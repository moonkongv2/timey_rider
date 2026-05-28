// ignore_for_file: annotate_overrides

import '../../models/reward_item.dart';
import '../text_sets.dart';

class EnRewardTexts implements RewardTextSet {
  const EnRewardTexts();

  String get collectionTitle => 'Sticker Collection';
  String get lockedSticker => 'Not collected yet';
  String get lockedStatus => 'Locked';
  String get uncollectedSemanticLabel => 'Not collected yet';
  String get rewardGoalTitle => 'Reward Promise';
  String get createRewardGoal => 'Create Reward Promise';
  String get rewardGoalEmptyTitle => 'Create a new reward promise';
  String get rewardGoalEmptyBody =>
      'Each completed meal fills one space on the reward board.';
  String get rewardGoalRewardFieldLabel => 'Reward';
  String get rewardGoalRequiredStickerCountLabel => 'Stickers needed';
  String get rewardGoalSaveButton => 'Save Promise';
  String get rewardGoalReadyMessage => 'Your reward is ready!';
  String get rewardGoalGivenButton => 'Reward Given';
  String get rewardGoalCreatedMessage => 'Reward promise saved.';
  String get rewardGoalRedeemedMessage => 'Reward given.';
  String get rewardGoalProgressTitle => 'Reward Board';
  String get rewardGoalEmptySlotSemanticLabel => 'Empty reward slot';
  String get openRewardGoal => 'View Reward Board';
  String get rewardGoalPromiseTitle => 'Current Reward';

  String stickerCount(int count) => '$count';
  String rewardGoalProgress(int filledCount, int requiredCount) =>
      '$filledCount/$requiredCount';
  String rewardGoalRemaining(int remainingCount) =>
      '$remainingCount spaces to go';
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName) =>
      'Reward slot $slotNumber, $rewardName';

  String name(String rewardId) {
    return switch (rewardId) {
      RewardCatalog.finishFlagStickerId => 'Finish Flag Sticker',
      RewardCatalog.twinkleStarStickerId => 'Twinkle Star Sticker',
      RewardCatalog.riceBowlStickerId => 'Hearty Rice Bowl Sticker',
      RewardCatalog.yumSpoonStickerId => 'Yummy Spoon Sticker',
      RewardCatalog.crunchyCarrotStickerId => 'Crunchy Carrot Sticker',
      RewardCatalog.sunnyMealStickerId => 'Sunny Meal Sticker',
      RewardCatalog.rainbowCourseStickerId => 'Rainbow Ride Sticker',
      RewardCatalog.rocketBiteStickerId => 'Rocket Bite Sticker',
      _ => rewardId,
    };
  }
}
