// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class UserGuideTexts implements UserGuideTextSet {
  const UserGuideTexts();

  String get title => '사용 안내';
  String get subtitle => '활동 미션, 응원 영상, 스티커 규칙을 확인해요.';
  String get introTitle => '보호자 가이드';
  String get introBody =>
      'Timey Rider를 시작하기 전에 활동 미션 흐름과 앱 규칙을 한눈에 확인할 수 있어요. 부모님뿐 아니라 아이의 루틴을 함께 돕는 보호자도 참고할 수 있어요.';
  String get basicFlowTitle => startMissionTitle;
  String get markersTitle => courseMarkersTitle;
  String get motivationTitle => '동기부여 영상';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => '보호자 사용 팁';

  String get whatIsTimeyRiderTitle => 'Timey Rider는 어떤 앱인가요?';
  List<String> get whatIsTimeyRiderItems => const [
    '양치, 책 읽기, 정리, 놀이 같은 활동을 작은 라이딩 미션으로 바꾸는 타이머 앱이에요.',
    '아이가 차량을 고르고, 정해진 시간 동안 코스를 따라가며 루틴을 경험해요.',
    '마지막에는 활동 방식에 따라 완료 확인, 시간 종료, 보호자 확인으로 기록돼요.',
  ];

  String get startMissionTitle => '활동 미션 시작하기';
  List<String> get startMissionItems => const [
    '아이 이름을 설정한 뒤 홈에서 탈 차량을 고를 수 있어요.',
    '홈에서 타이머 만들기를 눌러 미션 종류, 마커, 시간을 차례로 골라요.',
    '기타 미션도 같은 흐름에서 원하는 시간을 고른 뒤 시작해요.',
    '타이머 중 일시정지는 실패가 아니며, 필요하면 이어갈 수 있어요.',
  ];

  String get courseMarkersTitle => '코스 마커';
  List<String> get courseMarkersItems => const [
    '코스 마커는 활동 중 도로 위에 나타나는 작은 목표 표시예요.',
    '사용 안 함: 도로 위에 마커를 표시하지 않아요.',
    '자동: 선택한 활동에 어울리는 마커를 앱이 알아서 사용해요.',
    '직접 선택: 시작 전 최대 5개까지 골라요. 직접 고른 마커는 활동 기록에 남아요.',
    '마커는 완료 여부나 스티커 판정을 직접 결정하지 않아요.',
  ];

  List<String> get motivationItems => const [
    '타이머 중간에 나오는 짧은 응원 클립이에요.',
    '스티커나 결과를 결정하지 않아요.',
    '짧은 타이머에서는 영상이 겹치지 않도록 일부 구간을 건너뛸 수 있어요.',
    '긴 타이머나 직접 고른 시간 설정을 쓰면 시간 간격 기준으로 나올 수 있어요.',
    '영상 간격은 3분, 5분, 10분 중에서 선택할 수 있어요.',
    '소리 설정이 꺼져 있으면 영상만 나오거나 음성이 재생되지 않을 수 있어요.',
  ];

  String get completionTitle => '완료와 스티커';
  List<String> get completionItems => const [
    '활동을 마쳤다고 확인하면 완료로 기록돼요.',
    '놀이처럼 시간이 끝나면 자동으로 마무리되는 활동도 있어요.',
    '완료한 미션은 랜덤 성공 스티커를 받을 수 있어요.',
    '조금 더 필요하거나 취소된 기록은 스티커 없이 다음 조절에 참고해요.',
    '아이 화면은 강한 실패 표현보다 다음 도전을 떠올릴 수 있는 톤을 유지해요.',
  ];

  String get historyRewardsTitle => '활동 기록과 보상 목표';
  List<String> get historyRewardsItems => const [
    '활동 기록에서 활동 이름, 목표 시간, 실제 시간, 완료 상태를 볼 수 있어요.',
    '받은 스티커와 직접 고른 마커도 함께 확인할 수 있어요.',
    '받은 스티커는 스티커 모음 화면에 쌓여요.',
    '보상 목표가 있으면 성공 스티커가 목표 칸을 채울 수 있어요.',
  ];

  String get exitResumeTitle => '타이머 중 나가기와 이어하기';
  List<String> get exitResumeItems => const [
    '타이머 중 뒤로 가기는 확인 후 처리돼요.',
    '일시정지는 실패가 아니며, 잠깐 쉬었다가 이어갈 수 있어요.',
    '진행 중인 타이머가 저장되어 있으면 홈에 카드가 표시될 수 있어요. 카드에서 이어가기나 취소를 선택해요.',
  ];

  List<String> get guardianTipsItems => const [
    '아이에게 스티커보다 루틴을 시도한 점을 먼저 칭찬해 주세요.',
    '너무 짧은 목표보다 아이에게 맞는 시간을 기본 타이머 시간으로 설정해 주세요.',
    '조금 더 필요했던 결과는 벌이 아니라 다음 조절을 위한 기록으로 안내해 주세요.',
  ];
}
