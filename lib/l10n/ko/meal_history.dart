// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/meal_completion_status.dart';

class MealHistoryTexts implements MealHistoryTextSet {
  const MealHistoryTexts();

  String get title => '식사 기록';
  String get emptyTitle => '아직 식사 기록이 없어요';
  String get emptyBody => '타이머를 완료하면 기록이 여기에 쌓여요.';
  String get targetTimeLabel => '목표';
  String get actualTimeLabel => '실제';
  String get overrunTimeLabel => '초과';
  String get rewardLabel => '받은 스티커';
  String get noRewardLabel => '스티커 없음';

  String completedStatus(MealCompletionStatus completionStatus) {
    return completionStatus == MealCompletionStatus.notCompleted ? '미완료' : '완료';
  }

  String dateLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}월 ${dateTime.day}일 $hour:$minute';
  }

  String overrunTime(String duration) => '초과 +$duration';
}
