// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrPurchaseTexts implements PurchaseTextSet {
  const PtBrPurchaseTexts();

  String get vehiclePackInfoTitle => 'Este veículo está no pacote';
  String vehiclePackInfoSubtitle(String vehicleLabel) {
    return '$vehicleLabel está incluído no pacote de veículos.';
  }

  String get vehiclePackInfoUnlockAllMessage =>
      'O pacote desbloqueia todos os veículos bloqueados.';
  String get vehiclePackInfoGuardianNote =>
      'As opções de compra só abrem depois da verificação dos pais.';
  String get vehiclePackInfoContinueButton => 'Continuar com responsável';
  String get vehiclePackInfoCloseButton => 'Fechar';
  String get parentGateTitle => 'Verificação dos pais';
  String get parentGateSubtitle =>
      'Somente um responsável deve abrir as opções de compra. Resolva esta verificação rápida para continuar.';
  String parentGateQuestion(int left, int right) => 'Quanto é $left + $right?';
  String get parentGateAnswerLabel => 'Resposta';
  String get parentGateContinueButton => 'Continuar';
  String get parentGateErrorMessage => 'Confira a resposta e tente de novo.';
  String get vehiclePackPurchaseTitle => 'Desbloquear pacote de veículos';
  String get vehiclePackPurchaseSubtitle =>
      'Uma compra única desbloqueia todos os veículos bloqueados.';
  String get vehiclePackPurchaseLoadingMessage =>
      'Carregando detalhes do pacote de veículos.';
  String get vehiclePackPurchaseUnavailableMessage =>
      'Os detalhes do pacote não estão disponíveis agora. Tente mais tarde.';
  String get vehiclePackPurchaseButton => 'Desbloquear pacote';
  String get vehiclePackRestoreButton => 'Restaurar compra';
  String get vehiclePackPurchaseInProgressMessage =>
      'A compra na loja está em andamento.';
  String get vehiclePackPendingMessage => 'Aguardando aprovação da compra.';
  String get vehiclePackRestoringMessage => 'Verificando histórico de compras.';
  String get vehiclePackRestoreNotFoundMessage =>
      'Nenhuma compra do pacote foi encontrada para restaurar.';
  String get vehiclePackPurchasedMessage => 'Pacote de veículos desbloqueado.';
  String get vehiclePackRestoredMessage => 'Compra do pacote restaurada.';
  String get vehiclePackCanceledMessage => 'Compra cancelada.';
  String get vehiclePackErrorMessage =>
      'Não foi possível concluir a compra. Tente de novo.';
  String vehiclePackPriceLabel(String price) => 'Preço $price';
}
