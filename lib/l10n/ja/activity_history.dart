// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class JaActivityHistoryTexts implements ActivityHistoryTextSet {
  const JaActivityHistoryTexts();

  String get title => '活動記録';
  String get emptyTitle => '活動記録はまだありません。';
  String get emptyBody => '完了したミッションタイマーがここに表示されます。';
  String get helpTitle => '活動記録ガイド';
  List<String> get helpBulletItems => const [
    'Activity history shows the mission, target time, actual time, completion status, and earned stickers.',
    'Manually chosen picture markers appear when they were saved with the activity.',
    'Auto-selected markers appear on the road only and are not saved in history.',
    'Records without a sticker show No sticker this time.',
  ];
  String get targetTimeLabel => '目標';
  String get actualTimeLabel => '実際';
  String get overrunTimeLabel => '超過';
  String get rewardLabel => 'もらったステッカー';
  String get noRewardLabel => '今回はステッカーなし';
  String get selectedMarkerLabel => '選んだマーカー';
  String get deleteRecordLabel => '活動記録を削除';
  String get deleteRecordDialogTitle => 'この活動記録を削除しますか？';
  String get deleteRecordDialogBody => '削除されるのは記録だけです。もらったステッカーは残ります。';
  String get deleteRecordConfirmLabel => '削除';
  String get deleteRecordSuccessMessage => '活動記録を削除しました。';

  String completedStatus(ActivityCompletionStatus completionStatus) {
    return switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '完了',
      ActivityCompletionStatus.timeEnded => '時間終了',
      ActivityCompletionStatus.needsMoreTime => 'もう少し時間が必要',
      ActivityCompletionStatus.canceled => 'キャンセル',
    };
  }

  String dateLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} $hour:$minute';
  }

  String overrunTime(String duration) => 'Over +$duration';
}
