// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnTimerTexts implements TimerTextSet {
  const EnTimerTexts();

  String get courseTitle => "Today's Yamyam Ride";
  String get progressJustStarted => "We're off!";
  String get progressGoingWell => "You're doing great!";
  String get progressPastHalfway => "You've come so far!";
  String get progressAlmostThere => 'Almost there!';
  String get progressArrived => 'You arrived!';
  String get completeDialogTitle => 'Did you finish your meal?';
  String get arrivalDialogMessage =>
      'The rider passed by... did you finish your meal?';
  String get completeDialogMessage => 'Finish this mealtime ride?';
  String get pauseButton => 'Pause';
  String get completeMealButton => 'Meal done';
  String get runningArrivalLabel => 'Until arrival';
  String get pausedTimeLabel => 'Taking a break';
  String get arrivedTimeLabel => 'Arrived';
  String get idleTimeLabel => 'Getting ready';
  String get pausedProgressMessage => 'Taking a little break';
  String get arrivedProgressMessage => 'Arrived!';
  String get idleProgressMessage => 'Getting ready';

  String remainingTime(String remaining) => 'Time left $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label, $remaining remaining';
  }
}
