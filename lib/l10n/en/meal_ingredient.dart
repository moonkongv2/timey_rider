// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnMealIngredientTexts implements MealIngredientTextSet {
  const EnMealIngredientTexts();

  String get title => 'Choose ingredients for this meal';
  String get subtitle =>
      'Your ingredients will appear along the Yamyam course.';
  String get helpLinkLabel => 'What do ingredients mean?';
  String get helpTitle => 'Road ingredients';
  List<String> get helpBodyParagraphs => const [
    'Ingredients are visual markers on the road that help the child think about today’s food.',
    'They are not nutrition scoring, success/failure rules, or sticker reward rules.',
  ];
  List<String> get helpBulletItems => const [
    'Off: no ingredients are shown on the road.',
    'Manual: choose up to 5 ingredients before starting; manually chosen ingredients are saved in meal history.',
    'Auto: the app shows random ingredients on the road, but they are not saved in history.',
    'Only manually chosen ingredients are saved to meal records.',
  ];
  String get randomStartButton => 'Random start';
  String get selectedStartButton => 'Start selected';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selected';
  }
}
