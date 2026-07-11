// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaRewardTexts implements RewardTextSet {
  const JaRewardTexts();

  String get collectionTitle => 'ステッカーコレクション';
  String get lockedSticker => 'まだ集めていません';
  String get lockedStatus => 'ロック中';
  String get uncollectedSemanticLabel => 'まだ集めていません';
  String get rewardGoalTitle => 'ごほうび目標';
  String get createRewardGoal => 'ごほうび目標を作る';
  String get rewardGoalEmptyTitle => '新しいごほうび目標を作る';
  String get rewardGoalEmptyBody => '活動を完了するたびに、選んだステッカーがごほうびボードの枠を1つ埋めます。';
  String get rewardGoalRewardFieldLabel => 'ごほうび';
  String get rewardGoalRequiredStickerCountLabel => '必要なステッカー';
  String get rewardGoalSaveButton => '目標を保存';
  String get rewardGoalReadyMessage => 'ごほうびの準備ができました！';
  String get rewardGoalGivenButton => '使用済みにする';
  String get rewardGoalCreatedMessage => 'ごほうび目標を保存しました。';
  String get rewardGoalUpdatedMessage => 'ごほうび目標を更新しました。';
  String get rewardGoalCanceledMessage => 'ごほうび目標をキャンセルしました。';
  String get rewardGoalRedeemedMessage => 'ごほうびを渡しました。';
  String get rewardGoalUsedMessage => 'ごほうびを使用済みにしました。';
  String get rewardGoalProgressTitle => 'ごほうびボード';
  String get rewardGoalEmptySlotSemanticLabel => '空のごほうび枠';
  String get openRewardGoal => 'ごほうびボードを見る';
  String get rewardGoalPromiseTitle => '今のごほうび';
  String get activeRewardGoalsTitle => '進行中のごほうび目標';
  String get earnedRewardGoalsTitle => 'もらえるごほうび';
  String get usedRewardGoalsTitle => '使ったごほうび';
  String get maxActiveRewardGoalsMessage => '進行中のごほうび目標は2つまでです。';
  String get editRewardGoal => '目標を編集';
  String get cancelRewardGoal => '目標をキャンセル';
  String get rewardGoalHistoryTitle => 'ごほうび履歴';
  String get rewardGoalNoHistory => '渡したごほうびはまだありません。';
  String get confirmRedeemRewardGoalTitle => 'ごほうびを渡しましたか？';
  String get confirmRedeemRewardGoalMessage => 'このごほうびは履歴に移動します。';
  String get confirmCancelRewardGoalTitle => 'このごほうび目標をキャンセルしますか？';
  String get confirmCancelRewardGoalMessage => '現在のボード進行は削除されます。';
  String get keepRewardGoal => '目標を残す';
  String get confirmRewardGiven => '渡したことにする';
  String get confirmCancelGoal => '目標をキャンセル';
  String get confirmUseRewardGoalTitle => 'このごほうびを使用済みにしますか？';
  String get confirmUseRewardGoalMessage => 'もらえるごほうびから使ったごほうびへ移動します。';
  String get confirmUseRewardGoal => '使用済みにする';

  String stickerCount(int count) => '$count枚のステッカー';
  String rewardGoalProgress(int filledCount, int requiredCount) =>
      '$filledCount/$requiredCount';
  String rewardGoalRemaining(int remainingCount) => '残り$remainingCount枠';
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName) =>
      'ごほうび枠$slotNumber、$rewardName';
  String rewardGoalReadyAt(String dateLabel) => '準備完了: $dateLabel';
  String rewardGoalRedeemedAt(String dateLabel) => '渡した日: $dateLabel';
}
