import 'meal_history_entry.dart';
import 'reward_goal.dart';
import 'reward_item.dart';

class MealProgressSnapshot {
  const MealProgressSnapshot({
    required this.history,
    required this.inventory,
    required this.activeRewardGoal,
    required this.redeemedRewardGoals,
  });

  final List<MealHistoryEntry> history;
  final List<RewardInventoryItem> inventory;
  final RewardGoal? activeRewardGoal;
  final List<RewardGoal> redeemedRewardGoals;
}

class RecordedMealSession {
  const RecordedMealSession({
    required this.entry,
    required this.awardedRewards,
    required this.updatedRewardGoal,
    required this.rewardGoalJustReady,
  });

  final MealHistoryEntry entry;
  final List<RewardDefinition> awardedRewards;
  final RewardGoal? updatedRewardGoal;
  final bool rewardGoalJustReady;
}
