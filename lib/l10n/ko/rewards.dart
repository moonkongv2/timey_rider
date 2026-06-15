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
  String get rewardGoalEmptyBody => '활동 미션을 완료할 때마다 보상판이 한 칸씩 채워져요.';
  String get rewardGoalRewardFieldLabel => '받을 보상';
  String get rewardGoalRequiredStickerCountLabel => '필요한 스티커 수';
  String get rewardGoalSaveButton => '약속 저장';
  String get rewardGoalReadyMessage => '보상 받을 준비가 됐어요!';
  String get rewardGoalGivenButton => '사용하기';
  String get rewardGoalCreatedMessage => '보상 약속을 저장했어요.';
  String get rewardGoalUpdatedMessage => '보상 약속을 수정했어요.';
  String get rewardGoalCanceledMessage => '보상 약속을 취소했어요.';
  String get rewardGoalRedeemedMessage => '보상 지급을 기록했어요.';
  String get rewardGoalUsedMessage => '보상을 사용했어요.';
  String get rewardGoalProgressTitle => '보상판';
  String get rewardGoalEmptySlotSemanticLabel => '비어 있는 보상칸';
  String get openRewardGoal => '보상판 보기';
  String get rewardGoalPromiseTitle => '이번 보상';
  String get activeRewardGoalsTitle => '진행 중인 보상 약속';
  String get earnedRewardGoalsTitle => '받은 보상';
  String get usedRewardGoalsTitle => '사용한 보상';
  String get maxActiveRewardGoalsMessage => '진행 중인 보상 약속은 최대 2개까지 만들 수 있어요.';
  String get editRewardGoal => '약속 수정';
  String get cancelRewardGoal => '약속 취소';
  String get rewardGoalHistoryTitle => '지급 완료 이력';
  String get rewardGoalNoHistory => '아직 지급 완료된 보상이 없어요.';
  String get confirmRedeemRewardGoalTitle => '보상을 지급했나요?';
  String get confirmRedeemRewardGoalMessage => '완료하면 이 보상 약속은 지급 완료 이력으로 이동해요.';
  String get confirmCancelRewardGoalTitle => '보상 약속을 취소할까요?';
  String get confirmCancelRewardGoalMessage => '현재 보상판 진행 상황이 사라져요.';
  String get keepRewardGoal => '계속 유지';
  String get confirmRewardGiven => '지급 완료';
  String get confirmCancelGoal => '약속 취소';
  String get confirmUseRewardGoalTitle => '이 보상을 사용할까요?';
  String get confirmUseRewardGoalMessage =>
      '사용하면 받은 보상 목록에서 사라지고 사용한 보상에 기록돼요.';
  String get confirmUseRewardGoal => '사용하기';

  String stickerCount(int count) => '$count장';
  String rewardGoalProgress(int filledCount, int requiredCount) =>
      '$filledCount/$requiredCount';
  String rewardGoalRemaining(int remainingCount) => '$remainingCount칸 남았어요';
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName) =>
      '$slotNumber번째 보상칸, $rewardName';
  String rewardGoalReadyAt(String dateLabel) => '완료: $dateLabel';
  String rewardGoalRedeemedAt(String dateLabel) => '지급: $dateLabel';

  String name(String rewardId) {
    return RewardCatalog.findById(rewardId)?.labelForLanguage('ko') ?? rewardId;
  }
}
