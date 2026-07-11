class ActivityMarkerDefinition {
  const ActivityMarkerDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.labelJa,
    required this.labelEs,
    required this.labelPtBr,
    required this.emoji,
    this.assetPath,
    this.activityIds = const [],
  });

  final String id;
  final String labelKo;
  final String labelEn;
  final String labelJa;
  final String labelEs;
  final String labelPtBr;
  final String emoji;
  final String? assetPath;
  final List<String> activityIds;

  String labelForLanguage(String languageCode) {
    return switch (languageCode) {
      'ko' => labelKo,
      'ja' => labelJa,
      'es' => labelEs,
      'pt' => labelPtBr,
      _ => labelEn,
    };
  }
}
