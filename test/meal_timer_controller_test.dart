import 'package:flutter_test/flutter_test.dart';

import 'package:jy_yamyam/controllers/meal_timer_controller.dart';
import 'package:jy_yamyam/models/active_meal_timer_session.dart';
import 'package:jy_yamyam/models/meal_timer_config.dart';

void main() {
  test(
    'MealTimerController restores a running session from wall-clock time',
    () {
      final startedAt = DateTime.utc(2026, 6, 10, 1, 0);
      final now = DateTime.utc(2026, 6, 10, 1, 20);
      final controller = MealTimerController.fromSession(
        session: ActiveMealTimerSession(
          sessionId: 'session-1',
          startedAt: startedAt,
          config: MealTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveMealTimerSessionState.running,
        ),
        now: () => now,
      );

      expect(controller.state, MealTimerState.running);
      expect(controller.startedAt, startedAt);
      expect(controller.elapsed, const Duration(minutes: 20));
      expect(controller.remaining, const Duration(minutes: 10));
      expect(controller.progress, closeTo(2 / 3, 0.001));

      controller.dispose();
    },
  );

  test(
    'MealTimerController restores over-duration running sessions as arrived',
    () {
      final controller = MealTimerController.fromSession(
        session: ActiveMealTimerSession(
          sessionId: 'session-2',
          startedAt: DateTime.utc(2026, 6, 10, 1, 0),
          config: MealTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveMealTimerSessionState.running,
        ),
        now: () => DateTime.utc(2026, 6, 10, 1, 35),
      );

      expect(controller.state, MealTimerState.arrived);
      expect(controller.elapsed, const Duration(minutes: 35));
      expect(controller.remaining, Duration.zero);
      expect(controller.progress, 1);

      controller.dispose();
    },
  );

  test(
    'MealTimerController restores paused sessions at the paused timestamp',
    () {
      var now = DateTime.utc(2026, 6, 10, 1, 30);
      final pausedAt = DateTime.utc(2026, 6, 10, 1, 12);
      final controller = MealTimerController.fromSession(
        session: ActiveMealTimerSession(
          sessionId: 'session-3',
          startedAt: DateTime.utc(2026, 6, 10, 1, 0),
          config: MealTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 30),
          ),
          state: ActiveMealTimerSessionState.paused,
          totalPausedDuration: const Duration(minutes: 2),
          pausedAt: pausedAt,
        ),
        now: () => now,
      );

      expect(controller.state, MealTimerState.paused);
      expect(controller.elapsed, const Duration(minutes: 10));
      expect(controller.remaining, const Duration(minutes: 20));

      now = DateTime.utc(2026, 6, 10, 1, 40);
      expect(controller.elapsed, const Duration(minutes: 10));

      controller.resume();
      expect(controller.state, MealTimerState.running);
      expect(controller.elapsed, const Duration(minutes: 10));

      controller.dispose();
    },
  );

  test(
    'MealTimerController refreshes running sessions from wall-clock time',
    () {
      var now = DateTime.utc(2026, 6, 10, 1, 0);
      final controller = MealTimerController(
        config: MealTimerConfig.defaults().copyWith(
          duration: const Duration(minutes: 30),
        ),
        now: () => now,
      )..start();

      now = DateTime.utc(2026, 6, 10, 1, 12);
      controller.refreshFromClock();

      expect(controller.state, MealTimerState.running);
      expect(controller.elapsed, const Duration(minutes: 12));
      expect(controller.remaining, const Duration(minutes: 18));
      expect(controller.progress, closeTo(0.4, 0.001));

      controller.dispose();
    },
  );

  test('MealTimerController keeps restored arrived sessions at the finish', () {
    final controller = MealTimerController.fromSession(
      session: ActiveMealTimerSession(
        sessionId: 'session-4',
        startedAt: DateTime.utc(2026, 6, 10, 1, 0),
        config: MealTimerConfig.defaults().copyWith(
          duration: const Duration(minutes: 30),
        ),
        state: ActiveMealTimerSessionState.arrived,
      ),
      now: () => DateTime.utc(2026, 6, 10, 1, 20),
    );

    expect(controller.state, MealTimerState.arrived);
    expect(controller.elapsed, const Duration(minutes: 30));
    expect(controller.remaining, Duration.zero);
    expect(controller.progress, 1);

    controller.dispose();
  });
}
