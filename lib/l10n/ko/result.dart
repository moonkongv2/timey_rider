// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class ResultTexts implements ResultTextSet {
  const ResultTexts();

  String get rewardLoading => '보상 정리 중...';
  String get recordSaved => '오늘의 기록을 저장했어';

  String title(bool mealCompleted) =>
      mealCompleted ? '식사 완주 성공!' : '아쉽지만 조금 늦었어';

  String primaryMessage(bool mealCompleted, {String? vehicleId}) =>
      mealCompleted
      ? '오늘의 냠냠코스를 끝까지 잘 마쳤어.'
      : _failedPrimaryMessagesByVehicle[vehicleId] ?? '오토바이가 먼저 지나갔어.';

  String secondaryMessage(bool mealCompleted) =>
      mealCompleted ? '지나가기 전에 식사를 잘 마쳐서 선물을 받았어!' : '다음 냠냠코스에서 다시 도전해보자.';
}

const _failedPrimaryMessagesByVehicle = {
  'motorcycle': '오토바이가 먼저 지나갔어.',
  'fire_truck': '소방차가 먼저 출동했어.',
  'police_car': '경찰차가 먼저 지나갔어.',
  'excavator': '포크레인이 먼저 움직였어.',
  'airplane': '비행기가 먼저 날아갔어.',
  'bus': '버스가 먼저 출발했어.',
  'supercar': '슈퍼카가 먼저 달려갔어.',
  'train': '기차가 먼저 떠났어.',
  't_rex': '티렉스가 먼저 쿵쿵 지나갔어.',
  'shark': '상어가 먼저 헤엄쳐 갔어.',
  'brachio': '브라키오가 먼저 걸어갔어.',
  'pteranodon': '프테라노돈이 먼저 날아갔어.',
};
