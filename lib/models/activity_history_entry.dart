import '../catalogs/activity_catalog.dart';
import 'activity_completion_status.dart';

class ActivityHistoryEntry {
  const ActivityHistoryEntry({
    required this.id,
    required this.activityId,
    required this.startedAt,
    required this.endedAt,
    required this.targetDuration,
    required this.actualDuration,
    required this.completedBeforeEnd,
    required this.completionStatus,
    required this.rewardIds,
    this.selectedMarkerIds = const [],
  });

  factory ActivityHistoryEntry.fromJson(Map<String, Object?> json) {
    final rewardIds = json['rewardIds'];
    final selectedMarkerIds = json['selectedMarkerIds'];
    final completedBeforeEnd =
        json['completedBeforeEnd'] as bool? ??
        json['completedBeforeArrival'] as bool? ??
        false;
    final completionStatus = activityCompletionStatusFromJson(
      json['completionStatus'],
      completedBeforeEnd: completedBeforeEnd,
      activityCompleted: json['mealCompleted'] as bool?,
    );

    return ActivityHistoryEntry(
      id: json['id'] as String,
      activityId:
          json['activityId'] as String? ?? ActivityCatalog.defaultActivity.id,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      targetDuration: Duration(milliseconds: json['targetMs'] as int),
      actualDuration: Duration(milliseconds: json['actualMs'] as int),
      completedBeforeEnd: completedBeforeEnd,
      completionStatus: completionStatus,
      rewardIds: rewardIds is List
          ? rewardIds.whereType<String>().toList(growable: false)
          : const [],
      selectedMarkerIds: selectedMarkerIds is List
          ? selectedMarkerIds.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String activityId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration targetDuration;
  final Duration actualDuration;
  final bool completedBeforeEnd;
  final ActivityCompletionStatus completionStatus;
  final List<String> rewardIds;
  final List<String> selectedMarkerIds;

  bool get activityCompleted =>
      _activityCompletionStatusIsCompleted(completionStatus);

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'targetMs': targetDuration.inMilliseconds,
      'actualMs': actualDuration.inMilliseconds,
      'completedBeforeEnd': completedBeforeEnd,
      'completionStatus': completionStatus.name,
      'rewardIds': rewardIds,
      'selectedMarkerIds': selectedMarkerIds,
    };
  }
}

bool _activityCompletionStatusIsCompleted(ActivityCompletionStatus status) {
  return switch (status) {
    ActivityCompletionStatus.completedBeforeEnd ||
    ActivityCompletionStatus.completedAtEnd ||
    ActivityCompletionStatus.completedAfterEnd ||
    ActivityCompletionStatus.timeEnded => true,
    ActivityCompletionStatus.needsMoreTime ||
    ActivityCompletionStatus.canceled => false,
  };
}
