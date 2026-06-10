// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class UserGuideTexts implements UserGuideTextSet {
  const UserGuideTexts();

  String get title => '사용 안내';
  String get subtitle => '식재료, 응원 영상, 스티커 규칙을 확인해요.';
  String get introTitle => '보호자 가이드';
  String get introBody => '냠냠 라이더를 시작하기 전에 식사 흐름과 앱 규칙을 한눈에 확인할 수 있어요.';
  String get basicFlowTitle => '기본 사용 흐름';
  String get ingredientsTitle => '식재료 선택';
  String get motivationTitle => '응원 영상';
  String get resultRewardsTitle => '결과와 스티커';
  String get historyTitle => '식사 기록';
  String get guardianTipsTitle => '보호자 팁';
}
