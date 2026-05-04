import 'meal_history_entry.dart';
import 'reward_item.dart';

class MealProgressSnapshot {
  const MealProgressSnapshot({required this.history, required this.inventory});

  final List<MealHistoryEntry> history;
  final List<RewardInventoryItem> inventory;
}

class RecordedMealSession {
  const RecordedMealSession({
    required this.entry,
    required this.awardedRewards,
  });

  final MealHistoryEntry entry;
  final List<RewardDefinition> awardedRewards;
}
