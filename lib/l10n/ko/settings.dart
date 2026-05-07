class SettingsTexts {
  const SettingsTexts();

  String get title => '설정';
  String get showRemainingTime => '남은 시간 보여주기';
  String get soundEnabled => '효과음 사용';
  String get keepScreenAwake => '화면 계속 켜두기';
  String get savedOnlySubtitle => 'MVP에서는 설정만 저장해요';
  String get defaultMealDuration => '기본 식사 시간';

  String durationSegmentLabel(int minutes) => '$minutes분';
}
