// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrRewardTexts implements RewardTextSet {
  const PtBrRewardTexts();

  String get collectionTitle => 'Coleção de adesivos';
  String get lockedSticker => 'Ainda não coletado';
  String get lockedStatus => 'Bloqueado';
  String get uncollectedSemanticLabel => 'Ainda não coletado';
  String get rewardGoalTitle => 'Meta de recompensa';
  String get createRewardGoal => 'Criar meta';
  String get rewardGoalEmptyTitle => 'Criar uma nova meta';
  String get rewardGoalEmptyBody =>
      'Cada atividade concluída adiciona o adesivo escolhido e preenche um espaço no quadro.';
  String get rewardGoalRewardFieldLabel => 'Recompensa';
  String get rewardGoalRequiredStickerCountLabel => 'Adesivos necessários';
  String get rewardGoalSaveButton => 'Salvar meta';
  String get rewardGoalReadyMessage => 'Sua recompensa está pronta!';
  String get rewardGoalGivenButton => 'Marcar usada';
  String get rewardGoalCreatedMessage => 'Meta salva.';
  String get rewardGoalUpdatedMessage => 'Meta atualizada.';
  String get rewardGoalCanceledMessage => 'Meta cancelada.';
  String get rewardGoalRedeemedMessage => 'Recompensa entregue.';
  String get rewardGoalUsedMessage => 'Recompensa usada.';
  String get rewardGoalProgressTitle => 'Quadro de recompensa';
  String get rewardGoalEmptySlotSemanticLabel => 'Espaço vazio';
  String get openRewardGoal => 'Ver quadro';
  String get rewardGoalPromiseTitle => 'Recompensa atual';
  String get activeRewardGoalsTitle => 'Metas ativas';
  String get earnedRewardGoalsTitle => 'Recompensas ganhas';
  String get usedRewardGoalsTitle => 'Recompensas usadas';
  String get maxActiveRewardGoalsMessage =>
      'Você pode manter até 2 metas ativas.';
  String get editRewardGoal => 'Editar meta';
  String get cancelRewardGoal => 'Cancelar meta';
  String get rewardGoalHistoryTitle => 'Histórico de recompensas';
  String get rewardGoalNoHistory => 'Nenhuma recompensa foi entregue ainda.';
  String get confirmRedeemRewardGoalTitle => 'A recompensa foi entregue?';
  String get confirmRedeemRewardGoalMessage =>
      'Esta recompensa irá para o histórico.';
  String get confirmCancelRewardGoalTitle => 'Cancelar esta meta?';
  String get confirmCancelRewardGoalMessage =>
      'O progresso atual do quadro será removido.';
  String get keepRewardGoal => 'Manter meta';
  String get confirmRewardGiven => 'Marcar entregue';
  String get confirmCancelGoal => 'Cancelar meta';
  String get confirmUseRewardGoalTitle => 'Marcar esta recompensa como usada?';
  String get confirmUseRewardGoalMessage =>
      'Ela passará de recompensas ganhas para recompensas usadas.';
  String get confirmUseRewardGoal => 'Marcar usada';

  String stickerCount(int count) => '$count adesivos';
  String rewardGoalProgress(int filledCount, int requiredCount) =>
      '$filledCount/$requiredCount';
  String rewardGoalRemaining(int remainingCount) =>
      'Faltam $remainingCount espaços';
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName) =>
      'Espaço $slotNumber, $rewardName';
  String rewardGoalReadyAt(String dateLabel) => 'Pronta: $dateLabel';
  String rewardGoalRedeemedAt(String dateLabel) => 'Entregue: $dateLabel';
}
