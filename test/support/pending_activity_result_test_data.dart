import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_session_result.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/pending_activity_result.dart';

PendingActivityResult pendingResult({bool? receiveSticker}) {
  final start = DateTime.utc(2026, 10, 6, 1);
  return PendingActivityResult(
    session: ActiveActivityTimerSession(
      sessionId: 'finished-session',
      startedAt: start,
      config: ActivityTimerConfig.defaults().copyWith(
        childName: 'Riley',
        activityId: 'reading',
      ),
      state: ActiveActivityTimerSessionState.arrived,
    ),
    result: ActivitySessionResult(
      sessionId: 'finished-session',
      activityId: 'reading',
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 2)),
      targetDuration: const Duration(minutes: 5),
      actualDuration: const Duration(minutes: 2),
      completedBeforeEnd: true,
      completionStatus: ActivityCompletionStatus.completedBeforeEnd,
      selectedMarkerIds: const ['book'],
      receiveSticker: receiveSticker,
    ),
  );
}
