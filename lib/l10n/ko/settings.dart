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
  String get motivationVideoHelpSummary =>
      '동기부여 영상은 보상 판정과 관계없는 식사 중간의 짧은 응원이에요.';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    '동기부여 영상은 식사 중간에 아이의 흐름을 돕기 위해 나오는 짧은 응원이에요.',
    '성공, 미완료, 스티커 판정과는 관계가 없어요.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    '30분 이하 코스는 기본적으로 10%, 20%처럼 진행률 10% 단위 구간에 맞춰 나와요.',
    '아주 짧은 직접 설정 코스에서는 영상이 겹치지 않도록 일부 구간을 건너뛸 수 있어요.',
    '30분을 초과하는 긴 코스나 영상 간격 직접 설정을 쓰면 시간 간격 기준으로 나올 수 있어요.',
    '직접 설정 간격은 3분, 5분, 10분 중에서 고를 수 있어요.',
    '효과음 설정과 영상 사용 설정은 따로 동작할 수 있어요.',
    '영상이 너무 자주 겹치지 않도록 앱이 표시 간격을 조절해요.',
  ];
  String get keepScreenAwake => '화면 계속 켜두기';
  String get savedOnlySubtitle => '타이머 진행 중 나오는 소리를 켜고 꺼요';
  String get keepScreenAwakeSubtitle => '식사 타이머 중에 적용돼요';
  String get courseIngredientModeTitle => '도로 위 식재료';
  String get courseIngredientModeOff => '사용 안 함';
  String get courseIngredientModeManual => '직접 선택';
  String get courseIngredientModeRandom => '자동 선택';
  String get courseIngredientModeDescription =>
      '직접 선택한 식재료만 식사 기록에 남아요. 자동 선택은 도로에만 표시돼요.';
  String get defaultMealDuration => '기본 식사 시간';
  String get vehicleSelection => '빠방 고르기';
  String get childNameTitle => '아이 이름';
  String get childNameFieldLabel => '이름';
  String get childNameSetupTitle => '누가 냠냠 라이더를 탈까?';
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
