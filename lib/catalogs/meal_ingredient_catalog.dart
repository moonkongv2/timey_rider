import 'dart:math' as math;

import '../models/meal_ingredient.dart';

abstract final class MealIngredientCatalog {
  static const maxSelectableIngredientCount = 5;
  static const minCourseSlotCount = 30;
  static const maxCourseSlotCount = 144;
  static const referenceCourseDuration = Duration(minutes: 5);

  static const carrot = MealIngredientDefinition(
    id: 'carrot',
    labelKo: '당근',
    labelEn: 'Carrot',
    emoji: '🥕',
  );

  static const egg = MealIngredientDefinition(
    id: 'egg',
    labelKo: '달걀',
    labelEn: 'Egg',
    emoji: '🍳',
    assetPath: 'assets/images/ingredients/egg.png',
  );

  static const meat = MealIngredientDefinition(
    id: 'meat',
    labelKo: '고기',
    labelEn: 'Meat',
    emoji: '🥩',
  );

  static const onion = MealIngredientDefinition(
    id: 'onion',
    labelKo: '양파',
    labelEn: 'Onion',
    emoji: '🧅',
  );

  static const cucumber = MealIngredientDefinition(
    id: 'cucumber',
    labelKo: '오이',
    labelEn: 'Cucumber',
    emoji: '🥒',
  );

  static const rice = MealIngredientDefinition(
    id: 'rice',
    labelKo: '밥',
    labelEn: 'Rice',
    emoji: '🍚',
  );

  static const seaweed = MealIngredientDefinition(
    id: 'seaweed',
    labelKo: '김',
    labelEn: 'Seaweed',
    emoji: '🟩',
    assetPath: 'assets/images/ingredients/seaweed.png',
  );

  static const tofu = MealIngredientDefinition(
    id: 'tofu',
    labelKo: '두부',
    labelEn: 'Tofu',
    emoji: '⬜',
    assetPath: 'assets/images/ingredients/tofu.png',
  );

  static const broccoli = MealIngredientDefinition(
    id: 'broccoli',
    labelKo: '브로콜리',
    labelEn: 'Broccoli',
    emoji: '🥦',
  );

  static const tomato = MealIngredientDefinition(
    id: 'tomato',
    labelKo: '토마토',
    labelEn: 'Tomato',
    emoji: '🍅',
  );

  static const potato = MealIngredientDefinition(
    id: 'potato',
    labelKo: '감자',
    labelEn: 'Potato',
    emoji: '🥔',
  );

  static const fish = MealIngredientDefinition(
    id: 'fish',
    labelKo: '생선',
    labelEn: 'Fish',
    emoji: '🐟',
  );

  static const mushroom = MealIngredientDefinition(
    id: 'mushroom',
    labelKo: '버섯',
    labelEn: 'Mushroom',
    emoji: '🍄',
  );

  static const cheese = MealIngredientDefinition(
    id: 'cheese',
    labelKo: '치즈',
    labelEn: 'Cheese',
    emoji: '🧀',
  );

  static const apple = MealIngredientDefinition(
    id: 'apple',
    labelKo: '사과',
    labelEn: 'Apple',
    emoji: '🍎',
  );

  static const all = [
    carrot,
    egg,
    meat,
    onion,
    cucumber,
    rice,
    seaweed,
    tofu,
    broccoli,
    tomato,
    potato,
    fish,
    mushroom,
    cheese,
    apple,
  ];

  static const defaultSelectionIds = [
    'carrot',
    'egg',
    'rice',
    'broccoli',
    'apple',
  ];

  static MealIngredientDefinition? findById(String id) {
    for (final ingredient in all) {
      if (ingredient.id == id) {
        return ingredient;
      }
    }
    return null;
  }

  static List<String> randomSelectionIds({
    int count = maxSelectableIngredientCount,
    math.Random? random,
  }) {
    if (count <= 0) {
      return const [];
    }

    final shuffled = all.map((ingredient) => ingredient.id).toList();
    shuffled.shuffle(random ?? math.Random());
    return List.unmodifiable(shuffled.take(math.min(count, shuffled.length)));
  }

  static List<MealIngredientDefinition> courseSlotsFor(
    List<String> selectedIds, {
    int slotCount = minCourseSlotCount,
  }) {
    if (slotCount <= 0) {
      return const [];
    }

    final selectedIngredients = _ingredientsForIds(selectedIds);
    final ingredients = selectedIngredients.isEmpty
        ? _ingredientsForIds(defaultSelectionIds)
        : selectedIngredients;
    final slots = <MealIngredientDefinition>[];

    for (var index = 0; index < slotCount; index += 1) {
      var ingredient = ingredients[index % ingredients.length];
      if (ingredients.length >= 2 &&
          slots.length >= 2 &&
          slots[slots.length - 1].id == ingredient.id &&
          slots[slots.length - 2].id == ingredient.id) {
        ingredient = ingredients[(index + 1) % ingredients.length];
      }
      slots.add(ingredient);
    }

    return List.unmodifiable(slots);
  }

  static int courseSlotCountForDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return minCourseSlotCount;
    }

    final durationFactor =
        duration.inMilliseconds / referenceCourseDuration.inMilliseconds;
    final clampedFactor = math.max(1.0, durationFactor);
    final targetSlotCount = (18 * clampedFactor).round();
    return targetSlotCount
        .clamp(minCourseSlotCount, maxCourseSlotCount)
        .toInt();
  }

  static List<MealIngredientDefinition> _ingredientsForIds(List<String> ids) {
    final ingredients = <MealIngredientDefinition>[];
    final seenIds = <String>{};
    for (final id in ids) {
      final ingredient = findById(id);
      if (ingredient == null || !seenIds.add(ingredient.id)) {
        continue;
      }
      ingredients.add(ingredient);
    }
    return ingredients;
  }
}
