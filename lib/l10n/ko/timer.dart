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
  String get completeDialogMessage => '오늘의 냠냠코스를 마무리할까?';
  String get exitDialogTitle => '코스를 그만할까요?';
  String get exitDialogMessage => '지금 나가면 진행 중인 냠냠코스가 저장되지 않아요.';
  String get exitDialogCancelButton => '계속하기';
  String get exitDialogConfirmButton => '그만하기';
  String get pauseButton => '일시정지';
  String get completeMealButton => '식사 완료';
  String get runningArrivalLabel => '남은 식사 시간';
  String get pausedTimeLabel => '잠깐 쉬는 중';
  String get arrivedTimeLabel => '도착 완료';
  String get idleTimeLabel => '준비 중';
  String get pausedProgressMessage => '잠깐 쉬어가요';
  String get arrivedProgressMessage => '도착했어요!';
  String get idleProgressMessage => '출발 준비 중';
  String get finishDriveProgressMessage => '마무리하러 가고 있어요!';
  String get finishDriveTimeLabel => '마무리 중';

  String arrivalDialogMessage(String vehicleLabel) {
    return '$vehicleLabel${_subjectParticle(vehicleLabel)} 지나갔어. 식사를 마무리했어?';
  }

  String remainingTime(String remaining) => '남은 시간 $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label, 남은 시간 $remaining';
  }

  String _subjectParticle(String value) {
    if (value.isEmpty) {
      return '가';
    }

    final lastCodeUnit = value.codeUnitAt(value.length - 1);
    const hangulStart = 0xAC00;
    const hangulEnd = 0xD7A3;
    if (lastCodeUnit < hangulStart || lastCodeUnit > hangulEnd) {
      return '가';
    }

    final hasFinalConsonant = (lastCodeUnit - hangulStart) % 28 != 0;
    return hasFinalConsonant ? '이' : '가';
  }
}
