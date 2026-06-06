class MealIngredientDefinition {
  const MealIngredientDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.emoji,
    this.assetPath,
  });

  final String id;
  final String labelKo;
  final String labelEn;
  final String emoji;
  final String? assetPath;

  String labelForLanguage(String languageCode) {
    return languageCode == 'ko' ? labelKo : labelEn;
  }
}
