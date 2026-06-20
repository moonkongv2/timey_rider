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
  String get vehiclePickerTitle => 'Choose vehicle';
  String get vehicleChangeButton => 'Change';
  String get morningCourse => '15-min Ride';
  String get morningCourseSubtitle => 'A light warm-up';
  String get slowCourse => '35-min Ride';
  String get slowCourseSubtitle => 'Cruise to the finish';
  String get quickCourseTitle => 'Other activities';
  String get activityQuickStartTitle => "Today's Mission";
  String get customStartButton => 'Start Custom Ride';
  String get customSheetTitle => 'Custom time';
  String get customTimerTitle => 'Other';
  String get timerBuilderButton => 'Create Timer';
  String get timerBuilderSubtitle =>
      'Choose a mission, markers, and time before starting.';
  String get timerBuilderSheetTitle => 'Create Timer';
  String get timerBuilderActivityStepTitle => '1. Mission';
  String get timerBuilderMarkerStepTitle => '2. Markers';
  String get timerBuilderAutomaticMarkerOption => 'Auto';
  String get timerBuilderManualMarkerOption => 'Choose';
  String get timerBuilderRecentPresetTitle => 'Recent setting';
  String get timerBuilderRecentPresetApplyButton => 'Apply';
  String get timerBuilderSavedPresetTitle => 'Saved timers';
  String get timerBuilderSavePresetButton => 'Save';
  String get timerBuilderSavedPresetMessage => 'Saved.';
  String get timerBuilderSavedPresetFullMessage =>
      'Saved. Older timers are cleaned up automatically.';
  String get timerBuilderSavedPresetLimitHint =>
      'New saves replace the oldest timer.';
  String get timerBuilderDeletePresetTooltip => 'Delete';
  String get timerBuilderFavoritePresetTooltip => 'Show on Home';
  String get timerBuilderUnfavoritePresetTooltip => 'Hide from Home';
  String get timerBuilderFavoritePresetLimitMessage =>
      'Up to 3 timers can be shown on Home.';
  String get timerBuilderCustomNameDialogTitle => 'Timer name';
  String get timerBuilderCustomNameFieldLabel => 'Name';
  String get timerBuilderUseOtherNameButton => 'Save as Other';
  String get timerBuilderTimeStepTitle => '3. Time';
  String get timerBuilderStartButton => 'Start';
  String get timerBuilderSelectedMarkerEmpty => 'Choose 1-5 markers.';
  String get activitySummaryLabel => 'Missions';
  String get stickerKindSummaryLabel => 'Vehicle kinds';
  String get stickerSummaryLabel => 'Vehicle stickers';
  String get noActivityHistory => 'No activity history yet.';
  String get openStickerCollection => 'View Vehicle Sticker Collection';
  String get avatarCtaSubtitle => "Put your child's face on the ride.";
  String get avatarCtaButton => 'Create';
  String get avatarCtaEditButton => 'Edit';
  String get avatarCtaCreateSemantics => 'Create rider image';
  String get avatarCtaEditSemantics => 'Edit rider image';
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
  String timerBuilderSavedPresetCount(int count, int maxCount) {
    return '$count/$maxCount';
  }

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
    final status = switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Completed',
      ActivityCompletionStatus.timeEnded => 'Time ended',
      ActivityCompletionStatus.needsMoreTime => 'Needs more time',
      ActivityCompletionStatus.canceled => 'Canceled',
    };
    return 'Recent activity $actualDuration · $status';
  }
}
