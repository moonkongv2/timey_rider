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
  String get completeDialogMessage => 'Finish this mealtime ride?';
  String get exitDialogTitle => 'Leave this ride?';
  String get exitDialogMessage =>
      "If you leave now, this mealtime ride won't be saved.";
  String get exitDialogCancelButton => 'Keep going';
  String get exitDialogConfirmButton => 'Leave';
  String get pauseButton => 'Pause';
  String get completeMealButton => 'Meal done';
  String get runningArrivalLabel => 'Until arrival';
  String get pausedTimeLabel => 'Taking a break';
  String get arrivedTimeLabel => 'Arrived';
  String get idleTimeLabel => 'Getting ready';
  String get pausedProgressMessage => 'Taking a little break';
  String get arrivedProgressMessage => 'Arrived!';
  String get idleProgressMessage => 'Getting ready';
  String get finishDriveProgressMessage => 'Heading to the finish!';
  String get finishDriveTimeLabel => 'Finishing up';

  String arrivalDialogMessage(String vehicleLabel) {
    return 'The ${vehicleLabel.toLowerCase()} passed by... did you finish your meal?';
  }

  String remainingTime(String remaining) => 'Time left $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label, $remaining remaining';
  }
}
