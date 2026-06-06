// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class MealIngredientTexts implements MealIngredientTextSet {
  const MealIngredientTexts();

  String get title => '오늘 먹을 재료를 골라볼까?';
  String get subtitle => '고른 재료가 냠냠 코스 위에 차례로 나타나요.';
  String get randomStartButton => '랜덤으로 시작';
  String get selectedStartButton => '고른 재료로 시작';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount개 선택';
  }
}
