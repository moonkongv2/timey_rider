// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class JaActivityHistoryTexts implements ActivityHistoryTextSet {
  const JaActivityHistoryTexts();

  String get title => '活動記録';
  String get emptyTitle => '活動記録はまだありません。';
  String get emptyBody => '完了したミッションタイマーがここに表示されます。';
  String get helpTitle => '活動記録ガイド';
  List<String> get helpBulletItems => [
    deleteRecordOnlyWarning,
    deleteLinkedRewardsBody,
    '活動記録には、ミッション、目標時間、実際の時間、完了状況、もらったステッカーが表示されます。',
    '手動で選んだ絵マーカーは、活動と一緒に保存された場合に表示されます。',
    '自動で選ばれたマーカーはコース上だけに表示され、活動記録には保存されません。',
    'ステッカーがない記録には「今回はステッカーなし」と表示されます。',
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

  String get deleteLinkedRewardsLabel => 'この活動でもらったステッカーも削除する';
  String get deleteLinkedRewardsBody =>
      'この活動のステッカーと未使用のごほうびボードの該当マスを削除します。目標を下回ったごほうびは進行中に戻ります。使用済みのごほうびは変わりません。';
  String get deleteRecordOnlyLabel => '記録のみ削除';
  String get deleteWithRewardsLabel => 'ステッカーも削除';
  String get loadFailureMessage => '進行状況を読み込めませんでした。もう一度お試しください。';
  String get storageFailureMessage => '保存を完了できませんでした。もう一度確認すると保存状態を復旧します。';
  String get dataFailureMessage => '保存データに問題があります。再試行しても続く場合はサポートにお問い合わせください。';
  String get deletedActivityMessage => 'この活動は削除済みです。ステッカーは再び付与されません。';
  String get goHomeLabel => 'ホームへ';
  String additionalGoals(int count) => 'ほか$count件';
  String get deleteRecordOnlyWarning => '記録のみを削除すると、この活動からステッカーを連動削除できなくなります。';

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

  String overrunTime(String duration) => '超過 +$duration';
}
