// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnSettingsTexts implements SettingsTextSet {
  const EnSettingsTexts();

  String get title => 'Settings';
  String get showRemainingTime => 'Show remaining time';
  String get soundEnabled => 'Sound effects';
  String get motivationVideoEnabled => 'Motivation videos';
  String get motivationVideoCustomInterval => 'Use custom video interval';
  String get motivationVideoInterval => 'Motivation video interval';
  String get motivationVideoHelpTitle => 'Motivation video guide';
  String get motivationVideoHelpSummary =>
      'Motivation videos are short encouragement clips during the timer.';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    'Motivation videos are short encouragement clips that can appear during the timer.',
    'They do not decide stickers or results.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    'Short timers may skip some milestones so clips do not overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'Custom intervals can be set to 3, 5, or 10 minutes.',
    'Sound effects and video display settings can behave separately.',
    'The app spaces videos out so they do not overlap too frequently.',
  ];
  String get keepScreenAwake => 'Keep screen awake';
  String get savedOnlySubtitle => 'Turns sounds during the timer on or off.';
  String get keepScreenAwakeSubtitle => 'Applies while the timer is running.';
  String get markerModeTitle => 'Course markers';
  String get markerModeOff => 'Off';
  String get markerModeManual => 'Choose';
  String get markerModeActivityDefault => 'Auto';
  String get markerModeDescription =>
      'Auto previews and uses picture markers that fit the activity. Only manually chosen picture markers are saved to activity records.';
  String get vehicleSelection => 'Choose vehicle';
  String get childNameTitle => "Child's name";
  String get childNameFieldLabel => 'Name';
  String get childNameSetupTitle => 'Who is riding today?';
  String get childNameSetupSubtitle => "Enter your child's name first.";
  String get saveChildName => 'Save name';
  String get childNameRequiredMessage => "Enter your child's name.";
  String get childNameSavedMessage => 'Name saved.';
  String get avatarSettingsTitle => 'Rider image settings';
  String get avatarDefaultState => 'Using default image';
  String get avatarCustomState => 'Using custom rider';
  String get avatarSettingsButton => 'Open rider image settings';
  String get vehiclePackSettingsTitle => 'Vehicle pack';
  String get vehiclePackLockedState => 'Locked vehicles available';
  String get vehiclePackUnlockedState => 'Vehicle pack unlocked';
  String get vehiclePackSettingsDescription =>
      'The vehicle pack unlocks all locked vehicles. Purchase and restore options open after a parent check.';
  String get vehiclePackManageButton => 'View vehicle pack';
  String get vehiclePackRestoreButton => 'Restore purchase';
  String get helpAndSupportSectionTitle => 'Help & Support';
  String get userGuideSettingsItemTitle => 'User Guide';
  String get restorePurchaseSettingsItemTitle => 'Restore Purchase';
  String get contactSupportSettingsItemTitle => 'Contact Support';
  String get aboutSectionTitle => 'About';
  String get privacyPolicySettingsItemTitle => 'Privacy Policy';
  String get appVersionSettingsItemTitle => 'App Version';
  String get externalLinkOpenErrorMessage => 'Could not open the link.';

  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes min';
}
