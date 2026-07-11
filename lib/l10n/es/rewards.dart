// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsRewardTexts implements RewardTextSet {
  const EsRewardTexts();

  String get collectionTitle => 'Colección de pegatinas';
  String get lockedSticker => 'Aún no conseguida';
  String get lockedStatus => 'Bloqueada';
  String get uncollectedSemanticLabel => 'Aún no conseguida';
  String get rewardGoalTitle => 'Meta de recompensa';
  String get createRewardGoal => 'Crear meta';
  String get rewardGoalEmptyTitle => 'Crear una nueva meta';
  String get rewardGoalEmptyBody =>
      'Cada actividad completada añade la pegatina elegida y llena un espacio del tablero.';
  String get rewardGoalRewardFieldLabel => 'Recompensa';
  String get rewardGoalRequiredStickerCountLabel => 'Pegatinas necesarias';
  String get rewardGoalSaveButton => 'Guardar meta';
  String get rewardGoalReadyMessage => '¡Tu recompensa está lista!';
  String get rewardGoalGivenButton => 'Marcar usada';
  String get rewardGoalCreatedMessage => 'Meta guardada.';
  String get rewardGoalUpdatedMessage => 'Meta actualizada.';
  String get rewardGoalCanceledMessage => 'Meta cancelada.';
  String get rewardGoalRedeemedMessage => 'Recompensa entregada.';
  String get rewardGoalUsedMessage => 'Recompensa usada.';
  String get rewardGoalProgressTitle => 'Tablero de recompensa';
  String get rewardGoalEmptySlotSemanticLabel => 'Espacio vacío';
  String get openRewardGoal => 'Ver tablero';
  String get rewardGoalPromiseTitle => 'Recompensa actual';
  String get activeRewardGoalsTitle => 'Metas activas';
  String get earnedRewardGoalsTitle => 'Recompensas ganadas';
  String get usedRewardGoalsTitle => 'Recompensas usadas';
  String get maxActiveRewardGoalsMessage =>
      'Puedes tener hasta 2 metas activas.';
  String get editRewardGoal => 'Editar meta';
  String get cancelRewardGoal => 'Cancelar meta';
  String get rewardGoalHistoryTitle => 'Historial de recompensas';
  String get rewardGoalNoHistory =>
      'Aún no se ha entregado ninguna recompensa.';
  String get confirmRedeemRewardGoalTitle => '¿Se entregó la recompensa?';
  String get confirmRedeemRewardGoalMessage =>
      'Esta recompensa pasará al historial.';
  String get confirmCancelRewardGoalTitle => '¿Cancelar esta meta?';
  String get confirmCancelRewardGoalMessage =>
      'Se eliminará el progreso actual del tablero.';
  String get keepRewardGoal => 'Mantener meta';
  String get confirmRewardGiven => 'Marcar entregada';
  String get confirmCancelGoal => 'Cancelar meta';
  String get confirmUseRewardGoalTitle => '¿Marcar esta recompensa como usada?';
  String get confirmUseRewardGoalMessage =>
      'Pasará de recompensas ganadas a recompensas usadas.';
  String get confirmUseRewardGoal => 'Marcar usada';

  String stickerCount(int count) => '$count pegatinas';
  String rewardGoalProgress(int filledCount, int requiredCount) =>
      '$filledCount/$requiredCount';
  String rewardGoalRemaining(int remainingCount) =>
      'Quedan $remainingCount espacios';
  String rewardGoalSlotSemanticLabel(int slotNumber, String rewardName) =>
      'Espacio $slotNumber, $rewardName';
  String rewardGoalReadyAt(String dateLabel) => 'Lista: $dateLabel';
  String rewardGoalRedeemedAt(String dateLabel) => 'Entregada: $dateLabel';
}
