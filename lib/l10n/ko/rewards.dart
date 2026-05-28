// ignore_for_file: annotate_overrides

import '../../models/reward_item.dart';
import '../text_sets.dart';

class RewardTexts implements RewardTextSet {
  const RewardTexts();

  String get collectionTitle => '스티커 보관함';
  String get lockedSticker => '아직 미획득';
  String get lockedStatus => '잠금';
  String get uncollectedSemanticLabel => '아직 미획득';
  String get rewardGoalTitle => '보상 약속';
  String get createRewardGoal => '보상 약속 만들기';
  String get rewardGoalEmptyTitle => '새 보상 약속을 만들어 주세요';
  String get rewardGoalEmptyBody => '식사를 완료할 때마다 보상판이 한 칸씩 채워져요.';
  String get rewardGoalRewardFieldLabel => '받을 보상';
  String get rewardGoalRequiredStickerCountLabel => '필요한 스티커 수';
  String get rewardGoalSaveButton => '약속 저장';
  String get rewardGoalReadyMessage => '보상 받을 준비가 됐어요!';
  String get rewardGoalGivenButton => '보상 지급 완료';
  String get rewardGoalCreatedMessage => '보상 약속을 저장했어요.';
  String get rewardGoalRedeemedMessage => '보상 지급을 기록했어요.';
  String get rewardGoalProgressTitle => '보상판';
  String get rewardGoalEmptySlotSemanticLabel => '비어 있는 보상칸';
  String get openRewardGoal => '보상판 보기';
  String get rewardGoalPromiseTitle => '이번 보상';

  String stickerCount(int count) => '$count장';
  String rewardGoalProgress(int filledCount, int requiredCount) =>
      '$filledCount/$requiredCount';
  String rewardGoalRemaining(int remainingCount) => '$remainingCount칸 남았어요';
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName) =>
      '$slotNumber번째 보상칸, $rewardName';

  String name(String rewardId) {
    return switch (rewardId) {
      RewardCatalog.finishFlagStickerId => '도착 깃발 스티커',
      RewardCatalog.twinkleStarStickerId => '반짝 별 스티커',
      RewardCatalog.riceBowlStickerId => '든든 밥그릇 스티커',
      RewardCatalog.yumSpoonStickerId => '냠냠 숟가락 스티커',
      RewardCatalog.crunchyCarrotStickerId => '아삭 당근 스티커',
      RewardCatalog.sunnyMealStickerId => '햇살 식사 스티커',
      RewardCatalog.rainbowCourseStickerId => '무지개 코스 스티커',
      RewardCatalog.rocketBiteStickerId => '로켓 한입 스티커',
      _ => rewardId,
    };
  }
}
