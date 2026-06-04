// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/meal_completion_status.dart';

class EnMealHistoryTexts implements MealHistoryTextSet {
  const EnMealHistoryTexts();

  String get title => 'Meal Records';
  String get emptyTitle => 'No meal records yet';
  String get emptyBody => 'Completed timer sessions will appear here.';
  String get targetTimeLabel => 'Target';
  String get actualTimeLabel => 'Actual';
  String get overrunTimeLabel => 'Over';
  String get rewardLabel => 'Stickers earned';
  String get noRewardLabel => 'No stickers';

  String completedStatus(MealCompletionStatus completionStatus) {
    return completionStatus == MealCompletionStatus.notCompleted
        ? 'Incomplete'
        : 'Complete';
  }

  String dateLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} $hour:$minute';
  }

  String overrunTime(String duration) => 'Over +$duration';
}
