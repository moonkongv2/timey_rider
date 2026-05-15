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
  String get normalCourseSubtitle => 'A steady mealtime mission';
  String get slowCourse => '35-min Easy Ride';
  String get slowCourseSubtitle => 'Cruise to the finish';
  String get recommendedBadge => 'Recommended';
  String get customStartButton => 'Start Custom Ride';
  String get mealSummaryLabel => 'Meals';
  String get stickerKindSummaryLabel => 'Kinds';
  String get stickerSummaryLabel => 'Stickers';
  String get noMealHistory => 'No meal records yet.';
  String get openStickerCollection => 'View Sticker Collection';
  String get avatarCtaTitle => "Child's avatar";
  String get avatarCtaSubtitle =>
      'Put a cute rider face made from a child photo on the vehicle.';
  String get avatarCtaButton => 'Create avatar';

  String customSettingMinutes(int minutes) => 'Custom: $minutes min';
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
