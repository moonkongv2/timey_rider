// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class EnMealHistoryTexts implements MealHistoryTextSet {
  const EnMealHistoryTexts();

  String get title => 'Meal Records';
  String get emptyTitle => 'No meal records yet';
  String get emptyBody => 'Completed timer sessions will appear here.';
  String get helpTitle => 'Meal history guide';
  List<String> get helpBulletItems => const [
    'Meal history shows target time, actual time, completion status, and earned stickers.',
    'Manually chosen ingredients appear when they were saved with the meal.',
    'Auto-selected ingredients appear on the road only and are not saved in history.',
    'Incomplete meals may show no stickers.',
  ];
  String get targetTimeLabel => 'Target';
  String get actualTimeLabel => 'Actual';
  String get overrunTimeLabel => 'Over';
  String get rewardLabel => 'Stickers earned';
  String get noRewardLabel => 'No stickers';
  String get selectedIngredientLabel => 'Chosen ingredients';
  String get deleteRecordLabel => 'Delete meal record';
  String get deleteRecordDialogTitle => 'Delete this meal record?';
  String get deleteRecordDialogBody =>
      'Only the record will be removed. Earned stickers will stay.';
  String get deleteRecordConfirmLabel => 'Delete';
  String get deleteRecordSuccessMessage => 'Meal record deleted.';

  String completedStatus(ActivityCompletionStatus completionStatus) {
    return completionStatus == ActivityCompletionStatus.needsMoreTime ||
            completionStatus == ActivityCompletionStatus.canceled
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
