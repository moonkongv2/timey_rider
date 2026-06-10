// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class UserGuideTexts implements UserGuideTextSet {
  const UserGuideTexts();

  String get title => '사용 안내';
  String get subtitle => '식재료, 응원 영상, 스티커 규칙을 확인해요.';
  String get introTitle => '보호자 가이드';
  String get introBody => '냠냠 라이더를 시작하기 전에 식사 흐름과 앱 규칙을 한눈에 확인할 수 있어요.';
  String get basicFlowTitle => startCourseTitle;
  String get ingredientsTitle => roadIngredientsTitle;
  String get motivationTitle => '동기부여 영상';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => '보호자 사용 팁';

  String get whatIsYamyamTitle => '냠냠 라이더는 어떤 앱인가요?';
  List<String> get whatIsYamyamItems => const [
    '식사 시간을 단순한 카운트다운이 아니라 작은 코스 주행처럼 느끼게 해주는 앱이에요.',
    '아이가 차량을 고르고, 정해진 시간 동안 코스를 따라가며 식사 페이스를 맞춰요.',
    '마지막에는 보호자가 식사를 마쳤는지 확인해 완료 여부를 정해요.',
  ];

  String get startCourseTitle => '식사 코스 시작하기';
  List<String> get startCourseItems => const [
    '아이 이름을 설정한 뒤 홈에서 탈 차량을 고를 수 있어요.',
    '15분, 25분, 35분 코스나 직접 설정한 시간을 선택해 시작해요.',
    '설정에 따라 코스 시작 전 식재료를 고르거나, 앱이 자동으로 보여줄 수 있어요.',
    '타이머 중 일시정지는 실패가 아니며, 식사 흐름에 맞춰 잠깐 멈출 수 있어요.',
  ];

  String get roadIngredientsTitle => '도로 위 식재료';
  List<String> get roadIngredientsItems => const [
    '식재료는 아이가 오늘 먹는 음식을 떠올리도록 돕는 시각적 표시예요.',
    '영양 평가나 성공/실패 판정이 아니에요.',
    '사용 안 함: 도로 위에 식재료를 표시하지 않아요.',
    '직접 선택: 코스 시작 전 최대 5개까지 골라요. 직접 고른 식재료가 식사 기록에 남아요.',
    '자동 선택: 앱이 랜덤 식재료를 도로에 보여줘요. 기록에는 남지 않아요.',
    '식사 기록에는 직접 고른 식재료만 남는다는 점을 기억해 주세요.',
  ];

  List<String> get motivationItems => const [
    '식사 중간에 나오는 짧은 응원 영상이에요.',
    '보상 판정이나 성공/미완료 판정과는 관계가 없어요.',
    '기본적으로 식사 진행 상황에 따라 나와요.',
    '긴 코스나 직접 설정을 쓰면 시간 간격 기준으로 나올 수 있어요.',
    '영상 간격은 3분, 5분, 10분 중에서 선택할 수 있어요.',
    '소리 설정이 꺼져 있으면 영상만 나오거나 음성이 재생되지 않을 수 있어요.',
  ];

  String get completionTitle => '완료, 미완료, 스티커';
  List<String> get completionItems => const [
    '식사를 마쳤다고 확인하면 성공으로 기록돼요.',
    '성공하면 랜덤 성공 스티커 1개를 받아요.',
    '타이머가 먼저 도착했는데 식사가 끝나지 않았다면 “아직 아니에요”를 눌러요. 이때 미완료로 기록돼요.',
    '미완료 기록은 남지만 스티커는 받지 않아요.',
    '아이 화면은 강한 실패 표현보다 다음 도전을 떠올릴 수 있는 톤을 유지해요.',
  ];

  String get historyRewardsTitle => '식사 기록과 보상 목표';
  List<String> get historyRewardsItems => const [
    '식사 기록에서 목표 시간, 실제 시간, 완료 상태를 볼 수 있어요. 받은 스티커와 직접 고른 식재료도 함께 확인해요.',
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
    '아이에게 스티커보다 식사 흐름을 이어간 점을 먼저 칭찬해 주세요.',
    '너무 짧은 목표보다 아이에게 맞는 시간을 기본 식사 시간으로 설정해 주세요.',
    '미완료 결과는 벌이 아니라 다음 도전을 위한 기록으로 안내해 주세요.',
  ];
}
