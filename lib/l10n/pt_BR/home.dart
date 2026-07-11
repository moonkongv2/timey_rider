// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class PtBrHomeTexts implements HomeTextSet {
  const PtBrHomeTexts();

  String get subtitle => 'Prontos para a rotina de hoje?';
  String get heroMissionTitle => 'Missão de hoje';
  String get heroMissionSubtitle => 'Seu rider espera uma chegada divertida';
  String get todayVehicleTitle => 'Veículo de hoje';
  String get vehiclePickerTitle => 'Escolher veículo';
  String get vehicleChangeButton => 'Trocar';
  String get morningCourse => 'Corrida de 15 min';
  String get morningCourseSubtitle => 'Um aquecimento leve';
  String get slowCourse => 'Corrida de 35 min';
  String get slowCourseSubtitle => 'Siga com calma até a chegada';
  String get quickCourseTitle => 'Outras atividades';
  String get activityQuickStartTitle => 'Missão de hoje';
  String get customStartButton => 'Iniciar corrida personalizada';
  String get customSheetTitle => 'Tempo personalizado';
  String get customTimerTitle => 'Outra';
  String get timerBuilderButton => 'Criar timer';
  String get timerBuilderSubtitle =>
      'Escolha missão, marcadores e tempo antes de começar.';
  String get timerBuilderSheetTitle => 'Criar timer';
  String get timerBuilderActivityStepTitle => '1. Missão';
  String get timerBuilderMarkerStepTitle => '2. Marcadores';
  String get timerBuilderAutomaticMarkerOption => 'Auto';
  String get timerBuilderManualMarkerOption => 'Escolher';
  String get timerBuilderRecentPresetTitle => 'Configuração recente';
  String get timerBuilderRecentPresetApplyButton => 'Aplicar';
  String get timerBuilderSavedPresetTitle => 'Timers salvos';
  String get timerBuilderSavePresetButton => 'Salvar';
  String get timerBuilderSavedPresetMessage => 'Salvo.';
  String get timerBuilderSavedPresetFullMessage =>
      'Salvo. Timers antigos são limpos automaticamente.';
  String get timerBuilderSavedPresetLimitHint =>
      'Novos salvamentos substituem o timer mais antigo.';
  String get timerBuilderDeletePresetTooltip => 'Excluir';
  String get timerBuilderFavoritePresetTooltip => 'Mostrar no Início';
  String get timerBuilderUnfavoritePresetTooltip => 'Ocultar do Início';
  String get timerBuilderFavoritePresetLimitMessage =>
      'Até 3 timers podem ser mostrados no Início.';
  String get timerBuilderCustomNameDialogTitle => 'Nome do timer';
  String get timerBuilderCustomNameFieldLabel => 'Nome';
  String get timerBuilderUseOtherNameButton => 'Salvar como Outra';
  String get timerBuilderTimeStepTitle => '3. Tempo';
  String get timerBuilderStartButton => 'Começar';
  String get timerBuilderSelectedMarkerEmpty => 'Escolha de 1 a 5 marcadores.';
  String get activitySummaryLabel => 'Missões';
  String get stickerKindSummaryLabel => 'Tipos de veículo';
  String get stickerSummaryLabel => 'Adesivos';
  String get noActivityHistory => 'Ainda não há histórico.';
  String get openStickerCollection => 'Ver coleção de adesivos';
  String get avatarCtaSubtitle => 'Adicione o rosto da criança à corrida.';
  String get avatarCtaButton => 'Criar';
  String get avatarCtaEditButton => 'Editar';
  String get avatarCtaCreateSemantics => 'Criar imagem do rider';
  String get avatarCtaEditSemantics => 'Editar imagem do rider';
  String get avatarInlineDefaultState => 'Usando rosto padrão';
  String get avatarInlineCustomState => 'Rider personalizado pronto';
  String get activeTimerTitle => 'Há um timer em andamento';
  String get activeTimerResumeButton => 'Continuar';
  String get activeTimerCancelButton => 'Cancelar timer';
  String get activeTimerCancelDialogTitle => 'Cancelar o timer em andamento?';
  String get activeTimerCancelDialogMessage =>
      'Este timer de atividade não será salvo no histórico.';
  String get activeTimerNewTimerDialogTitle =>
      'Já existe um timer em andamento';
  String get activeTimerNewTimerDialogMessage =>
      'Iniciar um novo timer cancelará o atual.';
  String get activeTimerStartNewButton => 'Começar novo';
  String get activeTimerArrivedSubtitle => 'O tempo da atividade terminou';

  String recentCustomMinutes(int minutes) => 'Recente $minutes min';
  String minuteLabel(int minutes) => '$minutes min';
  String timerBuilderSavedPresetCount(int count, int maxCount) {
    return '$count/$maxCount';
  }

  String activeTimerSubtitle(String remainingTime) => '$remainingTime restante';
  String normalCourse(int minutes) => 'Corrida normal de $minutes min';
  String alternateCourse(int minutes) => 'Corrida de $minutes min';
  String alternateCourseSubtitle(int minutes) {
    return switch (minutes) {
      15 => 'Um aquecimento leve',
      25 => 'Um ritmo constante para o dia a dia',
      35 => 'Siga com calma até a chegada',
      _ => 'Corra por $minutes min',
    };
  }

  String progressTitle(String childName) =>
      'Histórico de atividades de $childName';
  String activityCount(int count) => '$count';
  String stickerKindCount(int count) => '$count';
  String stickerCount(int count) => '$count';
  String recentActivitySummary(
    String actualDuration,
    ActivityCompletionStatus completionStatus,
  ) {
    final status = switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Concluído',
      ActivityCompletionStatus.timeEnded => 'Tempo encerrado',
      ActivityCompletionStatus.needsMoreTime => 'Precisa de mais tempo',
      ActivityCompletionStatus.canceled => 'Cancelado',
    };
    return 'Atividade recente $actualDuration · $status';
  }
}
