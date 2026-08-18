import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_session_result.dart';
import 'package:timey_rider/models/activity_progress_snapshot.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

ActivitySessionResult activityResult({
  String activityId = 'brushing',
  DateTime? startedAt,
  DateTime? endedAt,
  Duration targetDuration = const Duration(minutes: 20),
  Duration actualDuration = const Duration(minutes: 25),
  bool completedBeforeEnd = false,
  bool activityCompleted = true,
  ActivityCompletionStatus? completionStatus,
  List<String> selectedMarkerIds = const [],
  bool includeStickerDecision = true,
  bool? receiveSticker,
}) {
  final resolvedStartedAt = startedAt ?? DateTime(2026, 5, 4, 12);
  final resolvedEndedAt = endedAt ?? resolvedStartedAt.add(actualDuration);
  final resolvedCompletionStatus =
      completionStatus ??
      (activityCompleted
          ? (completedBeforeEnd
                ? ActivityCompletionStatus.completedBeforeEnd
                : ActivityCompletionStatus.completedAfterEnd)
          : ActivityCompletionStatus.needsMoreTime);

  return ActivitySessionResult(
    activityId: activityId,
    startedAt: resolvedStartedAt,
    endedAt: resolvedEndedAt,
    targetDuration: targetDuration,
    actualDuration: actualDuration,
    completedBeforeEnd: completedBeforeEnd,
    completionStatus: resolvedCompletionStatus,
    selectedMarkerIds: selectedMarkerIds,
    receiveSticker: includeStickerDecision
        ? receiveSticker ??
              (ActivityCatalog.findById(activityId).rewardEnabledByDefault &&
                  activityCompletionStatusCanReceiveSticker(
                    resolvedCompletionStatus,
                  ))
        : null,
  );
}

Future<RecordedActivitySession> recordActivityResult(
  LocalActivityProgressService service,
  ActivitySessionResult result, {
  String vehicleId = 'motorcycle',
}) {
  return service.recordActivityResult(result, vehicleId: vehicleId);
}
