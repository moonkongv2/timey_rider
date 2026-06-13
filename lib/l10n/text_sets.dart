import '../models/activity_completion_status.dart';

abstract interface class CommonTextSet {
  String get appTitle;
  String get apply;
  String get cancel;
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
  String get heroMissionTitle;
  String get heroMissionSubtitle;
  String get todayVehicleTitle;
  String get morningCourse;
  String get morningCourseSubtitle;
  String get slowCourse;
  String get slowCourseSubtitle;
  String get quickCourseTitle;
  String get activityQuickStartTitle;
  String get customStartButton;
  String get customSheetTitle;
  String get customTimerTitle;
  String get activitySummaryLabel;
  String get stickerKindSummaryLabel;
  String get stickerSummaryLabel;
  String get noActivityHistory;
  String get openStickerCollection;
  String get avatarCtaSubtitle;
  String get avatarCtaButton;
  String get avatarCtaEditButton;
  String get avatarCtaCreateSemantics;
  String get avatarCtaEditSemantics;
  String get avatarInlineDefaultState;
  String get avatarInlineCustomState;
  String get activeTimerTitle;
  String get activeTimerResumeButton;
  String get activeTimerCancelButton;
  String get activeTimerCancelDialogTitle;
  String get activeTimerCancelDialogMessage;
  String get activeTimerNewTimerDialogTitle;
  String get activeTimerNewTimerDialogMessage;
  String get activeTimerStartNewButton;
  String get activeTimerArrivedSubtitle;

  String recentCustomMinutes(int minutes);
  String minuteLabel(int minutes);
  String activeTimerSubtitle(String remainingTime);
  String normalCourse(int minutes);
  String alternateCourse(int minutes);
  String alternateCourseSubtitle(int minutes);
  String progressTitle(String childName);
  String activityCount(int count);
  String stickerKindCount(int count);
  String stickerCount(int count);
  String recentActivitySummary(
    String actualDuration,
    ActivityCompletionStatus completionStatus,
  );
}

abstract interface class AvatarSetupTextSet {
  String get title;
  String get intro;
  String get selectedVehicleTitle;
  String get currentAvatarModeTitle;
  String get defaultImageMode;
  String get customAvatarMode;
  String get copyPromptMessage;
  String get avatarSaveFailureMessage;
  String get avatarSavedMessage;
  String get defaultImageSavedMessage;
  String get missingAvatarWarning;
  String get vehicleSelectionTitle;
  String get vehicleSelectionSubtitle;
  String get compositePreviewTitle;
  String get compositePreviewSubtitle;
  String get defaultPreviewTitle;
  String get useDefaultImageButton;
  String get adjustmentTitle;
  String get faceSizeLabel;
  String get horizontalPositionLabel;
  String get verticalPositionLabel;
  String get rotationLabel;
  String get resetPositionButton;
  String get adjustmentUnavailable;
  String get confirmAvatarButton;
  String get guideTitle;
  List<String> get guideItems;
  String get promptCopyTitle;
  String get copyPromptButton;
  String get uploadTitle;
  String get uploadInstructions;
  String get uploadingButton;
  String get reuploadButton;
  String get uploadButton;
  String get selectedImageFallback;
  String get privacyNote;
}

abstract interface class MealHistoryTextSet {
  String get title;
  String get emptyTitle;
  String get emptyBody;
  String get helpTitle;
  List<String> get helpBulletItems;
  String get targetTimeLabel;
  String get actualTimeLabel;
  String get overrunTimeLabel;
  String get rewardLabel;
  String get noRewardLabel;
  String get selectedIngredientLabel;
  String get deleteRecordLabel;
  String get deleteRecordDialogTitle;
  String get deleteRecordDialogBody;
  String get deleteRecordConfirmLabel;
  String get deleteRecordSuccessMessage;

  String completedStatus(ActivityCompletionStatus completionStatus);
  String dateLabel(DateTime dateTime);
  String overrunTime(String duration);
}

abstract interface class MealIngredientTextSet {
  String get title;
  String get subtitle;
  String get helpLinkLabel;
  String get helpTitle;
  List<String> get helpBodyParagraphs;
  List<String> get helpBulletItems;
  String get randomStartButton;
  String get selectedStartButton;

  String selectedCount(int selectedCount, int maxCount);
}

abstract interface class SettingsTextSet {
  String get title;
  String get showRemainingTime;
  String get soundEnabled;
  String get motivationVideoEnabled;
  String get motivationVideoCustomInterval;
  String get motivationVideoInterval;
  String get motivationVideoHelpTitle;
  String get motivationVideoHelpSummary;
  List<String> get motivationVideoHelpBodyParagraphs;
  List<String> get motivationVideoHelpBulletItems;
  String get keepScreenAwake;
  String get savedOnlySubtitle;
  String get keepScreenAwakeSubtitle;
  String get markerModeTitle;
  String get markerModeOff;
  String get markerModeManual;
  String get markerModeRandom;
  String get markerModeActivityDefault;
  String get markerModeDescription;
  String get defaultMealDuration;
  String get vehicleSelection;
  String get childNameTitle;
  String get childNameFieldLabel;
  String get childNameSetupTitle;
  String get childNameSetupSubtitle;
  String get saveChildName;
  String get childNameRequiredMessage;
  String get childNameSavedMessage;
  String get avatarSettingsTitle;
  String get avatarDefaultState;
  String get avatarCustomState;
  String get avatarSettingsButton;

