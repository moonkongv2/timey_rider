abstract interface class CommonTextSet {
  String get appTitle;
  String get defaultChildName;
  String get complete;
  String get home;
  String get notYet;
  String get restartRide;
  String get settings;
  String get start;
}

abstract interface class HomeTextSet {
  String get subtitle;
  String get morningCourse;
  String get normalCourse;
  String get slowCourse;
  String get customStartButton;
  String get mealSummaryLabel;
  String get stickerKindSummaryLabel;
  String get stickerSummaryLabel;
  String get noMealHistory;
  String get openStickerCollection;

  String customSettingMinutes(int minutes);
  String minuteLabel(int minutes);
  String progressTitle(String childName);
  String mealCount(int count);
  String stickerKindCount(int count);
  String stickerCount(int count);
  String recentMealSummary(String actualDuration, bool completedBeforeArrival);
}

abstract interface class SettingsTextSet {
  String get title;
  String get showRemainingTime;
  String get soundEnabled;
  String get keepScreenAwake;
  String get savedOnlySubtitle;
  String get defaultMealDuration;
  String get vehicleSelection;

  String durationSegmentLabel(int minutes);
}

abstract interface class TimerTextSet {
  String get courseTitle;
  String get completeDialogTitle;
  String get arrivalDialogMessage;
  String get completeDialogMessage;
  String get pauseButton;
  String get completeMealButton;

  String remainingTime(String remaining);
}

abstract interface class ResultTextSet {
  String get rewardLoading;
  String get recordSaved;

  String title(bool mealCompleted);
  String primaryMessage(bool mealCompleted);
  String secondaryMessage(bool mealCompleted);
}

abstract interface class RewardTextSet {
  String get collectionTitle;
  String get lockedSticker;
  String get lockedStatus;
  String get uncollectedSemanticLabel;

  String stickerCount(int count);
  String name(String rewardId);
}
