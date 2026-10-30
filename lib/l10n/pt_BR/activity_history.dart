// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class PtBrActivityHistoryTexts implements ActivityHistoryTextSet {
  const PtBrActivityHistoryTexts();

  String get title => 'Registros de atividade';
  String get emptyTitle => 'Ainda não há registros.';
  String get emptyBody => 'As missões concluídas aparecerão aqui.';
  String get helpTitle => 'Guia do histórico';
  List<String> get helpBulletItems => [
    deleteRecordOnlyWarning,
    deleteLinkedRewardsBody,
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

  String get deleteLinkedRewardsLabel =>
      'Excluir também os adesivos desta atividade';
  String get deleteLinkedRewardsBody =>
      'Remove os adesivos e as casas vinculadas nos quadros de recompensas não usadas. Recompensas abaixo da meta voltam a ficar em andamento. Recompensas usadas são mantidas.';
  String get deleteRecordOnlyLabel => 'Excluir só o registro';
  String get deleteWithRewardsLabel => 'Excluir com adesivos';
  String get loadFailureMessage =>
      'Não foi possível carregar seu progresso. Tente novamente.';
  String get storageFailureMessage =>
      'Não foi possível concluir o salvamento. Tente novamente para recuperar o estado salvo.';
  String get dataFailureMessage =>
      'Há um problema com os dados salvos. Se persistir após tentar novamente, entre em contato com o suporte.';
  String get deletedActivityMessage =>
      'Esta atividade foi excluída. Seus adesivos não serão concedidos novamente.';
  String get goHomeLabel => 'Ir ao início';
  String additionalGoals(int count) => 'Mais $count';
  String get deleteRecordOnlyWarning =>
      'Ao excluir só o registro, você não poderá mais remover os adesivos vinculados por esta atividade.';

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
