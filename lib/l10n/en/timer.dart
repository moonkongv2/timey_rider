// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnTimerTexts implements TimerTextSet {
  const EnTimerTexts();

  String get missionTitle => "Today's Mission";
  String get progressJustStarted => "We're off!";
  String get progressGoingWell => "You're doing great!";
  String get progressPastHalfway => "You've come so far!";
  String get progressAlmostThere => 'Almost there!';
  String get progressArrived => 'You arrived!';
  String completeDialogTitle(String activityLabel) =>
      'Did you finish $activityLabel?';
  String completeDialogMessage(String activityLabel) =>
      'Finish this $activityLabel mission?';
  String get exitDialogTitle => 'Leave this ride?';
  String get exitDialogMessage =>
      "If you leave now, this mission won't be saved.";
  String get exitDialogCancelButton => 'Keep going';
  String get exitDialogConfirmButton => 'Leave';
  String get pauseButton => 'Pause';
  String completeActivityButton(String activityId) {
    return switch (activityId) {
      'brushing' => 'Done Brushing',
      'reading' => 'Done Reading',
      'cleanup' => 'Done Cleaning',
      'play' => 'Play Done',
      _ => 'Mission Done',
    };
  }

  String get remainingTimeLabel => 'Time left';
  String get pausedTimeLabel => 'Taking a break';
  String get arrivedTimeLabel => 'Arrived';
  String get idleTimeLabel => 'Getting ready';
  String get pausedProgressMessage => 'Taking a little break';
  String get arrivedProgressMessage => 'Arrived!';
  String get idleProgressMessage => 'Getting ready';
  String get finishDriveProgressMessage => 'Heading to the finish!';
  String get finishDriveTimeLabel => 'Finishing up';
  String get previewReady => 'Ready... 🚦';
  String get previewGo => 'Go! 🌟';

  String arrivalDialogMessage(String vehicleLabel, String activityLabel) {
    return 'The ${vehicleLabel.toLowerCase()} arrived. Did you finish $activityLabel?';
  }

  String remainingTime(String remaining) => 'Time left $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label, $remaining remaining';
  }
}
