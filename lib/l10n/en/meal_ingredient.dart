// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnMealIngredientTexts implements MealIngredientTextSet {
  const EnMealIngredientTexts();

  String get title => 'Choose ingredients for this meal';
  String get subtitle =>
      'Your ingredients will appear along the Yamyam course.';
  String get randomStartButton => 'Random start';
  String get selectedStartButton => 'Start with selected';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selected';
  }
}
