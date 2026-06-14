// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class HomeTexts implements HomeTextSet {
  const HomeTexts();

  String get subtitle => '오늘도 작은 라이딩으로 루틴을 시작해볼까?';
  String get heroMissionTitle => '오늘의 미션';
  String get heroMissionSubtitle => '라이더가 즐거운 완주를 기다리고 있어요';
  String get todayVehicleTitle => '오늘의 빠방';
  String get vehiclePickerTitle => '빠방 고르기';
  String get vehicleChangeButton => '변경';
  String get morningCourse => '15분 코스';
  String get morningCourseSubtitle => '가볍게 워밍업';
  String get slowCourse => '35분 코스';
  String get slowCourseSubtitle => '천천히 완주하기';
  String get quickCourseTitle => '다른 활동';
  String get activityQuickStartTitle => '오늘의 미션';
  String get customStartButton => '직접 설정으로 출발';
  String get customSheetTitle => '직접 설정';
  String get customTimerTitle => '기타';
  String get timerBuilderButton => '타이머 만들기';
  String get timerBuilderSubtitle => '미션, 마커, 시간을 골라 바로 출발해요.';
  String get timerBuilderSheetTitle => '타이머 만들기';
  String get timerBuilderActivityStepTitle => '1. 미션 종류';
  String get timerBuilderMarkerStepTitle => '2. 마커';
  String get timerBuilderAutomaticMarkerOption => '자동';
  String get timerBuilderManualMarkerOption => '선택';
  String get timerBuilderRecentPresetTitle => '최근 설정';
  String get timerBuilderRecentPresetApplyButton => '적용';
  String get timerBuilderSavedPresetTitle => '저장한 타이머';
  String get timerBuilderSavePresetButton => '저장';
  String get timerBuilderSavedPresetMessage => '저장했어요.';
  String get timerBuilderSavedPresetFullMessage => '저장했어요. 오래된 타이머는 자동으로 정리돼요.';
  String get timerBuilderSavedPresetLimitHint => '새로 저장하면 가장 오래된 타이머가 정리돼요.';
  String get timerBuilderDeletePresetTooltip => '삭제';
  String get timerBuilderFavoritePresetTooltip => '홈에 표시';
  String get timerBuilderUnfavoritePresetTooltip => '홈에서 숨기기';
  String get timerBuilderFavoritePresetLimitMessage => '홈에는 최대 3개까지 표시할 수 있어요.';
  String get timerBuilderCustomNameDialogTitle => '타이머 이름';
  String get timerBuilderCustomNameFieldLabel => '이름';
  String get timerBuilderUseOtherNameButton => '기타로 저장';
  String get timerBuilderTimeStepTitle => '3. 시간';
  String get timerBuilderStartButton => '출발';
  String get timerBuilderSelectedMarkerEmpty => '마커를 1~5개 선택해요.';
  String get activitySummaryLabel => '미션';
  String get stickerKindSummaryLabel => '종류';
  String get stickerSummaryLabel => '스티커';
  String get noActivityHistory => '아직 저장된 활동 기록이 없어.';
  String get openStickerCollection => '스티커 보관함 보기';
  String get avatarCtaSubtitle => '아이 얼굴을 빠방에 태워보세요.';
  String get avatarCtaButton => '만들기';
  String get avatarCtaEditButton => '편집';
  String get avatarCtaCreateSemantics => '아바타 만들기';
  String get avatarCtaEditSemantics => '아바타 편집';
  String get avatarInlineDefaultState => '기본 얼굴 사용 중';
  String get avatarInlineCustomState => '아이 얼굴 탑승 중';
  String get activeTimerTitle => '진행 중인 활동 타이머';
  String get activeTimerResumeButton => '이어가기';
  String get activeTimerCancelButton => '취소하기';
  String get activeTimerCancelDialogTitle => '진행 중인 타이머를 취소할까요?';
  String get activeTimerCancelDialogMessage => '취소하면 이 활동 타이머는 기록에 남지 않아요.';
  String get activeTimerNewTimerDialogTitle => '진행 중인 타이머가 있어요';
  String get activeTimerNewTimerDialogMessage => '새 타이머를 시작하면 진행 중인 타이머는 취소돼요.';
  String get activeTimerStartNewButton => '새로 시작';
  String get activeTimerArrivedSubtitle => '활동 시간이 끝났어요';

  String recentCustomMinutes(int minutes) => '최근 $minutes분';
  String minuteLabel(int minutes) => '$minutes분';
  String timerBuilderSavedPresetCount(int count, int maxCount) {
    return '$count/$maxCount개';
  }

  String activeTimerSubtitle(String remainingTime) => '남은 시간 $remainingTime';
  String normalCourse(int minutes) => '$minutes분 보통 코스';
  String alternateCourse(int minutes) => '$minutes분 코스';
  String alternateCourseSubtitle(int minutes) {
    return switch (minutes) {
      15 => '가볍게 워밍업',
      25 => '기본 리듬으로 완주',
      35 => '천천히 완주하기',
      _ => '$minutes분으로 달리기',
    };
  }

  String progressTitle(String childName) =>
      '${_casualKoreanName(childName)}의 활동 기록';
  String activityCount(int count) => '$count번';
  String stickerKindCount(int count) => '$count개';
  String stickerCount(int count) => '$count장';
  String recentActivitySummary(
    String actualDuration,
    ActivityCompletionStatus completionStatus,
  ) {
    final status = switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd => '시간 전에 완료',
      ActivityCompletionStatus.completedAtEnd => '시간에 맞춰 완료',
      ActivityCompletionStatus.completedAfterEnd => '조금 더 하고 완료',
      ActivityCompletionStatus.timeEnded => '시간 종료',
      ActivityCompletionStatus.needsMoreTime => '조금 더 필요',
      ActivityCompletionStatus.canceled => '취소됨',
    };
    return '최근 기록 $actualDuration · $status';
  }
}

String _casualKoreanName(String name) {
  if (name.isEmpty || !_hasFinalConsonant(name)) {
    return name;
  }
  return '$name이';
}

bool _hasFinalConsonant(String value) {
  final codeUnit = value.codeUnitAt(value.length - 1);
  const hangulStart = 0xAC00;
  const hangulEnd = 0xD7A3;
  if (codeUnit < hangulStart || codeUnit > hangulEnd) {
    return false;
  }
  return (codeUnit - hangulStart) % 28 != 0;
}
