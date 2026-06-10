// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class MealIngredientTexts implements MealIngredientTextSet {
  const MealIngredientTexts();

  String get title => '오늘 먹을 재료를 골라볼까?';
  String get subtitle => '고른 재료가 냠냠 코스 위에 차례로 나타나요.';
  String get helpLinkLabel => '식재료는 어떤 의미인가요?';
  String get helpTitle => '도로 위 식재료 안내';
  List<String> get helpBodyParagraphs => const [
    '식재료는 아이가 오늘 먹는 음식을 떠올리도록 돕는 도로 위 표시예요.',
    '영양 평가나 성공/실패 판정이 아니며, 스티커 보상과도 직접 연결되지 않아요.',
  ];
  List<String> get helpBulletItems => const [
    '사용 안 함: 도로 위에 식재료를 표시하지 않아요.',
    '직접 선택: 코스 시작 전 최대 5개까지 고르고, 직접 고른 식재료는 식사 기록에 남아요.',
    '자동 선택: 앱이 랜덤 식재료를 도로에 표시하지만 기록에는 남지 않아요.',
    '식사 기록에는 직접 고른 식재료만 남아요.',
  ];
  String get randomStartButton => '랜덤으로 시작';
  String get selectedStartButton => '선택 시작';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount개 선택';
  }
}
