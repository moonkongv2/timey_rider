// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class PtBrActivityHistoryTexts implements ActivityHistoryTextSet {
  const PtBrActivityHistoryTexts();

  String get title => 'Registros de atividade';
  String get emptyTitle => 'Ainda não há registros.';
  String get emptyBody => 'As missões concluídas aparecerão aqui.';
  String get helpTitle => 'Guia do histórico';
  List<String> get helpBulletItems => const [
    'Activity history shows the mission, target time, actual time, completion status, and earned stickers.',
    'Manually chosen picture markers appear when they were saved with the activity.',
    'Auto-selected markers appear on the road only and are not saved in history.',
    'Records without a sticker show No sticker this time.',
  ];
  String get targetTimeLabel => 'Meta';
  String get actualTimeLabel => 'Real';
  String get overrunTimeLabel => 'Extra';
  String get rewardLabel => 'Adesivos ganhos';
  String get noRewardLabel => 'Sem adesivo desta vez';
  String get selectedMarkerLabel => 'Marcadores escolhidos';
  String get deleteRecordLabel => 'Excluir registro';
  String get deleteRecordDialogTitle => 'Excluir este registro?';
  String get deleteRecordDialogBody =>
      'Only the record will be removed. Earned stickers will stay.';
  String get deleteRecordConfirmLabel => 'Excluir';
  String get deleteRecordSuccessMessage => 'Registro excluído.';

  String completedStatus(ActivityCompletionStatus completionStatus) {
    return switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Concluído',
      ActivityCompletionStatus.timeEnded => 'Tempo encerrado',
      ActivityCompletionStatus.needsMoreTime => 'Precisa de mais tempo',
      ActivityCompletionStatus.canceled => 'Cancelado',
    };
  }

  String dateLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} $hour:$minute';
  }

  String overrunTime(String duration) => 'Over +$duration';
}
