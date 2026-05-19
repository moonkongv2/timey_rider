// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnHomeTexts implements HomeTextSet {
  const EnHomeTexts();

  String get subtitle => "Ready for today's mealtime ride?";
  String get heroMissionTitle => "Today's Yamyam Mission";
  String get heroMissionSubtitle => 'Your rider is waiting for a tasty finish';
  String get todayVehicleTitle => "Today's vehicle";
  String get morningCourse => '15-min Morning Ride';
  String get morningCourseSubtitle => 'A light warm-up';
  String get normalCourse => '25-min Regular Ride';
  String get slowCourse => '35-min Easy Ride';
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

  String recentCustomMinutes(int minutes) => 'Recent $minutes min';
  String minuteLabel(int minutes) => '$minutes min';
  String progressTitle(String childName) => "$childName's meal records";
  String mealCount(int count) => '$count';
  String stickerKindCount(int count) => '$count';
  String stickerCount(int count) => '$count';
  String recentMealSummary(String actualDuration, bool completedBeforeArrival) {
    final status = completedBeforeArrival
        ? 'finished before arrival'
        : 'finished after arrival';
    return 'Recent meal $actualDuration · $status';
  }
}
