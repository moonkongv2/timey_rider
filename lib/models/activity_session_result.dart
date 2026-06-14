import 'activity_completion_status.dart';

class ActivitySessionResult {
  const ActivitySessionResult({
    required this.activityId,
    required this.startedAt,
    required this.endedAt,
    required this.targetDuration,
    required this.actualDuration,
    required this.completedBeforeEnd,
    required this.completionStatus,
    this.selectedMarkerIds = const [],
  });

  final String activityId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration targetDuration;
  final Duration actualDuration;
  final bool completedBeforeEnd;
  final ActivityCompletionStatus completionStatus;
  final List<String> selectedMarkerIds;

  bool get activityCompleted =>
      activityCompletionStatusIsCompleted(completionStatus);

  ActivitySessionResult copyWith({List<String>? selectedMarkerIds}) {
    return ActivitySessionResult(
      activityId: activityId,
      startedAt: startedAt,
      endedAt: endedAt,
      targetDuration: targetDuration,
      actualDuration: actualDuration,
      completedBeforeEnd: completedBeforeEnd,
      completionStatus: completionStatus,
      selectedMarkerIds: selectedMarkerIds ?? this.selectedMarkerIds,
    );
  }
}
