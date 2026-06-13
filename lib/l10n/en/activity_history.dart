// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class EnActivityHistoryTexts implements ActivityHistoryTextSet {
  const EnActivityHistoryTexts();

  String get title => 'Activity Records';
  String get emptyTitle => 'No activity records yet.';
  String get emptyBody => 'Completed mission timers will appear here.';
  String get helpTitle => 'Activity history guide';
  List<String> get helpBulletItems => const [
    'Activity history shows the mission, target time, actual time, completion status, and earned stickers.',
    'Manually chosen markers appear when they were saved with the activity.',
    'Auto-selected markers appear on the road only and are not saved in history.',
    'Incomplete records may show no stickers.',
  ];
  String get targetTimeLabel => 'Target';
  String get actualTimeLabel => 'Actual';
  String get overrunTimeLabel => 'Over';
  String get rewardLabel => 'Stickers earned';
  String get noRewardLabel => 'No stickers';
  String get selectedMarkerLabel => 'Chosen markers';
  String get deleteRecordLabel => 'Delete activity record';
  String get deleteRecordDialogTitle => 'Delete this activity record?';
  String get deleteRecordDialogBody =>
      'Only the record will be removed. Earned stickers will stay.';
  String get deleteRecordConfirmLabel => 'Delete';
  String get deleteRecordSuccessMessage => 'Activity record deleted.';

  String completedStatus(ActivityCompletionStatus completionStatus) {
    return switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd => 'Done early',
      ActivityCompletionStatus.completedAtEnd => 'Done on time',
      ActivityCompletionStatus.completedAfterEnd => 'Done after time',
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
