// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnSettingsTexts implements SettingsTextSet {
  const EnSettingsTexts();

  String get title => 'Settings';
  String get showRemainingTime => 'Show remaining time';
  String get soundEnabled => 'Sound effects';
  String get keepScreenAwake => 'Keep screen awake';
  String get savedOnlySubtitle => 'This setting is saved but not active yet.';
  String get defaultMealDuration => 'Default meal time';

  String durationSegmentLabel(int minutes) => '$minutes min';
}
