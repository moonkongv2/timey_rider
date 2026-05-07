// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class ResultTexts implements ResultTextSet {
  const ResultTexts();

  String get rewardLoading => '보상 정리 중...';
  String get recordSaved => '오늘의 기록을 저장했어';

  String title(bool mealCompleted) =>
      mealCompleted ? '식사 완주 성공!' : '아쉽지만 조금 늦었어';

  String primaryMessage(bool mealCompleted) =>
      mealCompleted ? '오늘의 냠냠코스를 끝까지 잘 마쳤어.' : '오토바이가 먼저 지나갔어.';

  String secondaryMessage(bool mealCompleted) =>
      mealCompleted ? '지나가기 전에 식사를 잘 마쳐서 선물을 받았어!' : '다음 냠냠코스에서 다시 도전해보자.';
}
