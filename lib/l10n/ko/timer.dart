// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class TimerTexts implements TimerTextSet {
  const TimerTexts();

  String get courseTitle => '오늘의 냠냠코스';
  String get progressJustStarted => '출발했어요!';
  String get progressGoingWell => '잘 가고 있어요!';
  String get progressPastHalfway => '벌써 많이 왔어요!';
  String get progressAlmostThere => '거의 도착했어요!';
  String get progressArrived => '도착했어요!';
  String get completeDialogTitle => '식사를 완료했어?';
  String get arrivalDialogMessage => '오토바이가 지나갔어. 식사를 마무리했어?';
  String get completeDialogMessage => '오늘의 냠냠코스를 마무리할까?';
  String get pauseButton => '일시정지';
  String get completeMealButton => '식사 완료';
  String get runningArrivalLabel => '도착까지';
  String get pausedTimeLabel => '잠깐 쉬는 중';
  String get arrivedTimeLabel => '도착 완료';
  String get idleTimeLabel => '준비 중';
  String get pausedProgressMessage => '잠깐 쉬어가요';
  String get arrivedProgressMessage => '도착했어요!';
  String get idleProgressMessage => '출발 준비 중';

  String remainingTime(String remaining) => '남은 시간 $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label, 남은 시간 $remaining';
  }
}
