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
  static const _activeRewardGoalKey = 'activeRewardGoal';
  static const _redeemedRewardGoalsKey = 'redeemedRewardGoals';

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
      activeRewardGoal: _decodeRewardGoal(preferences),
      redeemedRewardGoals: _decodeRewardGoalList(
        preferences.getStringList(_redeemedRewardGoalsKey),
      ),
    );
  }

  Future<RewardGoal?> loadActiveRewardGoal() async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeRewardGoal(preferences);
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
    final existingGoal = _decodeRewardGoal(preferences);
    if (existingGoal != null) {
      throw StateError('Only one active reward goal is supported.');
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
    await _saveActiveRewardGoal(preferences, goal);
    return goal;
  }

  Future<RewardGoal?> redeemActiveRewardGoal() async {
    final preferences = await SharedPreferences.getInstance();
    final activeGoal = _decodeRewardGoal(preferences);
    if (activeGoal == null || activeGoal.status != RewardGoalStatus.ready) {
      return null;
    }

    final redeemedGoal = activeGoal.copyWith(
      status: RewardGoalStatus.redeemed,
      redeemedAt: DateTime.now(),
    );
    final redeemedGoals = _decodeRewardGoalList(
      preferences.getStringList(_redeemedRewardGoalsKey),
    ).toList();
    redeemedGoals.insert(0, redeemedGoal);

    await preferences.setStringList(
      _redeemedRewardGoalsKey,
      redeemedGoals.map((goal) => jsonEncode(goal.toJson())).toList(),
    );
    await clearActiveRewardGoal();
    return redeemedGoal;
  }

  Future<void> clearActiveRewardGoal() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeRewardGoalKey);
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
    final activeRewardGoal = _decodeRewardGoal(preferences);

    final awardedRewards = _selectRewards(result);
    final entry = MealHistoryEntry(
      id: result.endedAt.microsecondsSinceEpoch.toString(),
      startedAt: result.startedAt,
      endedAt: result.endedAt,
      targetDuration: result.targetDuration,
      actualDuration: result.actualDuration,
      completedBeforeArrival: result.completedBeforeArrival,
      rewardIds: awardedRewards.map((reward) => reward.id).toList(),
    );

    history.insert(0, entry);
    _addRewardsToInventory(inventory, awardedRewards, result.endedAt);
    final goalUpdate = _fillRewardGoalSlotIfEligible(
      goal: activeRewardGoal,
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
    final updatedRewardGoal = goalUpdate.goal;
    if (updatedRewardGoal != null) {
      await _saveActiveRewardGoal(preferences, updatedRewardGoal);
    }

    return RecordedMealSession(
      entry: entry,
      awardedRewards: awardedRewards,
      updatedRewardGoal: goalUpdate.goal,
      rewardGoalJustReady: goalUpdate.justReady,
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

  _RewardGoalUpdate _fillRewardGoalSlotIfEligible({
    required RewardGoal? goal,
    required List<RewardDefinition> awardedRewards,
    required MealSessionResult result,
    required String mealSessionId,
  }) {
    if (goal == null ||
        goal.status != RewardGoalStatus.active ||
        !result.mealCompleted ||
        goal.filledCount >= goal.requiredStickerCount) {
      return const _RewardGoalUpdate();
    }

    final slotReward = _rewardGoalSlotReward(awardedRewards);
    if (slotReward == null) {
      return const _RewardGoalUpdate();
    }

    final filledSlots = [
      ...goal.filledSlots,
      RewardGoalSlot(
        rewardId: slotReward.id,
        filledAt: result.endedAt,
        mealSessionId: mealSessionId,
      ),
    ];
    final becameReady = filledSlots.length >= goal.requiredStickerCount;

    return _RewardGoalUpdate(
      goal: goal.copyWith(
        filledSlots: filledSlots,
        status: becameReady ? RewardGoalStatus.ready : RewardGoalStatus.active,
        readyAt: becameReady ? result.endedAt : goal.readyAt,
      ),
      justReady: becameReady,
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

  RewardGoal? _decodeRewardGoal(SharedPreferences preferences) {
    final rawGoal = preferences.getString(_activeRewardGoalKey);
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

  Future<void> _saveActiveRewardGoal(
    SharedPreferences preferences,
    RewardGoal goal,
  ) {
    return preferences.setString(
      _activeRewardGoalKey,
      jsonEncode(goal.toJson()),
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
  const _RewardGoalUpdate({this.goal, this.justReady = false});

  final RewardGoal? goal;
  final bool justReady;
}
