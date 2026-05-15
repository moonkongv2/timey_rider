// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class SettingsTexts implements SettingsTextSet {
  const SettingsTexts();

  String get title => '설정';
  String get showRemainingTime => '남은 시간 보여주기';
  String get soundEnabled => '효과음 사용';
  String get keepScreenAwake => '화면 계속 켜두기';
  String get savedOnlySubtitle => 'MVP에서는 설정만 저장해요';
  String get defaultMealDuration => '기본 식사 시간';
  String get vehicleSelection => '빠방 고르기';
  String get childNameTitle => '아이 이름';
  String get childNameFieldLabel => '이름';
  String get childNameSetupTitle => '누가 냠냠 라이더를 탈까?';
  String get childNameSetupSubtitle => '아이 이름을 먼저 알려줘.';
  String get saveChildName => '이름 저장';
  String get avatarSettingsTitle => '아바타 설정';
  String get avatarDefaultState => '기본 이미지 사용 중';
  String get avatarCustomState => '직접 만든 아바타 사용 중';
  String get avatarSettingsButton => '아바타 설정하기';

  String durationSegmentLabel(int minutes) => '$minutes분';
}
