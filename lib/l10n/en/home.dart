// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class EnHomeTexts implements HomeTextSet {
  const EnHomeTexts();

  String get subtitle => "Ready for today's routine ride?";
  String get heroMissionTitle => "Today's Mission";
  String get heroMissionSubtitle =>
      'Your rider is waiting for a playful finish';
  String get todayVehicleTitle => "Today's vehicle";
  String get morningCourse => '15-min Ride';
  String get morningCourseSubtitle => 'A light warm-up';
  String get slowCourse => '35-min Ride';
  String get slowCourseSubtitle => 'Cruise to the finish';
  String get quickCourseTitle => 'Other activities';
  String get activityQuickStartTitle => "Today's Mission";
  String get customStartButton => 'Start Custom Ride';
  String get customSheetTitle => 'Custom time';
  String get customTimerTitle => 'Custom Timer';
  String get activitySummaryLabel => 'Activities';
  String get stickerKindSummaryLabel => 'Kinds';
  String get stickerSummaryLabel => 'Stickers';
  String get noActivityHistory => 'No activity history yet.';
  String get openStickerCollection => 'View Sticker Collection';
  String get avatarCtaSubtitle => "Put your child's face on the ride.";
  String get avatarCtaButton => 'Create';
  String get avatarCtaEditButton => 'Edit';
  String get avatarCtaCreateSemantics => 'Create avatar';
  String get avatarCtaEditSemantics => 'Edit avatar';
  String get avatarInlineDefaultState => 'Using default face';
  String get avatarInlineCustomState => 'Child face on board';
  String get activeTimerTitle => 'Activity timer in progress';
  String get activeTimerResumeButton => 'Resume';
  String get activeTimerCancelButton => 'Cancel timer';
  String get activeTimerCancelDialogTitle => 'Cancel the timer in progress?';
  String get activeTimerCancelDialogMessage =>
      'This activity timer will not be saved to history.';
  String get activeTimerNewTimerDialogTitle => 'A timer is already in progress';
  String get activeTimerNewTimerDialogMessage =>
      'Starting a new timer will cancel the current one.';
  String get activeTimerStartNewButton => 'Start new';
  String get activeTimerArrivedSubtitle => 'Activity time is done';

  String recentCustomMinutes(int minutes) => 'Recent $minutes min';
  String minuteLabel(int minutes) => '$minutes min';
  String activeTimerSubtitle(String remainingTime) => '$remainingTime left';
  String normalCourse(int minutes) => '$minutes-min Regular Ride';
  String alternateCourse(int minutes) => '$minutes-min Ride';
  String alternateCourseSubtitle(int minutes) {
    return switch (minutes) {
      15 => 'A light warm-up',
      25 => 'A steady everyday pace',
      35 => 'Cruise to the finish',
      _ => 'Ride for $minutes min',
    };
  }

  String progressTitle(String childName) => "$childName's activity history";
  String activityCount(int count) => '$count';
  String stickerKindCount(int count) => '$count';
  String stickerCount(int count) => '$count';
  String recentActivitySummary(
    String actualDuration,
    ActivityCompletionStatus completionStatus,
  ) {
    final status =
        completionStatus == ActivityCompletionStatus.needsMoreTime ||
            completionStatus == ActivityCompletionStatus.canceled
        ? 'incomplete'
        : 'complete';
    return 'Recent activity $actualDuration · $status';
  }
}
