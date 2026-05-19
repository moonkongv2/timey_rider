// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class HomeTexts implements HomeTextSet {
  const HomeTexts();

  String get subtitle => '오늘도 냠냠 코스를 달려볼까?';
  String get heroMissionTitle => '오늘의 냠냠 미션';
  String get heroMissionSubtitle => '라이더가 맛있는 완주를 기다리고 있어요';
  String get todayVehicleTitle => '오늘의 빠방';
  String get morningCourse => '15분 아침 코스';
  String get morningCourseSubtitle => '가볍게 워밍업';
  String get normalCourse => '25분 보통 코스';
  String get slowCourse => '35분 천천히 코스';
  String get slowCourseSubtitle => '천천히 완주하기';
  String get quickCourseTitle => '다른 코스';
  String get customStartButton => '직접 설정으로 출발';
  String get customSheetTitle => '직접 설정';
  String get mealSummaryLabel => '식사';
  String get stickerKindSummaryLabel => '종류';
  String get stickerSummaryLabel => '스티커';
  String get noMealHistory => '아직 저장된 식사 이력이 없어.';
  String get openStickerCollection => '스티커 보관함 보기';
  String get avatarCtaSubtitle => '아이 얼굴을 빠방에 태워보세요.';
  String get avatarCtaButton => '만들기';
  String get avatarCtaEditButton => '편집';
  String get avatarCtaCreateSemantics => '아바타 만들기';
  String get avatarCtaEditSemantics => '아바타 편집';
  String get avatarInlineDefaultState => '기본 얼굴 사용 중';
  String get avatarInlineCustomState => '아이 얼굴 탑승 중';

  String recentCustomMinutes(int minutes) => '최근 $minutes분';
  String minuteLabel(int minutes) => '$minutes분';
  String progressTitle(String childName) =>
      '${_casualKoreanName(childName)}의 냠냠 기록';
  String mealCount(int count) => '$count번';
  String stickerKindCount(int count) => '$count개';
  String stickerCount(int count) => '$count장';
  String recentMealSummary(String actualDuration, bool completedBeforeArrival) {
    final status = completedBeforeArrival ? '도착 전 완료' : '도착 후 완료';
    return '최근 식사 $actualDuration · $status';
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
