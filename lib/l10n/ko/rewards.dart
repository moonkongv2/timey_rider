// ignore_for_file: annotate_overrides

import '../../models/reward_item.dart';
import '../text_sets.dart';

class RewardTexts implements RewardTextSet {
  const RewardTexts();

  String get collectionTitle => '스티커 보관함';
  String get lockedSticker => '아직 미획득';
  String get lockedStatus => '잠금';
  String get uncollectedSemanticLabel => '아직 미획득';

  String stickerCount(int count) => '$count장';

  String name(String rewardId) {
    return switch (rewardId) {
      RewardCatalog.finishFlagStickerId => '도착 깃발 스티커',
      RewardCatalog.twinkleStarStickerId => '반짝 별 스티커',
      RewardCatalog.riderHelmetStickerId => '멋진 헬멧 스티커',
      RewardCatalog.riceBowlStickerId => '든든 밥그릇 스티커',
      RewardCatalog.yumSpoonStickerId => '냠냠 숟가락 스티커',
      RewardCatalog.crunchyCarrotStickerId => '아삭 당근 스티커',
      RewardCatalog.sunnyMealStickerId => '햇살 식사 스티커',
      RewardCatalog.rainbowCourseStickerId => '무지개 코스 스티커',
      RewardCatalog.rocketBiteStickerId => '로켓 한입 스티커',
      RewardCatalog.happyRiderStickerId => '신나는 라이더 스티커',
      RewardCatalog.lightningYumStickerId => '번개 냠냠 스티커',
      _ => rewardId,
    };
  }
}
