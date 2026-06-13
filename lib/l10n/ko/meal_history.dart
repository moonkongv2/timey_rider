// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/meal_completion_status.dart';

class MealHistoryTexts implements MealHistoryTextSet {
  const MealHistoryTexts();

  String get title => '식사 기록';
  String get emptyTitle => '아직 식사 기록이 없어요';
  String get emptyBody => '타이머를 완료하면 기록이 여기에 쌓여요.';
  String get helpTitle => '식사 기록 안내';
  List<String> get helpBulletItems => const [
    '식사 기록에는 목표 시간, 실제 시간, 완료 상태, 받은 스티커가 표시돼요.',
    '직접 고른 식재료가 있으면 기록에 함께 표시돼요.',
    '자동 선택 식재료는 도로에만 보이고 기록에는 남지 않아요.',
    '미완료 기록은 스티커 없음으로 표시될 수 있어요.',
  ];
  String get targetTimeLabel => '목표';
  String get actualTimeLabel => '실제';
  String get overrunTimeLabel => '초과';
  String get rewardLabel => '받은 스티커';
  String get noRewardLabel => '스티커 없음';
  String get selectedIngredientLabel => '고른 식재료';
  String get deleteRecordLabel => '식사 기록 삭제';
  String get deleteRecordDialogTitle => '이 식사 기록을 삭제할까요?';
  String get deleteRecordDialogBody => '기록만 삭제되고 받은 스티커는 유지돼요.';
  String get deleteRecordConfirmLabel => '삭제';
  String get deleteRecordSuccessMessage => '식사 기록을 삭제했어요.';

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
