// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnTimerTexts implements TimerTextSet {
  const EnTimerTexts();

  String get courseTitle => "Today's Yamyam Ride";
  String get completeDialogTitle => 'Did you finish your meal?';
  String get arrivalDialogMessage =>
      'The rider passed by... did you finish your meal?';
  String get completeDialogMessage => 'Finish this mealtime ride?';
  String get pauseButton => 'Pause';
  String get completeMealButton => 'Meal done';

  String remainingTime(String remaining) => 'Time left $remaining';
}