  String durationSegmentLabel(int minutes);
  String motivationVideoIntervalSegmentLabel(int minutes);
}

abstract interface class UserGuideTextSet {
  String get title;
  String get subtitle;
  String get introTitle;
  String get introBody;
  String get basicFlowTitle;
  String get ingredientsTitle;
  String get motivationTitle;
  String get resultRewardsTitle;
  String get historyTitle;
  String get guardianTipsTitle;
  String get whatIsYamyamTitle;
  List<String> get whatIsYamyamItems;
  String get startCourseTitle;
  List<String> get startCourseItems;
  String get roadIngredientsTitle;
  List<String> get roadIngredientsItems;
  List<String> get motivationItems;
  String get completionTitle;
  List<String> get completionItems;
  String get historyRewardsTitle;
  List<String> get historyRewardsItems;
  String get exitResumeTitle;
  List<String> get exitResumeItems;
  List<String> get guardianTipsItems;
}

abstract interface class TimerTextSet {
  String get missionTitle;
  String get progressJustStarted;
  String get progressGoingWell;
  String get progressPastHalfway;
  String get progressAlmostThere;
  String get progressArrived;
  String completeDialogTitle(String activityLabel);
  String completeDialogMessage(String activityLabel);
  String get exitDialogTitle;
  String get exitDialogMessage;
  String get exitDialogCancelButton;
  String get exitDialogConfirmButton;
  String get pauseButton;
  String completeActivityButton(String activityId);
  String get remainingTimeLabel;
  String get pausedTimeLabel;
  String get arrivedTimeLabel;
  String get idleTimeLabel;
  String get pausedProgressMessage;
  String get arrivedProgressMessage;
  String get idleProgressMessage;
  String get finishDriveProgressMessage;
  String get finishDriveTimeLabel;

  String arrivalDialogMessage(String vehicleLabel, String activityLabel);
  String remainingTime(String remaining);
  String remainingTimeSemanticLabel(String label, String remaining);
}

abstract interface class ResultTextSet {
  String get rewardLoading;
  String get recordSaved;

  String title(ActivityCompletionStatus status);
  String primaryMessage(ActivityCompletionStatus status, {String? vehicleId});
  String secondaryMessage(ActivityCompletionStatus status);
  String get parentTipLabel;
  String parentTipTitle(ActivityCompletionStatus status);
  String parentTipSubtitle(ActivityCompletionStatus status);
  String parentTipSemanticLabel(ActivityCompletionStatus status);
  String helpButtonLabel(ActivityCompletionStatus status);
  String helpTitle(ActivityCompletionStatus status);
  List<String> helpBodyParagraphs(ActivityCompletionStatus status);
  List<String> helpBulletItems(ActivityCompletionStatus status);
  String resultHelpMeaningTitle(ActivityCompletionStatus status);
  List<String> resultHelpMeaningItems(ActivityCompletionStatus status);
  String resultHelpSayTitle(ActivityCompletionStatus status);
  List<String> resultHelpSayItems(ActivityCompletionStatus status);
  String resultHelpAvoidTitle(ActivityCompletionStatus status);
  List<String> resultHelpAvoidItems(ActivityCompletionStatus status);
  String resultHelpNextCourseTitle(ActivityCompletionStatus status);
  List<String> resultHelpNextCourseItems(ActivityCompletionStatus status);
}

abstract interface class RewardTextSet {
  String get collectionTitle;
  String get lockedSticker;
  String get lockedStatus;
  String get uncollectedSemanticLabel;
  String get rewardGoalTitle;
  String get createRewardGoal;
  String get rewardGoalEmptyTitle;
  String get rewardGoalEmptyBody;
  String get rewardGoalRewardFieldLabel;
  String get rewardGoalRequiredStickerCountLabel;
  String get rewardGoalSaveButton;
  String get rewardGoalReadyMessage;
  String get rewardGoalGivenButton;
  String get rewardGoalCreatedMessage;
  String get rewardGoalUpdatedMessage;
  String get rewardGoalCanceledMessage;
  String get rewardGoalRedeemedMessage;
  String get rewardGoalUsedMessage;
  String get rewardGoalProgressTitle;
  String get rewardGoalEmptySlotSemanticLabel;
  String get openRewardGoal;
  String get rewardGoalPromiseTitle;
  String get activeRewardGoalsTitle;
  String get earnedRewardGoalsTitle;
  String get usedRewardGoalsTitle;
  String get maxActiveRewardGoalsMessage;
  String get editRewardGoal;
  String get cancelRewardGoal;
  String get rewardGoalHistoryTitle;
  String get rewardGoalNoHistory;
  String get confirmRedeemRewardGoalTitle;
  String get confirmRedeemRewardGoalMessage;
  String get confirmCancelRewardGoalTitle;
  String get confirmCancelRewardGoalMessage;
  String get keepRewardGoal;
  String get confirmRewardGiven;
  String get confirmCancelGoal;
  String get confirmUseRewardGoalTitle;
  String get confirmUseRewardGoalMessage;
  String get confirmUseRewardGoal;

  String stickerCount(int count);
  String rewardGoalProgress(int filledCount, int requiredCount);
  String rewardGoalRemaining(int remainingCount);
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName);
  String rewardGoalReadyAt(String dateLabel);
  String rewardGoalRedeemedAt(String dateLabel);
  String name(String rewardId);
}
