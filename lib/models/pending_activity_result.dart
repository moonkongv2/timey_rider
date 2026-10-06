import 'active_activity_timer_session.dart';
import 'activity_completion_status.dart';
import 'activity_session_result.dart';

class PendingActivityResult {
  const PendingActivityResult({required this.session, required this.result});

  final ActiveActivityTimerSession session;
  final ActivitySessionResult result;

  Map<String, Object?> toJson() => {
    'session': session.toJson(),
    'result': {
      'endedAt': result.endedAt.toIso8601String(),
      'actualDurationMs': result.actualDuration.inMilliseconds,
      'completedBeforeEnd': result.completedBeforeEnd,
      'completionStatus': result.completionStatus.name,
      'selectedMarkerIds': result.selectedMarkerIds,
      'receiveSticker': result.receiveSticker,
    },
  };

  factory PendingActivityResult.fromJson(Map<String, Object?> json) {
    final session = ActiveActivityTimerSession.fromJson(
      Map<String, Object?>.from(json['session'] as Map),
    );
    final result = Map<String, Object?>.from(json['result'] as Map);
    final completedBeforeEnd = result['completedBeforeEnd'] as bool;
    return PendingActivityResult(
      session: session,
      result: ActivitySessionResult(
        sessionId: session.sessionId,
        activityId: session.config.activityId,
        startedAt: session.startedAt,
        endedAt: DateTime.parse(result['endedAt'] as String),
        targetDuration: session.config.duration,
        actualDuration: Duration(
          milliseconds: result['actualDurationMs'] as int,
        ),
        completedBeforeEnd: completedBeforeEnd,
        completionStatus: activityCompletionStatusFromJson(
          result['completionStatus'],
          completedBeforeEnd: completedBeforeEnd,
        ),
        selectedMarkerIds: List<String>.from(
          result['selectedMarkerIds'] as List,
        ),
        receiveSticker: result['receiveSticker'] as bool?,
      ),
    );
  }
}
