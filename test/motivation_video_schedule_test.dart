import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/utils/motivation_video_schedule.dart'
    as motivation_schedule;

void main() {
  test('Motivation milestone selection keeps the first crossed milestone', () {
    expect(nextMotivationMilestoneForProgress(0.09, {}), isNull);
    expect(nextMotivationMilestoneForProgress(0.10, {}), 10);
    expect(nextMotivationMilestoneForProgress(0.24, {}), 10);
    expect(nextMotivationMilestoneForProgress(0.24, {10}), 20);
    expect(nextMotivationMilestoneForProgress(1.0, {}), isNull);
  });

  test(
    'Motivation schedule switches to three-minute cadence after 30 minutes',
    () {
      expect(usesTimedMotivationSchedule(const Duration(minutes: 30)), isFalse);
      expect(usesTimedMotivationSchedule(const Duration(minutes: 31)), isTrue);

      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 30),
          elapsed: const Duration(minutes: 3),
          progress: 0.10,
          shownMilestones: {},
        ),
        10,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 2, seconds: 59),
          progress: 0.05,
          shownMilestones: {},
        ),
        isNull,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 3),
          progress: 0.05,
          shownMilestones: {},
        ),
        3,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 6, seconds: 1),
          progress: 0.10,
          shownMilestones: {3},
        ),
        6,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 9, seconds: 59),
          progress: 0.16,
          shownMilestones: {},
        ),
        9,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 60),
          progress: 1,
          shownMilestones: {57},
        ),
        isNull,
      );
    },
  );

  test('Motivation schedule can be disabled from config', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(motivationVideoEnabled: false),
    );

    expect(schedule.usesTimedSchedule(const Duration(minutes: 60)), isFalse);
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 60),
        elapsed: const Duration(minutes: 3),
        progress: 0.05,
        shownMilestones: {},
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 2),
        progress: 0.10,
        shownMilestones: {},
      ),
      isNull,
    );
  });

  test('Custom motivation interval ignores percent milestones', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 5),
      ),
    );

    expect(schedule.usesTimedSchedule(const Duration(minutes: 15)), isTrue);
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 2),
        progress: 0.10,
        shownMilestones: {},
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 5),
        progress: 0.33,
        shownMilestones: {},
      ),
      5,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 10),
        progress: 0.66,
        shownMilestones: {5},
      ),
      10,
    );
  });

  test('Custom motivation interval longer than timer duration never plays', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 10),
      ),
    );

    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 5),
        elapsed: const Duration(minutes: 4, seconds: 59),
        progress: 0.99,
        shownMilestones: {},
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 5),
        elapsed: const Duration(minutes: 5),
        progress: 1,
        shownMilestones: {},
      ),
      isNull,
    );
  });

  test('Timed motivation schedule can restart from an elapsed offset', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 3),
      ),
    );

    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 60),
        elapsed: const Duration(minutes: 10, seconds: 59),
        progress: 0.18,
        shownMilestones: {},
        scheduleStartedAt: const Duration(minutes: 8),
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 60),
        elapsed: const Duration(minutes: 11),
        progress: 0.18,
        shownMilestones: {},
        scheduleStartedAt: const Duration(minutes: 8),
      ),
      11,
    );
  });

  test('Motivation video interval requires at least 10 seconds', () {
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 9),
        lastShownAt: null,
      ),
      isFalse,
    );
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 10),
        lastShownAt: null,
      ),
      isTrue,
    );
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 15),
        lastShownAt: const Duration(seconds: 6),
      ),
      isFalse,
    );
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 16),
        lastShownAt: const Duration(seconds: 6),
      ),
      isTrue,
    );
  });
}
