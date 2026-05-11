class VehicleDefinition {
  const VehicleDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.emoji,
    required this.assetPath,
    this.selectionAssetPath,
  });

  final String id;
  final String labelKo;
  final String labelEn;
  final String emoji;
  final String assetPath;
  final String? selectionAssetPath;

  String get selectionImagePath => selectionAssetPath ?? assetPath;

  String labelForLanguage(String languageCode) {
    return languageCode == 'ko' ? labelKo : labelEn;
  }
}
