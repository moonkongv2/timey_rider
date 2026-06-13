import '../models/activity_timer_config.dart';

const motivationLongCourseThreshold = Duration(minutes: 30);
const motivationDefaultTimedVideoInterval = Duration(minutes: 3);

class MotivationVideoSchedule {
  const MotivationVideoSchedule({
    required this.enabled,
    required this.useCustomInterval,
    required this.customInterval,
  });

  factory MotivationVideoSchedule.fromConfig(ActivityTimerConfig config) {
    return MotivationVideoSchedule(
      enabled: config.motivationVideoEnabled,
      useCustomInterval: config.motivationVideoUseCustomInterval,
      customInterval: config.motivationVideoInterval,
    );
  }

  static const defaults = MotivationVideoSchedule(
    enabled: true,
    useCustomInterval: false,
    customInterval: motivationDefaultTimedVideoInterval,
  );

  final bool enabled;
  final bool useCustomInterval;
  final Duration customInterval;

  bool usesTimedSchedule(Duration duration) {
    if (!enabled) {
      return false;
    }

    return useCustomInterval || duration > motivationLongCourseThreshold;
  }

  int? nextMilestoneForTimer({
    required Duration duration,
    required Duration elapsed,
    required double progress,
    required Set<int> shownMilestones,
    Duration scheduleStartedAt = Duration.zero,
  }) {
    if (!enabled) {
      return null;
    }

    if (useCustomInterval) {
      return nextTimedMotivationMilestoneForElapsed(
        elapsed: elapsed,
        duration: duration,
        shownMilestones: shownMilestones,
        interval: customInterval,
        scheduleStartedAt: scheduleStartedAt,
      );
    }

    if (duration > motivationLongCourseThreshold) {
      return nextTimedMotivationMilestoneForElapsed(
        elapsed: elapsed,
        duration: duration,
        shownMilestones: shownMilestones,
        interval: motivationDefaultTimedVideoInterval,
        scheduleStartedAt: scheduleStartedAt,
      );
    }

    return nextMotivationMilestoneForProgress(progress, shownMilestones);
  }
}

int? nextMotivationMilestoneForProgress(
  double progress,
  Set<int> shownMilestones,
) {
  if (progress <= 0 || progress >= 1) {
    return null;
  }

  final reachedPercent = (progress * 100).floor();
  for (var milestone = 10; milestone <= 90; milestone += 10) {
    if (reachedPercent >= milestone && !shownMilestones.contains(milestone)) {
      return milestone;
    }
  }

  return null;
}

int? nextTimedMotivationMilestoneForElapsed({
  required Duration elapsed,
  required Duration duration,
  required Set<int> shownMilestones,
  Duration interval = motivationDefaultTimedVideoInterval,
  Duration scheduleStartedAt = Duration.zero,
}) {
  if (interval <= Duration.zero ||
      duration <= Duration.zero ||
      elapsed <= scheduleStartedAt ||
      elapsed >= duration) {
    return null;
  }

  final relativeElapsed = elapsed - scheduleStartedAt;
  if (relativeElapsed < interval) {
    return null;
  }

  final reachedIntervals =
      relativeElapsed.inMilliseconds ~/ interval.inMilliseconds;
  final milestoneElapsed =
      scheduleStartedAt +
      Duration(milliseconds: interval.inMilliseconds * reachedIntervals);
  final milestone = milestoneElapsed.inMinutes;
  if (milestone <= 0 || shownMilestones.contains(milestone)) {
    return null;
  }

  return milestone;
}
