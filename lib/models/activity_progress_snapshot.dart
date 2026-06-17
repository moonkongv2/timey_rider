import 'activity_history_entry.dart';
import 'reward_goal.dart';
import 'reward_item.dart';

class ActivityProgressSnapshot {
  const ActivityProgressSnapshot({
    required this.history,
    required this.inventory,
    required this.activeRewardGoals,
    required this.earnedRewardGoals,
    required this.usedRewardGoals,
  });

  final List<ActivityHistoryEntry> history;
  final List<RewardInventoryItem> inventory;
  final List<RewardGoal> activeRewardGoals;
  final List<RewardGoal> earnedRewardGoals;
  final List<RewardGoal> usedRewardGoals;

  RewardGoal? get activeRewardGoal =>
      activeRewardGoals.isEmpty ? null : activeRewardGoals.first;
  List<RewardGoal> get redeemedRewardGoals => usedRewardGoals;
}

class RecordedActivitySession {
  const RecordedActivitySession({
    required this.entry,
    required this.awardedRewards,
    required this.updatedRewardGoals,
    required this.earnedRewardGoals,
    required this.inventory,
  });

  final ActivityHistoryEntry entry;
  final List<RewardDefinition> awardedRewards;
  final List<RewardGoal> updatedRewardGoals;
  final List<RewardGoal> earnedRewardGoals;
  final List<RewardInventoryItem> inventory;

  RewardGoal? get updatedRewardGoal {
    final goals = [...earnedRewardGoals, ...updatedRewardGoals];
    return goals.isEmpty ? null : goals.first;
  }

  bool get rewardGoalJustReady => earnedRewardGoals.isNotEmpty;

  int get collectedStickerTypeCount {
    return inventory.where((item) => item.count > 0).length;
  }

  int get totalStickerTypeCount => RewardCatalog.all.length;
}
