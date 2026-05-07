// ignore_for_file: annotate_overrides

import '../../models/reward_item.dart';
import '../text_sets.dart';

class EnRewardTexts implements RewardTextSet {
  const EnRewardTexts();

  String get collectionTitle => 'Sticker Collection';
  String get lockedSticker => 'Not collected yet';
  String get lockedStatus => 'Locked';
  String get uncollectedSemanticLabel => 'Not collected yet';

  String stickerCount(int count) => '$count';

  String name(String rewardId) {
    return switch (rewardId) {
      RewardCatalog.finishFlagStickerId => 'Finish Flag Sticker',
      RewardCatalog.twinkleStarStickerId => 'Twinkle Star Sticker',
      RewardCatalog.riderHelmetStickerId => 'Rider Helmet Sticker',
      RewardCatalog.riceBowlStickerId => 'Hearty Rice Bowl Sticker',
      RewardCatalog.yumSpoonStickerId => 'Yummy Spoon Sticker',
      RewardCatalog.crunchyCarrotStickerId => 'Crunchy Carrot Sticker',
      RewardCatalog.sunnyMealStickerId => 'Sunny Meal Sticker',
      RewardCatalog.rainbowCourseStickerId => 'Rainbow Ride Sticker',
      RewardCatalog.rocketBiteStickerId => 'Rocket Bite Sticker',
      RewardCatalog.happyRiderStickerId => 'Happy Rider Sticker',
      RewardCatalog.lightningYumStickerId => 'Lightning Yum Sticker',
      _ => rewardId,
    };
  }
}
