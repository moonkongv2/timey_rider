// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnSettingsTexts implements SettingsTextSet {
  const EnSettingsTexts();

  String get title => 'Settings';
  String get showRemainingTime => 'Show remaining time';
  String get soundEnabled => 'Sound effects';
  String get keepScreenAwake => 'Keep screen awake';
  String get savedOnlySubtitle => 'This setting is saved but not active yet.';
  String get keepScreenAwakeSubtitle =>
      'Applies while the meal timer is running.';
  String get defaultMealDuration => 'Default meal time';
  String get vehicleSelection => 'Choose vehicle';
  String get childNameTitle => "Child's name";
  String get childNameFieldLabel => 'Name';
  String get childNameSetupTitle => 'Who is riding today?';
  String get childNameSetupSubtitle => "Enter your child's name first.";
  String get saveChildName => 'Save name';
  String get childNameRequiredMessage => "Enter your child's name.";
  String get childNameSavedMessage => 'Name saved.';
  String get avatarSettingsTitle => 'Avatar settings';
  String get avatarDefaultState => 'Using default image';
  String get avatarCustomState => 'Using custom avatar';
  String get avatarSettingsButton => 'Open avatar settings';

  String durationSegmentLabel(int minutes) => '$minutes min';
}
