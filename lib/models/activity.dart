enum ActivityCompletionMode { confirmDone, timeEndsAutomatically, parentCheck }

enum ActivityMarkerMode { off, manual, activityDefault }

class ActivityDefinition {
  const ActivityDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
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
  final String emoji;
  final Duration defaultDuration;
  final List<Duration> presetDurations;
  final ActivityCompletionMode completionMode;
  final bool rewardEnabledByDefault;
  final List<String> markerIds;

  String labelForLanguage(String languageCode) {
    return languageCode == 'ko' ? labelKo : labelEn;
  }
}
