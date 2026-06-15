// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class ActivityMarkerTexts implements ActivityMarkerTextSet {
  const ActivityMarkerTexts();

  String get title => '코스 마커를 골라볼까?';
  String get subtitle => '고른 마커가 코스 위에 차례로 나타나요.';
  String get helpLinkLabel => '코스 마커 안내';
  String get helpTitle => '코스 마커 안내';
  List<String> get helpBodyParagraphs => const [
    '코스 마커는 활동 중 도로 위에 나타나는 작은 목표 표시예요.',
    '완료 여부나 차량 스티커 판정을 직접 결정하지 않아요.',
  ];
  List<String> get helpBulletItems => const [
    '자동: 선택한 활동에 어울리는 그림 마커를 미리 보여주고 사용해요.',
    '직접 선택: 시작 전 그림 마커를 최대 5개까지 골라요.',
    '활동 기록에는 직접 고른 그림 마커만 남아요.',
  ];
  String get automaticStartButton => '자동으로 출발';
  String get selectedStartButton => '선택한 마커로 출발';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount개 선택';
  }
}
