// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class ActivityHistoryTexts implements ActivityHistoryTextSet {
  const ActivityHistoryTexts();

  String get title => '활동 기록';
  String get emptyTitle => '아직 저장된 활동 기록이 없어.';
  String get emptyBody => '미션 타이머를 마치면 기록이 여기에 쌓여요.';
  String get helpTitle => '활동 기록 안내';
  List<String> get helpBulletItems => const [
    '활동 기록에는 미션, 목표 시간, 실제 시간, 완료 상태, 받은 차량 스티커가 표시돼요.',
    '직접 고른 그림 마커가 있으면 기록에 함께 표시돼요.',
    '자동 선택 마커는 도로에만 보이고 기록에는 남지 않아요.',
    '차량 스티커를 받지 않은 기록은 차량 스티커 받지 않음으로 표시돼요.',
  ];
  String get targetTimeLabel => '목표';
  String get actualTimeLabel => '실제';
  String get overrunTimeLabel => '초과';
  String get rewardLabel => '받은 차량 스티커';
  String get noRewardLabel => '차량 스티커 받지 않음';
  String get selectedMarkerLabel => '고른 마커';
  String get deleteRecordLabel => '활동 기록 삭제';
  String get deleteRecordDialogTitle => '이 활동 기록을 삭제할까요?';
  String get deleteRecordDialogBody => '기록만 삭제되고 받은 차량 스티커는 유지돼요.';
  String get deleteRecordConfirmLabel => '삭제';
  String get deleteRecordSuccessMessage => '활동 기록을 삭제했어요.';

  String completedStatus(ActivityCompletionStatus completionStatus) {
    return switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => '완료',
      ActivityCompletionStatus.timeEnded => '시간 종료',
      ActivityCompletionStatus.needsMoreTime => '조금 더 필요',
      ActivityCompletionStatus.canceled => '취소됨',
    };
  }

  String dateLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}월 ${dateTime.day}일 $hour:$minute';
  }

  String overrunTime(String duration) => '초과 +$duration';
}
