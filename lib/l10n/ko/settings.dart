// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class SettingsTexts implements SettingsTextSet {
  const SettingsTexts();

  String get title => '설정';
  String get showRemainingTime => '남은 시간 보여주기';
  String get soundEnabled => '효과음 사용';
  String get motivationVideoEnabled => '동기부여 영상 사용';
  String get motivationVideoCustomInterval => '영상 간격 직접 설정';
  String get motivationVideoInterval => '동기부여 영상 간격';
  String get motivationVideoHelpTitle => '동기부여 영상 안내';
  String get motivationVideoHelpSummary => '동기부여 영상은 타이머 중간에 나오는 짧은 응원이에요.';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    '동기부여 영상은 타이머 중간에 아이의 흐름을 돕기 위해 나오는 짧은 응원 클립이에요.',
    '스티커나 결과를 결정하지 않아요.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    '짧은 타이머에서는 영상이 겹치지 않도록 일부 구간을 건너뛸 수 있어요.',
    '긴 타이머나 영상 간격 직접 설정을 쓰면 시간 간격 기준으로 나올 수 있어요.',
    '직접 설정 간격은 3분, 5분, 10분 중에서 고를 수 있어요.',
    '효과음 설정과 영상 사용 설정은 따로 동작할 수 있어요.',
    '영상이 너무 자주 겹치지 않도록 앱이 표시 간격을 조절해요.',
  ];
  String get keepScreenAwake => '화면 계속 켜두기';
  String get savedOnlySubtitle => '타이머 진행 중 나오는 소리를 켜고 꺼요';
  String get keepScreenAwakeSubtitle => '타이머가 실행 중일 때 적용돼요';
  String get markerModeTitle => '코스 마커';
  String get markerModeOff => '사용 안 함';
  String get markerModeManual => '직접 선택';
  String get markerModeRandom => '자동 선택';
  String get markerModeActivityDefault => '활동에 맞게';
  String get markerModeDescription =>
      '직접 선택한 마커만 활동 기록에 남아요. 자동 선택은 도로에만 표시돼요.';
  String get defaultTimerDuration => '기본 타이머 시간';
  String get vehicleSelection => '빠방 고르기';
  String get childNameTitle => '아이 이름';
  String get childNameFieldLabel => '이름';
  String get childNameSetupTitle => '누가 Ticky Rider를 탈까?';
  String get childNameSetupSubtitle => '아이 이름을 먼저 알려줘.';
  String get saveChildName => '이름 저장';
  String get childNameRequiredMessage => '아이 이름을 입력해 주세요.';
  String get childNameSavedMessage => '이름을 저장했어요.';
  String get avatarSettingsTitle => '아바타 설정';
  String get avatarDefaultState => '기본 이미지 사용 중';
  String get avatarCustomState => '직접 만든 아바타 사용 중';
  String get avatarSettingsButton => '아바타 설정하기';

  String durationSegmentLabel(int minutes) => '$minutes분';
  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes분';
}
