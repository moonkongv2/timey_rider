class MealHistoryEntry {
  const MealHistoryEntry({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.targetDuration,
    required this.actualDuration,
    required this.completedBeforeArrival,
    required this.rewardIds,
  });

  factory MealHistoryEntry.fromJson(Map<String, Object?> json) {
    final rewardIds = json['rewardIds'];

    return MealHistoryEntry(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      targetDuration: Duration(milliseconds: json['targetMs'] as int),
      actualDuration: Duration(milliseconds: json['actualMs'] as int),
      completedBeforeArrival: json['completedBeforeArrival'] as bool,
      rewardIds: rewardIds is List
          ? rewardIds.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration targetDuration;
  final Duration actualDuration;
  final bool completedBeforeArrival;
  final List<String> rewardIds;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'targetMs': targetDuration.inMilliseconds,
      'actualMs': actualDuration.inMilliseconds,
      'completedBeforeArrival': completedBeforeArrival,
      'rewardIds': rewardIds,
    };
  }
}
