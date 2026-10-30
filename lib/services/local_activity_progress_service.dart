import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../catalogs/activity_catalog.dart';
import '../models/activity_history_entry.dart';
import '../models/activity_progress_snapshot.dart';
import '../models/activity_completion_status.dart';
import '../models/activity_session_result.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';

class LocalActivityProgressService {
  LocalActivityProgressService();

  static Future<void>? _recordOperation;
  static const _deletedIdsKey = 'deletedActivitySessionIds';
  // Journal metadata, never a preferences data key. Explicit provenance makes
  // legacy used-source cleanup replayable without deleting shadowed fallbacks.
  static const _legacyUsedCleanup = 'legacyUsedSourceToRemove';

  Future<T> _serialized<T>(Future<T> Function() operation) async {
    final previous = _recordOperation;
    final completed = Completer<void>();
    _recordOperation = completed.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      completed.complete();
      if (identical(_recordOperation, completed.future)) {
        _recordOperation = null;
      }
    }
  }

  Future<ActivityProgressSnapshot> loadSnapshot() => _serialized(_loadSnapshot);
  Future<RewardGoal?> loadActiveRewardGoal() =>
      _serialized(_loadActiveRewardGoal);
  Future<List<RewardGoal>> loadActiveRewardGoals() =>
      _serialized(_loadActiveRewardGoalsPublic);
  Future<RewardGoal> createRewardGoal({
    required int requiredStickerCount,
    required String rewardText,
  }) => _serialized(
    () => _createRewardGoal(
      requiredStickerCount: requiredStickerCount,
      rewardText: rewardText,
    ),
  );
  Future<RewardGoal?> updateActiveRewardGoal({
    String? goalId,
    required int requiredStickerCount,
    required String rewardText,
  }) => _serialized(
    () => _updateActiveRewardGoal(
      goalId: goalId,
      requiredStickerCount: requiredStickerCount,
      rewardText: rewardText,
    ),
  );
  Future<RewardGoal?> cancelActiveRewardGoal({String? goalId}) =>
      _serialized(() => _cancelActiveRewardGoal(goalId: goalId));
  Future<RewardGoal?> useEarnedRewardGoal({String? goalId}) =>
      _serialized(() => _useEarnedRewardGoal(goalId: goalId));
  Future<void> clearActiveRewardGoal() => _serialized(_clearActiveRewardGoal);
  Future<bool> deleteActivityHistoryEntry(
    String entryId, {
    bool deleteLinkedRewards = false,
  }) => _serialized(
    () => _deleteActivityHistoryEntry(
      entryId,
      deleteLinkedRewards: deleteLinkedRewards,
    ),
  );
  Future<bool> isActivitySessionDeleted(String sessionId) =>
      _serialized(() async {
        final preferences = await _preferences();
        return _deletedIds(preferences).contains(sessionId);
      });
  Future<bool> hasLinkedRewards(String entryId) => _serialized(() async {
    final preferences = await _preferences();
    final history = _rawList(preferences, _historyKey, _legacyHistoryKey);
    final index = _historyIndex(history, entryId);
    if (index < 0) return false;
    if (_rewardIds(_json(history[index])).isNotEmpty) return true;
    return _mutationGoals(preferences).values
        .expand((goals) => goals)
        .any(
          (raw) => (_json(raw)['filledSlots'] as List).any(
            (slot) =>
                (slot['activitySessionId'] ?? slot['mealSessionId']) == entryId,
          ),
        );
  });

  static const _recordTransactionKey = 'activityRecordTransaction';

  static const _historyKey = 'activityHistory';
  // Migration fallback: old local keys are read once, then new saves use the
  // activity* keys below.
  static const _legacyHistoryKey = 'mealHistory';
  static const _inventoryKey = 'activityRewardInventory';
  static const _legacyInventoryKey = 'rewardInventory';
  static const _legacyActiveRewardGoalKey = 'activeRewardGoal';
  static const _legacyRedeemedRewardGoalsKey = 'redeemedRewardGoals';
  static const _activeRewardGoalsKey = 'activityActiveRewardGoals';
  static const _legacyActiveRewardGoalsKey = 'activeRewardGoals';
  static const _earnedRewardGoalsKey = 'activityEarnedRewardGoals';
  static const _legacyEarnedRewardGoalsKey = 'earnedRewardGoals';
  static const _usedRewardGoalsKey = 'activityUsedRewardGoals';
  static const _legacyUsedRewardGoalsKey = 'usedRewardGoals';
  static const maxActiveRewardGoals = 2;

  Future<ActivityProgressSnapshot> _loadSnapshot() async {
    final preferences = await _preferences();

    return ActivityProgressSnapshot(
      history: _decodeList(
        preferences.getStringList(_historyKey) ??
            preferences.getStringList(_legacyHistoryKey),
        ActivityHistoryEntry.fromJson,
      ),
      inventory: _decodeList(
        preferences.getStringList(_inventoryKey) ??
            preferences.getStringList(_legacyInventoryKey),
        RewardInventoryItem.fromJson,
      ),
      activeRewardGoals: _loadActiveRewardGoals(preferences),
      earnedRewardGoals: _loadEarnedRewardGoals(preferences),
      usedRewardGoals: _loadUsedRewardGoals(preferences),
    );
  }

  Future<RewardGoal?> _loadActiveRewardGoal() async {
    final preferences = await _preferences();
    final goals = _loadActiveRewardGoals(preferences);
    return goals.isEmpty ? null : goals.first;
  }

  Future<List<RewardGoal>> _loadActiveRewardGoalsPublic() async {
    final preferences = await _preferences();
    return _loadActiveRewardGoals(preferences);
  }

  Future<RewardGoal> _createRewardGoal({
    required int requiredStickerCount,
    required String rewardText,
  }) async {
    final trimmedRewardText = rewardText.trim();
    if (trimmedRewardText.isEmpty) {
      throw ArgumentError.value(rewardText, 'rewardText');
    }

    final preferences = await _preferences();
    _deletedIds(preferences);
    final activeGoals = _loadMutationGoalModels(
      preferences,
      _activeRewardGoalsKey,
    ).toList();
    if (activeGoals.length >= maxActiveRewardGoals) {
      throw StateError('Up to two active reward goals are supported.');
    }

    final now = DateTime.now();
    final goal = RewardGoal(
      id: now.microsecondsSinceEpoch.toString(),
      rewardText: trimmedRewardText,
      requiredStickerCount: requiredStickerCount.clamp(1, 20).toInt(),
      filledSlots: const [],
      createdAt: now,
      status: RewardGoalStatus.active,
    );
    activeGoals.add(goal);
    await _commitGoals(preferences, active: activeGoals);
    return goal;
  }

  Future<RewardGoal?> _updateActiveRewardGoal({
    String? goalId,
    required int requiredStickerCount,
    required String rewardText,
  }) async {
    final trimmedRewardText = rewardText.trim();
    if (trimmedRewardText.isEmpty) {
      throw ArgumentError.value(rewardText, 'rewardText');
    }

    final preferences = await _preferences();
    _deletedIds(preferences);
    final activeGoals = _loadMutationGoalModels(
      preferences,
      _activeRewardGoalsKey,
    ).toList();
    if (activeGoals.isEmpty) {
      return null;
    }

    final targetIndex = goalId == null
        ? 0
        : activeGoals.indexWhere((goal) => goal.id == goalId);
    if (targetIndex == -1) {
      return null;
    }

    final activeGoal = activeGoals[targetIndex];
    final nextRequiredStickerCount = requiredStickerCount.clamp(1, 20).toInt();
    final isEarned = activeGoal.filledCount >= nextRequiredStickerCount;
    final updatedGoal = activeGoal.copyWith(
      rewardText: trimmedRewardText,
      requiredStickerCount: nextRequiredStickerCount,
      status: isEarned ? RewardGoalStatus.earned : RewardGoalStatus.active,
      earnedAt: isEarned ? activeGoal.earnedAt ?? DateTime.now() : null,
      readyAt: isEarned ? activeGoal.readyAt ?? DateTime.now() : null,
    );
    if (isEarned) {
      activeGoals.removeAt(targetIndex);
      final earnedGoals = _loadMutationGoalModels(
        preferences,
        _earnedRewardGoalsKey,
      ).toList()..insert(0, updatedGoal);
      await _commitGoals(preferences, active: activeGoals, earned: earnedGoals);
    } else {
      activeGoals[targetIndex] = updatedGoal;
      await _commitGoals(preferences, active: activeGoals);
    }
    return updatedGoal;
  }

  Future<RewardGoal?> _cancelActiveRewardGoal({String? goalId}) async {
    final preferences = await _preferences();
    _deletedIds(preferences);
    final activeGoals = _loadMutationGoalModels(
      preferences,
      _activeRewardGoalsKey,
    ).toList();
    if (activeGoals.isEmpty) {
      return null;
    }

    final targetIndex = goalId == null
        ? 0
        : activeGoals.indexWhere((goal) => goal.id == goalId);
    if (targetIndex == -1) {
      return null;
    }

    final canceledGoal = activeGoals.removeAt(targetIndex);
    await _commitGoals(preferences, active: activeGoals);
    return canceledGoal;
  }

  Future<RewardGoal?> redeemActiveRewardGoal() async {
    return useEarnedRewardGoal();
  }

  Future<RewardGoal?> _useEarnedRewardGoal({String? goalId}) async {
    final preferences = await _preferences();
    _deletedIds(preferences);
    final earnedGoals = _loadMutationGoalModels(
      preferences,
      _earnedRewardGoalsKey,
    ).toList();
    if (earnedGoals.isEmpty) {
      return null;
    }

    final targetIndex = goalId == null
        ? 0
        : earnedGoals.indexWhere((goal) => goal.id == goalId);
    if (targetIndex == -1) {
      return null;
    }

    final earnedGoal = earnedGoals.removeAt(targetIndex);
    final usedGoal = earnedGoal.copyWith(
      status: RewardGoalStatus.used,
      usedAt: DateTime.now(),
      redeemedAt: DateTime.now(),
    );
    final usedSource = preferences.containsKey(_usedRewardGoalsKey)
        ? null
        : preferences.containsKey(_legacyUsedRewardGoalsKey)
        ? _legacyUsedRewardGoalsKey
        : _legacyRedeemedRewardGoalsKey;
    final usedGoals = _rawUsedGoals(preferences);
    final sourceGoals = _mutationGoals(preferences);
    final usedRaw = _encodeGoal(
      usedGoal,
      sourceGoals.values.expand((items) => items).toList(),
    );
    await _commit(preferences, {
      ...sourceGoals,
      _earnedRewardGoalsKey: _encodeGoals(earnedGoals, sourceGoals),
      _usedRewardGoalsKey: [usedRaw, ...usedGoals],
      if (usedSource != null) _legacyUsedCleanup: [usedSource],
    });
    return usedGoal;
  }

  Future<void> _clearActiveRewardGoal() async {
    final preferences = await _preferences();
    _deletedIds(preferences);
    await _commitGoals(preferences, active: []);
  }

  Future<bool> _deleteActivityHistoryEntry(
    String entryId, {
    required bool deleteLinkedRewards,
  }) async {
    final preferences = await _preferences();
    final history = _rawList(preferences, _historyKey, _legacyHistoryKey);
    final index = _historyIndex(history, entryId);
    if (index < 0) return false;
    final deletedIds = _deletedIds(preferences)..add(entryId);
    final writes = <String, List<String>>{};
    if (deleteLinkedRewards) {
      final counts = <String, int>{};
      for (final id in _rewardIds(_json(history[index]))) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
      final inventory = _rawList(
        preferences,
        _inventoryKey,
        _legacyInventoryKey,
      );
      final seen = <String>{};
      final nextInventory = <String>[];
      for (final raw in inventory) {
        final item = _json(raw);
        final id = item['rewardId'];
        final count = item['count'];
        if (id is! String ||
            id.trim().isEmpty ||
            !seen.add(id) ||
            count is! int ||
            count < 1 ||
            item['acquiredAt'] is! String ||
            DateTime.tryParse(item['acquiredAt'] as String) == null) {
          throw const ActivityProgressDataException();
        }
        final removed = counts[id] ?? 0;
        if (removed == 0) {
          nextInventory.add(raw);
          continue;
        }
        if (count > removed) {
          item['count'] = count - removed;
          nextInventory.add(jsonEncode(item));
        }
      }
      writes[_inventoryKey] = nextInventory;
      final goals = _mutationGoals(preferences);
      final active = <String>[];
      final earned = <String>[];
      final returned = <String>[];
      for (final key in [_activeRewardGoalsKey, _earnedRewardGoalsKey]) {
        for (final raw in goals[key]!) {
          final goal = _json(raw);
          final slots = goal['filledSlots'] as List;
          final kept = slots
              .where(
                (slot) =>
                    (slot['activitySessionId'] ?? slot['mealSessionId']) !=
                    entryId,
              )
              .toList();
          var next = raw;
          var returnsToActive = false;
          if (kept.length != slots.length) {
            goal['filledSlots'] = kept;
            if (key == _earnedRewardGoalsKey &&
                kept.length < (goal['requiredStickerCount'] as int)) {
              goal['status'] = 'active';
              goal['earnedAt'] = null;
              goal['readyAt'] = null;
              returnsToActive = true;
            }
            next = jsonEncode(goal);
          }
          if (returnsToActive) {
            returned.add(next);
          } else if (key == _activeRewardGoalsKey) {
            active.add(next);
          } else {
            earned.add(next);
          }
        }
      }
      writes[_activeRewardGoalsKey] = [...active, ...returned];
      writes[_earnedRewardGoalsKey] = earned;
    }
    history.removeAt(index);
    writes[_historyKey] = history;
    writes[_deletedIdsKey] = deletedIds.toList();
    await _commit(preferences, writes);
    return true;
  }

  Future<RecordedActivitySession> recordActivityResult(
    ActivitySessionResult result, {
    required String vehicleId,
  }) async {
    return _serialized(
      () => _recordActivityResult(result, vehicleId: vehicleId),
    );
  }

  Future<RecordedActivitySession> _recordActivityResult(
    ActivitySessionResult result, {
    required String vehicleId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await _recoverRecordTransaction(preferences);
    final deletedEntryId =
        result.sessionId ?? result.endedAt.microsecondsSinceEpoch.toString();
    if (deletedEntryId.trim().isEmpty) {
      throw const ActivityProgressDataException();
    }
    if (_deletedIds(preferences).contains(deletedEntryId)) {
      throw DeletedActivitySessionException(deletedEntryId);
    }
    final history = _decodeList(
      preferences.getStringList(_historyKey) ??
          preferences.getStringList(_legacyHistoryKey),
      ActivityHistoryEntry.fromJson,
    ).toList();
    final inventory = _loadInventoryForMutation(preferences);
    final activeRewardGoals = _loadMutationGoalModels(
      preferences,
      _activeRewardGoalsKey,
    ).toList();
    final earnedRewardGoals = _loadMutationGoalModels(
      preferences,
      _earnedRewardGoalsKey,
    ).toList();

    final entryId =
        result.sessionId ?? result.endedAt.microsecondsSinceEpoch.toString();
    for (final existing in history) {
      if (existing.id == entryId) {
        return RecordedActivitySession(
          entry: existing,
          awardedRewards: existing.rewardIds
              .map(RewardCatalog.findById)
              .whereType<RewardDefinition>()
              .toList(),
          updatedRewardGoals: const [],
          earnedRewardGoals: const [],
          inventory: inventory,
        );
      }
    }
    final awardedRewards = _selectRewards(result, vehicleId: vehicleId);
    final entry = ActivityHistoryEntry(
      id: entryId,
      activityId: result.activityId,
      startedAt: result.startedAt,
      endedAt: result.endedAt,
      targetDuration: result.targetDuration,
      actualDuration: result.actualDuration,
      completedBeforeEnd: result.completedBeforeEnd,
      completionStatus: result.completionStatus,
      rewardIds: awardedRewards.map((reward) => reward.id).toList(),
      selectedMarkerIds: result.selectedMarkerIds,
    );

    history.insert(0, entry);
    _addRewardsToInventory(inventory, awardedRewards, result.endedAt);
    final goalUpdate = _fillRewardGoalSlotsIfEligible(
      goals: activeRewardGoals,
      awardedRewards: awardedRewards,
      result: result,
      activitySessionId: entry.id,
    );

    final writes = <String, List<String>>{
      _historyKey: [
        jsonEncode(entry.toJson()),
        ..._rawList(preferences, _historyKey, _legacyHistoryKey),
      ],
      _inventoryKey: _encodeInventory(preferences, inventory),
    };
    if (goalUpdate.changed) {
      earnedRewardGoals.insertAll(0, goalUpdate.earnedGoals);
      writes[_activeRewardGoalsKey] = _encodeGoals(
        goalUpdate.activeGoals,
        _mutationGoals(preferences),
      );
      writes[_earnedRewardGoalsKey] = _encodeGoals(
        earnedRewardGoals,
        _mutationGoals(preferences),
      );
    }
    await _commit(preferences, writes);

    return RecordedActivitySession(
      entry: entry,
      awardedRewards: awardedRewards,
      updatedRewardGoals: goalUpdate.updatedGoals,
      earnedRewardGoals: goalUpdate.earnedGoals,
      inventory: inventory,
    );
  }

  Future<SharedPreferences> _preferences() async {
    final preferences = await SharedPreferences.getInstance();
    await _recoverRecordTransaction(preferences);
    return preferences;
  }

  Future<void> _commit(
    SharedPreferences preferences,
    Map<String, List<String>> writes,
  ) async {
    _validateWrites(writes);
    try {
      if (!await preferences.setString(
        _recordTransactionKey,
        jsonEncode(writes),
      )) {
        throw const ActivityProgressStorageException();
      }
      await _recoverRecordTransaction(preferences);
    } on ActivityProgressDataException {
      rethrow;
    } catch (_) {
      await preferences.reload();
      throw const ActivityProgressStorageException();
    }
  }

  Map<String, List<String>> _validateWrites(Object? value) {
    const supported = {
      _historyKey,
      _inventoryKey,
      _activeRewardGoalsKey,
      _earnedRewardGoalsKey,
      _usedRewardGoalsKey,
      _deletedIdsKey,
      _legacyUsedCleanup,
    };
    if (value is! Map || value.isEmpty) {
      throw const ActivityProgressDataException();
    }
    final writes = <String, List<String>>{};
    for (final entry in value.entries) {
      if (!supported.contains(entry.key) ||
          entry.value is! List ||
          (entry.value as List).any((item) => item is! String)) {
        throw const ActivityProgressDataException();
      }
      final items = List<String>.from(entry.value as List);
      if (entry.key == _deletedIdsKey && items.any((id) => id.trim().isEmpty)) {
        throw const ActivityProgressDataException();
      }
      writes[entry.key as String] = items;
    }
    final cleanup = writes[_legacyUsedCleanup];
    if (cleanup != null &&
        (cleanup.length != 1 ||
            !{
              _legacyUsedRewardGoalsKey,
              _legacyRedeemedRewardGoalsKey,
            }.contains(cleanup.single) ||
            !writes.containsKey(_usedRewardGoalsKey))) {
      throw const ActivityProgressDataException();
    }
    return writes;
  }

  Future<void> _remove(SharedPreferences preferences, String key) async {
    if (preferences.containsKey(key) && !await preferences.remove(key)) {
      throw const ActivityProgressStorageException();
    }
  }

  Future<void> _recoverRecordTransaction(SharedPreferences preferences) async {
    if (!preferences.containsKey(_recordTransactionKey)) return;
    late Map<String, List<String>> writes;
    try {
      writes = _validateWrites(
        jsonDecode(preferences.getString(_recordTransactionKey)!),
      );
    } catch (_) {
      throw const ActivityProgressDataException();
    }
    try {
      // Tombstones must be durable before a history entry disappears.
      for (final key in [
        _deletedIdsKey,
        ...writes.keys.where(
          (key) => key != _deletedIdsKey && key != _legacyUsedCleanup,
        ),
      ]) {
        if (writes.containsKey(key) &&
            !await preferences.setStringList(key, writes[key]!)) {
          throw const ActivityProgressStorageException();
        }
      }
      for (final pair in {
        _historyKey: _legacyHistoryKey,
        _inventoryKey: _legacyInventoryKey,
        _activeRewardGoalsKey: _legacyActiveRewardGoalsKey,
        _earnedRewardGoalsKey: _legacyEarnedRewardGoalsKey,
      }.entries) {
        if (writes.containsKey(pair.key)) {
          await _remove(preferences, pair.value);
        }
      }
      if (writes.containsKey(_activeRewardGoalsKey) &&
          writes.containsKey(_earnedRewardGoalsKey)) {
        await _remove(preferences, _legacyActiveRewardGoalKey);
      }
      for (final key in writes[_legacyUsedCleanup] ?? <String>[]) {
        await _remove(preferences, key);
      }
      await _remove(preferences, _recordTransactionKey);
    } catch (_) {
      await preferences.reload();
      throw const ActivityProgressStorageException();
    }
  }

  List<RewardDefinition> _selectRewards(
    ActivitySessionResult result, {
    required String vehicleId,
  }) {
    if (!result.activityCompleted) {
      return const [];
    }

    final activity = ActivityCatalog.findById(result.activityId);
    final shouldReceiveSticker =
        result.receiveSticker ??
        (activity.rewardEnabledByDefault &&
            activityCompletionStatusCanReceiveSticker(result.completionStatus));
    if (!shouldReceiveSticker) {
      return const [];
    }

    final reward = RewardCatalog.findVehicleStickerByVehicleId(vehicleId);
    return reward == null ? const [] : [reward];
  }

  void _addRewardsToInventory(
    List<RewardInventoryItem> inventory,
    List<RewardDefinition> rewards,
    DateTime acquiredAt,
  ) {
    for (final reward in rewards) {
      final index = inventory.indexWhere((item) => item.rewardId == reward.id);
      if (index == -1) {
        inventory.add(
          RewardInventoryItem(
            rewardId: reward.id,
            acquiredAt: acquiredAt,
            count: 1,
          ),
        );
        continue;
      }

      final item = inventory[index];
      inventory[index] = item.copyWith(count: item.count + 1);
    }
  }

  _RewardGoalUpdate _fillRewardGoalSlotsIfEligible({
    required List<RewardGoal> goals,
    required List<RewardDefinition> awardedRewards,
    required ActivitySessionResult result,
    required String activitySessionId,
  }) {
    final shouldReceiveSticker =
        result.receiveSticker ??
        activityCompletionStatusCanReceiveSticker(result.completionStatus);
    if (goals.isEmpty || !shouldReceiveSticker) {
      return _RewardGoalUpdate(activeGoals: goals);
    }

    final slotReward = _rewardGoalSlotReward(awardedRewards);
    if (slotReward == null) {
      return _RewardGoalUpdate(activeGoals: goals);
    }

    final activeGoals = <RewardGoal>[];
    final updatedGoals = <RewardGoal>[];
    final earnedGoals = <RewardGoal>[];

    for (final goal in goals) {
      if (goal.status != RewardGoalStatus.active ||
          goal.filledCount >= goal.requiredStickerCount) {
        activeGoals.add(goal);
        continue;
      }

      final filledSlots = [
        ...goal.filledSlots,
        RewardGoalSlot(
          rewardId: slotReward.id,
          filledAt: result.endedAt,
          activitySessionId: activitySessionId,
        ),
      ];
      final becameEarned = filledSlots.length >= goal.requiredStickerCount;
      final updatedGoal = goal.copyWith(
        filledSlots: filledSlots,
        status: becameEarned
            ? RewardGoalStatus.earned
            : RewardGoalStatus.active,
        earnedAt: becameEarned ? result.endedAt : goal.earnedAt,
        readyAt: becameEarned ? result.endedAt : goal.readyAt,
      );

      if (becameEarned) {
        earnedGoals.add(updatedGoal);
      } else {
        activeGoals.add(updatedGoal);
        updatedGoals.add(updatedGoal);
      }
    }

    return _RewardGoalUpdate(
      activeGoals: activeGoals,
      updatedGoals: updatedGoals,
      earnedGoals: earnedGoals,
      changed: updatedGoals.isNotEmpty || earnedGoals.isNotEmpty,
    );
  }

  RewardDefinition? _rewardGoalSlotReward(List<RewardDefinition> rewards) {
    for (final reward in rewards) {
      if (reward.type == RewardType.sticker) {
        return reward;
      }
    }
    return null;
  }

  List<RewardGoal> _loadActiveRewardGoals(SharedPreferences preferences) {
    final rawGoals =
        preferences.getStringList(_activeRewardGoalsKey) ??
        preferences.getStringList(_legacyActiveRewardGoalsKey);
    if (rawGoals != null) {
      return _decodeRewardGoalList(
        rawGoals,
      ).where((goal) => goal.status == RewardGoalStatus.active).toList();
    }

    final legacyGoal = _decodeRewardGoal(
      preferences,
      _legacyActiveRewardGoalKey,
    );
    if (legacyGoal == null || legacyGoal.status != RewardGoalStatus.active) {
      return <RewardGoal>[];
    }
    return [legacyGoal];
  }

  List<RewardGoal> _loadEarnedRewardGoals(SharedPreferences preferences) {
    final rawGoals =
        preferences.getStringList(_earnedRewardGoalsKey) ??
        preferences.getStringList(_legacyEarnedRewardGoalsKey);
    if (rawGoals != null) {
      return _decodeRewardGoalList(
        rawGoals,
      ).where((goal) => goal.status == RewardGoalStatus.earned).toList();
    }

    final legacyGoal = _decodeRewardGoal(
      preferences,
      _legacyActiveRewardGoalKey,
    );
    if (legacyGoal == null || !legacyGoal.isReady) {
      return <RewardGoal>[];
    }
    return [
      legacyGoal.copyWith(
        status: RewardGoalStatus.earned,
        earnedAt: legacyGoal.earnedAt ?? legacyGoal.readyAt,
      ),
    ];
  }

  List<RewardGoal> _loadUsedRewardGoals(SharedPreferences preferences) {
    final rawGoals =
        preferences.getStringList(_usedRewardGoalsKey) ??
        preferences.getStringList(_legacyUsedRewardGoalsKey);
    if (rawGoals != null) {
      return _decodeRewardGoalList(
        rawGoals,
      ).where((goal) => goal.isUsed).toList();
    }

    return _decodeRewardGoalList(
          preferences.getStringList(_legacyRedeemedRewardGoalsKey),
        )
        .map(
          (goal) => goal.copyWith(
            status: RewardGoalStatus.used,
            usedAt: goal.usedAt ?? goal.redeemedAt,
          ),
        )
        .toList();
  }

  RewardGoal? _decodeRewardGoal(SharedPreferences preferences, String key) {
    final rawGoal = preferences.getString(key);
    if (rawGoal == null || rawGoal.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawGoal);
      if (decoded is Map) {
        try {
          return _strictGoal(rawGoal);
        } catch (_) {
          return RewardGoal.tryFromJson(Map<String, Object?>.from(decoded));
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<RewardGoal> _decodeRewardGoalList(List<String>? rawItems) {
    if (rawItems == null) {
      return <RewardGoal>[];
    }

    final goals = <RewardGoal>[];
    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is Map) {
          final goal = RewardGoal.tryFromJson(
            Map<String, Object?>.from(decoded),
          );
          if (goal != null) {
            try {
              goals.add(_strictGoal(rawItem));
            } catch (_) {
              goals.add(goal);
            }
          }
        }
      } catch (_) {
        continue;
      }
    }
    return goals;
  }

  Map<String, Object?> _json(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) throw const ActivityProgressDataException();
      return Map<String, Object?>.from(value);
    } catch (_) {
      throw const ActivityProgressDataException();
    }
  }

  List<String> _rawList(
    SharedPreferences preferences,
    String key,
    String legacy,
  ) {
    try {
      return List.of(
        preferences.getStringList(key) ??
            preferences.getStringList(legacy) ??
            <String>[],
      );
    } catch (_) {
      throw const ActivityProgressDataException();
    }
  }

  Set<String> _deletedIds(SharedPreferences preferences) {
    try {
      if (!preferences.containsKey(_deletedIdsKey)) return <String>{};
      final ids = preferences.getStringList(_deletedIdsKey)!;
      if (ids.any((id) => id.trim().isEmpty)) {
        throw const ActivityProgressDataException();
      }
      return ids.toSet();
    } catch (_) {
      throw const ActivityProgressDataException();
    }
  }

  int _historyIndex(List<String> history, String entryId) {
    var index = -1;
    for (var i = 0; i < history.length; i++) {
      // An unreadable ID cannot safely be assumed to belong to another session.
      final id = _json(history[i])['id'];
      if (id is! String || id.trim().isEmpty) {
        throw const ActivityProgressDataException();
      }
      if (id == entryId) {
        if (index != -1) throw const ActivityProgressDataException();
        index = i;
      }
    }
    return index;
  }

  List<String> _rewardIds(Map<String, Object?> history) {
    final ids = history['rewardIds'];
    if (ids is! List || ids.any((id) => id is! String || id.trim().isEmpty)) {
      throw const ActivityProgressDataException();
    }
    return List<String>.from(ids);
  }

  RewardGoal _strictGoal(String raw, {Set<RewardGoalStatus>? allowed}) {
    try {
      return _decodeStrictGoal(raw, allowed: allowed);
    } catch (_) {
      throw const ActivityProgressDataException();
    }
  }

  RewardGoal _decodeStrictGoal(String raw, {Set<RewardGoalStatus>? allowed}) {
    final json = _json(raw);
    final status = json['status'];
    final slots = json['filledSlots'];
    final count = json['requiredStickerCount'];
    final model = RewardGoal.tryFromJson(json);
    if (model == null ||
        model.id.trim().isEmpty ||
        status is! String ||
        !RewardGoalStatus.values.any((value) => value.name == status) ||
        count is! int ||
        count < 1 ||
        count > 20 ||
        slots is! List ||
        (allowed != null && !allowed.contains(model.status))) {
      throw const ActivityProgressDataException();
    }
    for (final key in ['earnedAt', 'readyAt', 'usedAt', 'redeemedAt']) {
      final value = json[key];
      if (value != null &&
          (value is! String || DateTime.tryParse(value) == null)) {
        throw const ActivityProgressDataException();
      }
    }
    final decodedSlots = <RewardGoalSlot>[];
    for (final slot in slots) {
      if (slot is! Map) throw const ActivityProgressDataException();
      final decoded = RewardGoalSlot.tryFromJson(
        Map<String, Object?>.from(slot),
      );
      if (decoded == null ||
          decoded.rewardId.trim().isEmpty ||
          decoded.activitySessionId.trim().isEmpty) {
        throw const ActivityProgressDataException();
      }
      decodedSlots.add(decoded);
    }
    return model.copyWith(filledSlots: decodedSlots);
  }

  Map<String, List<String>> _mutationGoals(SharedPreferences preferences) {
    final result = <String, List<String>>{};
    String? single;
    if (preferences.containsKey(_legacyActiveRewardGoalKey)) {
      try {
        single = preferences.getString(_legacyActiveRewardGoalKey);
      } catch (_) {
        throw const ActivityProgressDataException();
      }
      if (single == null) throw const ActivityProgressDataException();
      _strictGoal(
        single,
        allowed: {RewardGoalStatus.active, RewardGoalStatus.earned},
      );
    }
    for (final pair in {
      _activeRewardGoalsKey: _legacyActiveRewardGoalsKey,
      _earnedRewardGoalsKey: _legacyEarnedRewardGoalsKey,
    }.entries) {
      if (preferences.containsKey(pair.key) ||
          preferences.containsKey(pair.value)) {
        result[pair.key] = _rawList(preferences, pair.key, pair.value);
      } else {
        try {
          single ??= preferences.getString(_legacyActiveRewardGoalKey);
        } catch (_) {
          throw const ActivityProgressDataException();
        }
        if (single == null) {
          result[pair.key] = [];
          continue;
        }
        final model = _strictGoal(
          single,
          allowed: {RewardGoalStatus.active, RewardGoalStatus.earned},
        );
        result[pair.key] =
            (model.status == RewardGoalStatus.active) ==
                (pair.key == _activeRewardGoalsKey)
            ? [single]
            : [];
      }
    }
    final seen = <String>{};
    for (final entry in result.entries) {
      for (final raw in entry.value) {
        final goal = _strictGoal(
          raw,
          allowed: {
            entry.key == _activeRewardGoalsKey
                ? RewardGoalStatus.active
                : RewardGoalStatus.earned,
          },
        );
        if (!seen.add(goal.id)) throw const ActivityProgressDataException();
      }
    }
    return result;
  }

  List<RewardGoal> _loadMutationGoalModels(
    SharedPreferences preferences,
    String key,
  ) =>
      _mutationGoals(preferences)[key]!.map((raw) => _strictGoal(raw)).toList();

  List<String> _rawUsedGoals(SharedPreferences preferences) {
    final selected = preferences.containsKey(_usedRewardGoalsKey)
        ? _usedRewardGoalsKey
        : preferences.containsKey(_legacyUsedRewardGoalsKey)
        ? _legacyUsedRewardGoalsKey
        : _legacyRedeemedRewardGoalsKey;
    final raw = _rawList(preferences, selected, selected);
    final seen = <String>{};
    return raw.map((item) {
      final goal = _strictGoal(
        item,
        allowed: selected == _legacyRedeemedRewardGoalsKey
            ? null
            : {RewardGoalStatus.used},
      );
      if (!seen.add(goal.id)) throw const ActivityProgressDataException();
      if (selected != _legacyRedeemedRewardGoalsKey) return item;
      final json = _json(item);
      json['status'] = 'used';
      json['usedAt'] = json['usedAt'] ?? json['redeemedAt'];
      return jsonEncode(json);
    }).toList();
  }

  String _encodeGoal(RewardGoal goal, List<String> originals) {
    for (final raw in originals) {
      final json = _json(raw);
      if (json['id'] != goal.id) continue;
      final before = _strictGoal(raw);
      if (jsonEncode(before.toJson()) == jsonEncode(goal.toJson())) return raw;
      final beforeJson = before.toJson();
      final afterJson = goal.toJson();
      for (final key in afterJson.keys) {
        if (jsonEncode(beforeJson[key]) != jsonEncode(afterJson[key])) {
          json[key] = afterJson[key];
        }
      }
      // Append-only completion and edits retain each original slot, including
      // distinct extension fields on slots with identical session/reward IDs.
      if (jsonEncode(beforeJson['filledSlots']) !=
          jsonEncode(afterJson['filledSlots'])) {
        final oldSlots = _json(raw)['filledSlots'] as List;
        final consumed = <int>{};
        json['filledSlots'] = goal.filledSlots.map((slot) {
          for (var i = 0; i < oldSlots.length; i++) {
            if (consumed.contains(i)) continue;
            final old = oldSlots[i];
            if ((old['activitySessionId'] ?? old['mealSessionId']) ==
                    slot.activitySessionId &&
                old['rewardId'] == slot.rewardId &&
                DateTime.tryParse(old['filledAt'] as String) == slot.filledAt) {
              consumed.add(i);
              return old;
            }
          }
          return slot.toJson();
        }).toList();
      }
      return jsonEncode(json);
    }
    return jsonEncode(goal.toJson());
  }

  List<String> _encodeGoals(
    List<RewardGoal> goals,
    Map<String, List<String>> source,
  ) => goals
      .map(
        (goal) =>
            _encodeGoal(goal, source.values.expand((items) => items).toList()),
      )
      .toList();

  Future<void> _commitGoals(
    SharedPreferences preferences, {
    List<RewardGoal>? active,
    List<RewardGoal>? earned,
  }) async {
    final source = _mutationGoals(preferences);
    await _commit(preferences, {
      ...source,
      if (active != null) _activeRewardGoalsKey: _encodeGoals(active, source),
      if (earned != null) _earnedRewardGoalsKey: _encodeGoals(earned, source),
    });
  }

  List<RewardInventoryItem> _loadInventoryForMutation(
    SharedPreferences preferences,
  ) {
    final seen = <String>{};
    return _rawList(preferences, _inventoryKey, _legacyInventoryKey).map((raw) {
      try {
        final item = RewardInventoryItem.fromJson(_json(raw));
        if (item.rewardId.trim().isEmpty ||
            item.count < 1 ||
            !seen.add(item.rewardId)) {
          throw const ActivityProgressDataException();
        }
        return item;
      } catch (_) {
        throw const ActivityProgressDataException();
      }
    }).toList();
  }

  List<String> _encodeInventory(
    SharedPreferences preferences,
    List<RewardInventoryItem> items,
  ) {
    final originals = _rawList(preferences, _inventoryKey, _legacyInventoryKey);
    return items.map((item) {
      for (final raw in originals) {
        final json = _json(raw);
        if (json['rewardId'] != item.rewardId) continue;
        if (json['count'] == item.count) return raw;
        json['count'] = item.count;
        return jsonEncode(json);
      }
      return jsonEncode(item.toJson());
    }).toList();
  }

  List<T> _decodeList<T>(
    List<String>? rawItems,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    if (rawItems == null) {
      return <T>[];
    }

    final items = <T>[];
    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is Map) {
          items.add(fromJson(Map<String, Object?>.from(decoded)));
        }
      } catch (_) {
        continue;
      }
    }
    return items;
  }
}

class _RewardGoalUpdate {
  const _RewardGoalUpdate({
    required this.activeGoals,
    this.updatedGoals = const [],
    this.earnedGoals = const [],
    this.changed = false,
  });

  final List<RewardGoal> activeGoals;
  final List<RewardGoal> updatedGoals;
  final List<RewardGoal> earnedGoals;
  final bool changed;
}

class ActivityProgressDataException implements Exception {
  const ActivityProgressDataException();
}

class ActivityProgressStorageException implements Exception {
  const ActivityProgressStorageException();
}

class DeletedActivitySessionException implements Exception {
  const DeletedActivitySessionException(this.sessionId);
  final String sessionId;
}
