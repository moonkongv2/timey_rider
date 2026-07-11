enum ActivityCompletionMode { confirmDone, timeEndsAutomatically, parentCheck }

enum ActivityMarkerMode { off, manual, activityDefault }

class ActivityDefinition {
  const ActivityDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.labelJa,
    required this.labelEs,
    required this.labelPtBr,
    required this.emoji,
    required this.defaultDuration,
    required this.presetDurations,
    required this.completionMode,
    required this.rewardEnabledByDefault,
    required this.markerIds,
  });

  final String id;
  final String labelKo;
  final String labelEn;
  final String labelJa;
  final String labelEs;
  final String labelPtBr;
  final String emoji;
  final Duration defaultDuration;
  final List<Duration> presetDurations;
  final ActivityCompletionMode completionMode;
  final bool rewardEnabledByDefault;
  final List<String> markerIds;

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
