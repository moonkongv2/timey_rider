class VehicleDefinition {
  const VehicleDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.emoji,
    required this.assetPath,
  });

  final String id;
  final String labelKo;
  final String labelEn;
  final String emoji;
  final String assetPath;

  String labelForLanguage(String languageCode) {
    return languageCode == 'ko' ? labelKo : labelEn;
  }
}
