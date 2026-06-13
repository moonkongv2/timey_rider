import 'package:flutter_test/flutter_test.dart';

import 'package:timey_rider/controllers/activity_timer_controller.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_timer_config.dart';

void main() {
  test(
    'ActivityTimerController restores a running session from wall-clock time',
    () {
      final startedAt = DateTime.utc(2026, 6, 10, 1, 0);
      final now = DateTime.utc(2026, 6, 10, 1, 20);
      final controller = ActivityTimerController.fromSession(
        session: ActiveActivityTimerSession(
          sessionId: 'session-1',
          startedAt: startedAt,
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveActivityTimerSessionState.running,
        ),
        now: () => now,
      );

      expect(controller.state, ActivityTimerState.running);
      expect(controller.startedAt, startedAt);
      expect(controller.elapsed, const Duration(minutes: 20));
      expect(controller.remaining, const Duration(minutes: 10));
      expect(controller.progress, closeTo(2 / 3, 0.001));

      controller.dispose();
    },
  );

  test(
    'ActivityTimerController restores over-duration running sessions as arrived',
    () {
      final controller = ActivityTimerController.fromSession(
        session: ActiveActivityTimerSession(
          sessionId: 'session-2',
          startedAt: DateTime.utc(2026, 6, 10, 1, 0),
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveActivityTimerSessionState.running,
        ),
        now: () => DateTime.utc(2026, 6, 10, 1, 35),
      );

      expect(controller.state, ActivityTimerState.arrived);
      expect(controller.elapsed, const Duration(minutes: 35));
      expect(controller.remaining, Duration.zero);
      expect(controller.progress, 1);

      controller.dispose();
    },
  );

  test(
    'ActivityTimerController restores paused sessions at the paused timestamp',
    () {
      var now = DateTime.utc(2026, 6, 10, 1, 30);
      final pausedAt = DateTime.utc(2026, 6, 10, 1, 12);
      final controller = ActivityTimerController.fromSession(
        session: ActiveActivityTimerSession(
          sessionId: 'session-3',
          startedAt: DateTime.utc(2026, 6, 10, 1, 0),
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveActivityTimerSessionState.paused,
          totalPausedDuration: const Duration(minutes: 2),
          pausedAt: pausedAt,
        ),
        now: () => now,
      );

      expect(controller.state, ActivityTimerState.paused);
      expect(controller.elapsed, const Duration(minutes: 10));
      expect(controller.remaining, const Duration(minutes: 20));

      now = DateTime.utc(2026, 6, 10, 1, 40);
      expect(controller.elapsed, const Duration(minutes: 10));

      controller.resume();
      expect(controller.state, ActivityTimerState.running);
      expect(controller.elapsed, const Duration(minutes: 10));

      controller.dispose();
    },
  );

  test(
    'ActivityTimerController restarts ticking after restored paused sessions resume',
    () async {
      var now = DateTime.utc(2026, 6, 10, 1, 30);
      final controller = ActivityTimerController.fromSession(
        session: ActiveActivityTimerSession(
          sessionId: 'session-5',
          startedAt: DateTime.utc(2026, 6, 10, 1, 0),
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveActivityTimerSessionState.paused,
          pausedAt: DateTime.utc(2026, 6, 10, 1, 10),
        ),
        now: () => now,
      );

      expect(controller.elapsed, const Duration(minutes: 10));

      controller.resume();
      now = DateTime.utc(2026, 6, 10, 1, 31);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(controller.state, ActivityTimerState.running);
      expect(controller.elapsed, const Duration(minutes: 11));

      controller.dispose();
    },
  );

  test(
    'ActivityTimerController refreshes running sessions from wall-clock time',
    () {
      var now = DateTime.utc(2026, 6, 10, 1, 0);
      final controller = ActivityTimerController(
        config: ActivityTimerConfig.defaults().copyWith(
          duration: const Duration(minutes: 30),
        ),
        now: () => now,
      )..start();

      now = DateTime.utc(2026, 6, 10, 1, 12);
      controller.refreshFromClock();

      expect(controller.state, ActivityTimerState.running);
      expect(controller.elapsed, const Duration(minutes: 12));
      expect(controller.remaining, const Duration(minutes: 18));
      expect(controller.progress, closeTo(0.4, 0.001));

      controller.dispose();
    },
  );

  test(
    'ActivityTimerController keeps restored arrived sessions at the finish',
    () {
      final controller = ActivityTimerController.fromSession(
        session: ActiveActivityTimerSession(
          sessionId: 'session-4',
          startedAt: DateTime.utc(2026, 6, 10, 1, 0),
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveActivityTimerSessionState.arrived,
        ),
        now: () => DateTime.utc(2026, 6, 10, 1, 20),
      );

      expect(controller.state, ActivityTimerState.arrived);
      expect(controller.elapsed, const Duration(minutes: 30));
      expect(controller.remaining, Duration.zero);
      expect(controller.progress, 1);

      controller.dispose();
    },
  );

  test('ActivityTimerController completes before end with activity result', () {
    var now = DateTime.utc(2026, 6, 10, 1, 0);
    final config = ActivityTimerConfig.defaults().copyWith(
      activityId: 'reading',
      duration: const Duration(minutes: 30),
    );
    final controller = ActivityTimerController(config: config, now: () => now)
      ..start();

    now = DateTime.utc(2026, 6, 10, 1, 12);
    final result = controller.complete();

    expect(controller.state, ActivityTimerState.completed);
    expect(result.activityId, 'reading');
    expect(result.actualDuration, const Duration(minutes: 12));
    expect(result.completedBeforeEnd, isTrue);
    expect(
      result.completionStatus,
      ActivityCompletionStatus.completedBeforeEnd,
    );
    expect(result.activityCompleted, isTrue);

    controller.dispose();
  });

  test('ActivityTimerController completes after end by default', () {
    var now = DateTime.utc(2026, 6, 10, 1, 0);
    final controller = ActivityTimerController(
      config: ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(minutes: 30),
      ),
      now: () => now,
    )..start();

    now = DateTime.utc(2026, 6, 10, 1, 35);
    final result = controller.complete();

    expect(controller.state, ActivityTimerState.completed);
    expect(result.completedBeforeEnd, isFalse);
    expect(result.completionStatus, ActivityCompletionStatus.completedAfterEnd);
    expect(result.activityCompleted, isTrue);

    controller.dispose();
  });
}
