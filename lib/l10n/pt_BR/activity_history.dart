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
    'O histórico mostra a missão, o tempo previsto, o tempo real, o status de conclusão e os adesivos ganhos.',
    'Os marcadores com imagens escolhidos manualmente aparecem quando foram salvos com a atividade.',
    'Os marcadores selecionados automaticamente aparecem apenas na rota e não são salvos no histórico.',
    'Registros sem adesivo mostram Sem adesivo desta vez.',
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
      'Apenas o registro será removido. Os adesivos ganhos serão mantidos.';
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

  String overrunTime(String duration) => 'Extra +$duration';
}
