class ActivityMarkerDefinition {
  const ActivityMarkerDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.emoji,
    this.assetPath,
    this.activityIds = const [],
  });

  final String id;
  final String labelKo;
  final String labelEn;
  final String emoji;
  final String? assetPath;
  final List<String> activityIds;

  String labelForLanguage(String languageCode) {
    return languageCode == 'ko' ? labelKo : labelEn;
  }
}
