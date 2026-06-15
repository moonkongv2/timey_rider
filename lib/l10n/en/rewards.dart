// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnRewardTexts implements RewardTextSet {
  const EnRewardTexts();

  String get collectionTitle => 'Vehicle Sticker Collection';
  String get lockedSticker => 'Not collected yet';
  String get lockedStatus => 'Locked';
  String get uncollectedSemanticLabel => 'Not collected yet';
  String get rewardGoalTitle => 'Reward Promise';
  String get createRewardGoal => 'Create Reward Promise';
  String get rewardGoalEmptyTitle => 'Create a new reward promise';
  String get rewardGoalEmptyBody =>
      'Each completed activity adds the selected vehicle sticker and fills one reward board space.';
  String get rewardGoalRewardFieldLabel => 'Reward';
  String get rewardGoalRequiredStickerCountLabel => 'Vehicle stickers needed';
  String get rewardGoalSaveButton => 'Save Promise';
  String get rewardGoalReadyMessage => 'Your reward is ready!';
  String get rewardGoalGivenButton => 'Use Reward';
  String get rewardGoalCreatedMessage => 'Reward promise saved.';
  String get rewardGoalUpdatedMessage => 'Reward promise updated.';
  String get rewardGoalCanceledMessage => 'Reward promise canceled.';
  String get rewardGoalRedeemedMessage => 'Reward given.';
  String get rewardGoalUsedMessage => 'Reward used.';
  String get rewardGoalProgressTitle => 'Reward Board';
  String get rewardGoalEmptySlotSemanticLabel => 'Empty reward slot';
  String get openRewardGoal => 'View Reward Board';
  String get rewardGoalPromiseTitle => 'Current Reward';
  String get activeRewardGoalsTitle => 'Active Reward Promises';
  String get earnedRewardGoalsTitle => 'Earned Rewards';
  String get usedRewardGoalsTitle => 'Used Rewards';
  String get maxActiveRewardGoalsMessage =>
      'You can keep up to 2 active reward promises.';
  String get editRewardGoal => 'Edit Promise';
  String get cancelRewardGoal => 'Cancel Promise';
  String get rewardGoalHistoryTitle => 'Reward History';
  String get rewardGoalNoHistory => 'No rewards have been given yet.';
  String get confirmRedeemRewardGoalTitle => 'Was the reward given?';
  String get confirmRedeemRewardGoalMessage =>
      'This promise will move to reward history.';
  String get confirmCancelRewardGoalTitle => 'Cancel this reward promise?';
  String get confirmCancelRewardGoalMessage =>
      'The current board progress will be removed.';
  String get keepRewardGoal => 'Keep Promise';
  String get confirmRewardGiven => 'Mark Given';
  String get confirmCancelGoal => 'Cancel Promise';
  String get confirmUseRewardGoalTitle => 'Use this reward?';
  String get confirmUseRewardGoalMessage =>
      'It will move from earned rewards to used rewards.';
  String get confirmUseRewardGoal => 'Use Reward';

  String stickerCount(int count) => '$count vehicle stickers';
  String rewardGoalProgress(int filledCount, int requiredCount) =>
      '$filledCount/$requiredCount';
  String rewardGoalRemaining(int remainingCount) =>
      '$remainingCount spaces to go';
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName) =>
      'Reward slot $slotNumber, $rewardName';
  String rewardGoalReadyAt(String dateLabel) => 'Ready: $dateLabel';
  String rewardGoalRedeemedAt(String dateLabel) => 'Given: $dateLabel';
}
