import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_history_entry.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/meal_session_result.dart';
import '../models/reward_goal.dart';
import '../models/reward_item.dart';

class LocalMealProgressService {
  LocalMealProgressService({Random? random}) : _random = random ?? Random();

  static const _historyKey = 'mealHistory';
  static const _inventoryKey = 'rewardInventory';
  static const _legacyActiveRewardGoalKey = 'activeRewardGoal';
  static const _legacyRedeemedRewardGoalsKey = 'redeemedRewardGoals';
  static const _activeRewardGoalsKey = 'activeRewardGoals';
  static const _earnedRewardGoalsKey = 'earnedRewardGoals';
  static const _usedRewardGoalsKey = 'usedRewardGoals';
  static const maxActiveRewardGoals = 2;

  final Random _random;

  Future<MealProgressSnapshot> loadSnapshot() async {
    final preferences = await SharedPreferences.getInstance();

    return MealProgressSnapshot(
      history: _decodeList(
        preferences.getStringList(_historyKey),
        MealHistoryEntry.fromJson,
      ),
      inventory: _decodeList(
        preferences.getStringList(_inventoryKey),
        RewardInventoryItem.fromJson,
      ),
      activeRewardGoals: _loadActiveRewardGoals(preferences),
      earnedRewardGoals: _loadEarnedRewardGoals(preferences),
      usedRewardGoals: _loadUsedRewardGoals(preferences),
    );
  }

  Future<RewardGoal?> loadActiveRewardGoal() async {
    final preferences = await SharedPreferences.getInstance();
    final goals = _loadActiveRewardGoals(preferences);
    return goals.isEmpty ? null : goals.first;
  }

  Future<List<RewardGoal>> loadActiveRewardGoals() async {
    final preferences = await SharedPreferences.getInstance();
    return _loadActiveRewardGoals(preferences);
  }

  Future<RewardGoal> createRewardGoal({
    required int requiredStickerCount,
    required String rewardText,
  }) async {
    final trimmedRewardText = rewardText.trim();
    if (trimmedRewardText.isEmpty) {
      throw ArgumentError.value(rewardText, 'rewardText');
    }

    final preferences = await SharedPreferences.getInstance();
    final activeGoals = _loadActiveRewardGoals(preferences).toList();
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
    await _saveRewardGoalList(preferences, _activeRewardGoalsKey, activeGoals);
    await preferences.remove(_legacyActiveRewardGoalKey);
    return goal;
  }

