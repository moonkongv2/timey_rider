// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnHomeTexts implements HomeTextSet {
  const EnHomeTexts();

  String get subtitle => "Ready for today's mealtime ride?";
  String get morningCourse => '15-min Morning Ride';
  String get normalCourse => '25-min Regular Ride';
  String get slowCourse => '35-min Easy Ride';
  String get customStartButton => 'Start Custom Ride';
  String get mealSummaryLabel => 'Meals';
  String get stickerKindSummaryLabel => 'Kinds';
  String get stickerSummaryLabel => 'Stickers';
  String get noMealHistory => 'No meal records yet.';
  String get openStickerCollection => 'View Sticker Collection';

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
