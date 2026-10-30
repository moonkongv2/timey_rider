// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class EnActivityHistoryTexts implements ActivityHistoryTextSet {
  const EnActivityHistoryTexts();

  String get title => 'Activity Records';
  String get emptyTitle => 'No activity records yet.';
  String get emptyBody => 'Completed mission timers will appear here.';
  String get helpTitle => 'Activity history guide';
  List<String> get helpBulletItems => [
    deleteRecordOnlyWarning,
    deleteLinkedRewardsBody,
    'Activity history shows the mission, target time, actual time, completion status, and earned stickers.',
    'Manually chosen picture markers appear when they were saved with the activity.',
    'Auto-selected markers appear on the road only and are not saved in history.',
    'Records without a sticker show No sticker this time.',
  ];
  String get targetTimeLabel => 'Target';
  String get actualTimeLabel => 'Actual';
  String get overrunTimeLabel => 'Over';
  String get rewardLabel => 'Stickers earned';
  String get noRewardLabel => 'No sticker this time';
  String get selectedMarkerLabel => 'Chosen markers';
  String get deleteRecordLabel => 'Delete activity record';
  String get deleteRecordDialogTitle => 'Delete this activity record?';
  String get deleteRecordDialogBody =>
      'Only the record will be removed. Earned stickers will stay.';
  String get deleteRecordConfirmLabel => 'Delete';
  String get deleteRecordSuccessMessage => 'Activity record deleted.';

  String get deleteLinkedRewardsLabel =>
      'Also remove stickers earned from this activity';
  String get deleteLinkedRewardsBody =>
      'Removes its stickers and linked slots on unused reward boards. Rewards that fall below their goal return to in progress. Used rewards stay unchanged.';
  String get deleteRecordOnlyLabel => 'Delete record only';
  String get deleteWithRewardsLabel => 'Delete with stickers';
  String get loadFailureMessage =>
      'Unable to load your progress. Please try again.';
  String get storageFailureMessage =>
      'Saving could not be completed. Try again to recover the saved state.';
  String get dataFailureMessage =>
      'There is a problem with the saved data. If it persists after retrying, please contact support.';
  String get deletedActivityMessage =>
      'This activity was deleted. Its stickers will not be awarded again.';
  String get goHomeLabel => 'Go home';
  String additionalGoals(int count) => '$count more';
  String get deleteRecordOnlyWarning =>
      'After deleting only the record, you cannot remove its linked stickers through this activity.';

  String completedStatus(ActivityCompletionStatus completionStatus) {
    return switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Completed',
      ActivityCompletionStatus.timeEnded => 'Time ended',
      ActivityCompletionStatus.needsMoreTime => 'Needs more time',
      ActivityCompletionStatus.canceled => 'Canceled',
    };
  }

  String dateLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} $hour:$minute';
  }

  String overrunTime(String duration) => 'Over +$duration';
}