  Future<RewardGoal?> updateActiveRewardGoal({
    String? goalId,
    required int requiredStickerCount,
    required String rewardText,
  }) async {
    final trimmedRewardText = rewardText.trim();
    if (trimmedRewardText.isEmpty) {
      throw ArgumentError.value(rewardText, 'rewardText');
    }

    final preferences = await SharedPreferences.getInstance();
    final activeGoals = _loadActiveRewardGoals(preferences).toList();
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
      final earnedGoals = _loadEarnedRewardGoals(preferences).toList()
        ..insert(0, updatedGoal);
      await _saveRewardGoalList(
        preferences,
        _activeRewardGoalsKey,
        activeGoals,
      );
      await _saveRewardGoalList(
        preferences,
        _earnedRewardGoalsKey,
        earnedGoals,
      );
    } else {
      activeGoals[targetIndex] = updatedGoal;
      await _saveRewardGoalList(
        preferences,
        _activeRewardGoalsKey,
        activeGoals,
      );
    }
    await preferences.remove(_legacyActiveRewardGoalKey);
    return updatedGoal;
  }

  Future<RewardGoal?> cancelActiveRewardGoal({String? goalId}) async {
    final preferences = await SharedPreferences.getInstance();
    final activeGoals = _loadActiveRewardGoals(preferences).toList();
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
    await _saveRewardGoalList(preferences, _activeRewardGoalsKey, activeGoals);
    await preferences.remove(_legacyActiveRewardGoalKey);
    return canceledGoal;
  }

  Future<RewardGoal?> redeemActiveRewardGoal() async {
    return useEarnedRewardGoal();
  }

  Future<RewardGoal?> useEarnedRewardGoal({String? goalId}) async {
    final preferences = await SharedPreferences.getInstance();
    final earnedGoals = _loadEarnedRewardGoals(preferences).toList();
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
    final usedGoals = _loadUsedRewardGoals(preferences).toList()
      ..insert(0, usedGoal);

    await _saveRewardGoalList(preferences, _earnedRewardGoalsKey, earnedGoals);
    await _saveRewardGoalList(preferences, _usedRewardGoalsKey, usedGoals);
    return usedGoal;
  }

  Future<void> clearActiveRewardGoal() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_legacyActiveRewardGoalKey);
    await preferences.remove(_activeRewardGoalsKey);
  }

  Future<RecordedMealSession> recordMealResult(MealSessionResult result) async {
    final preferences = await SharedPreferences.getInstance();
    final history = _decodeList(
      preferences.getStringList(_historyKey),
      MealHistoryEntry.fromJson,
    ).toList();
    final inventory = _decodeList(
      preferences.getStringList(_inventoryKey),
      RewardInventoryItem.fromJson,
    ).toList();
    final activeRewardGoals = _loadActiveRewardGoals(preferences).toList();
    final earnedRewardGoals = _loadEarnedRewardGoals(preferences).toList();

    final awardedRewards = _selectRewards(result);
    final entry = MealHistoryEntry(
      id: result.endedAt.microsecondsSinceEpoch.toString(),
      startedAt: result.startedAt,
      endedAt: result.endedAt,
      targetDuration: result.targetDuration,
      actualDuration: result.actualDuration,
      completedBeforeArrival: result.completedBeforeArrival,
      mealCompleted: result.mealCompleted,
      completionStatus: result.completionStatus,
      rewardIds: awardedRewards.map((reward) => reward.id).toList(),
    );

    history.insert(0, entry);
    _addRewardsToInventory(inventory, awardedRewards, result.endedAt);
    final goalUpdate = _fillRewardGoalSlotsIfEligible(
      goals: activeRewardGoals,
      awardedRewards: awardedRewards,
      result: result,
      mealSessionId: entry.id,
    );

    await preferences.setStringList(
      _historyKey,
      history.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    await preferences.setStringList(
      _inventoryKey,
      inventory.map((item) => jsonEncode(item.toJson())).toList(),
    );
    if (goalUpdate.changed) {
      earnedRewardGoals.insertAll(0, goalUpdate.earnedGoals);
      await _saveRewardGoalList(
        preferences,
        _activeRewardGoalsKey,
        goalUpdate.activeGoals,
      );
      await _saveRewardGoalList(
        preferences,
        _earnedRewardGoalsKey,
        earnedRewardGoals,
      );
      await preferences.remove(_legacyActiveRewardGoalKey);
    }

    return RecordedMealSession(
      entry: entry,
      awardedRewards: awardedRewards,
      updatedRewardGoals: goalUpdate.updatedGoals,
      earnedRewardGoals: goalUpdate.earnedGoals,
    );
  }

  List<RewardDefinition> _selectRewards(MealSessionResult result) {
    if (!result.mealCompleted) {
      return const [];
    }

    return [_randomSuccessSticker()];
  }

  RewardDefinition _randomSuccessSticker() {
    final stickerIndex = _random.nextInt(RewardCatalog.successStickers.length);
    return RewardCatalog.successStickers[stickerIndex];
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
    required MealSessionResult result,
    required String mealSessionId,
  }) {
    if (goals.isEmpty || !result.mealCompleted) {
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
          mealSessionId: mealSessionId,
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
    final rawGoals = preferences.getStringList(_activeRewardGoalsKey);
    if (rawGoals != null) {
      return _decodeRewardGoalList(rawGoals)
          .where((goal) => goal.status == RewardGoalStatus.active)
          .take(maxActiveRewardGoals)
          .toList();
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
    final rawGoals = preferences.getStringList(_earnedRewardGoalsKey);
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
    final rawGoals = preferences.getStringList(_usedRewardGoalsKey);
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
        return RewardGoal.tryFromJson(Map<String, Object?>.from(decoded));
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
            goals.add(goal);
          }
        }
      } catch (_) {
        continue;
      }
    }
    return goals;
  }

  Future<void> _saveRewardGoalList(
    SharedPreferences preferences,
    String key,
    List<RewardGoal> goals,
  ) {
    return preferences.setStringList(
      key,
      goals.map((goal) => jsonEncode(goal.toJson())).toList(),
    );
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
      final decoded = jsonDecode(rawItem);
      if (decoded is Map) {
        items.add(fromJson(Map<String, Object?>.from(decoded)));
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
