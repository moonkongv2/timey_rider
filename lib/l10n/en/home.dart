// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/meal_completion_status.dart';

class EnHomeTexts implements HomeTextSet {
  const EnHomeTexts();

  String get subtitle => "Ready for today's mealtime ride?";
  String get heroMissionTitle => "Today's Yamyam Mission";
  String get heroMissionSubtitle => 'Your rider is waiting for a tasty finish';
  String get todayVehicleTitle => "Today's vehicle";
  String get morningCourse => '15-min Ride';
  String get morningCourseSubtitle => 'A light warm-up';
  String get slowCourse => '35-min Ride';
  String get slowCourseSubtitle => 'Cruise to the finish';
  String get quickCourseTitle => 'Other rides';
  String get customStartButton => 'Start Custom Ride';
  String get customSheetTitle => 'Custom time';
  String get mealSummaryLabel => 'Meals';
  String get stickerKindSummaryLabel => 'Kinds';
  String get stickerSummaryLabel => 'Stickers';
  String get noMealHistory => 'No meal records yet.';
  String get openStickerCollection => 'View Sticker Collection';
  String get avatarCtaSubtitle => "Put your child's face on the ride.";
  String get avatarCtaButton => 'Create';
  String get avatarCtaEditButton => 'Edit';
  String get avatarCtaCreateSemantics => 'Create avatar';
  String get avatarCtaEditSemantics => 'Edit avatar';
  String get avatarInlineDefaultState => 'Using default face';
  String get avatarInlineCustomState => 'Child face on board';
  String get activeTimerTitle => 'Meal timer in progress';
  String get activeTimerResumeButton => 'Resume';
  String get activeTimerCancelButton => 'Cancel timer';
  String get activeTimerCancelDialogTitle => 'Cancel the timer in progress?';
  String get activeTimerCancelDialogMessage =>
      'This meal timer will not be saved to meal records.';
  String get activeTimerNewTimerDialogTitle => 'A timer is already in progress';
  String get activeTimerNewTimerDialogMessage =>
      'Starting a new timer will cancel the current one.';
  String get activeTimerStartNewButton => 'Start new';

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

  String progressTitle(String childName) => "$childName's meal records";
  String mealCount(int count) => '$count';
  String stickerKindCount(int count) => '$count';
  String stickerCount(int count) => '$count';
  String recentMealSummary(
    String actualDuration,
    MealCompletionStatus completionStatus,
  ) {
    final status = completionStatus == MealCompletionStatus.notCompleted
        ? 'incomplete'
        : 'complete';
    return 'Recent meal $actualDuration · $status';
  }
}
