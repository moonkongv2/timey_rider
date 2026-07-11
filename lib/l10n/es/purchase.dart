// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsPurchaseTexts implements PurchaseTextSet {
  const EsPurchaseTexts();

  String get vehiclePackInfoTitle => 'Este vehículo está en el pack';
  String vehiclePackInfoSubtitle(String vehicleLabel) {
    return '$vehicleLabel está incluido en el pack de vehículos.';
  }

  String get vehiclePackInfoUnlockAllMessage =>
      'El pack desbloquea todos los vehículos bloqueados.';
  String get vehiclePackInfoGuardianNote =>
      'Las opciones de compra se abren solo después de una comprobación para adultos.';
  String get vehiclePackInfoContinueButton => 'Continuar con un adulto';
  String get vehiclePackInfoCloseButton => 'Cerrar';
  String get parentGateTitle => 'Comprobación para adultos';
  String get parentGateSubtitle =>
      'Solo un padre, madre o tutor debería abrir las opciones de compra. Resuelve esta comprobación rápida para continuar.';
  String parentGateQuestion(int left, int right) =>
      '¿Cuánto es $left + $right?';
  String get parentGateAnswerLabel => 'Respuesta';
  String get parentGateContinueButton => 'Continuar';
  String get parentGateErrorMessage =>
      'Revisa la respuesta e inténtalo de nuevo.';
  String get vehiclePackPurchaseTitle => 'Desbloquear el pack de vehículos';
  String get vehiclePackPurchaseSubtitle =>
      'Una compra única desbloquea todos los vehículos bloqueados.';
  String get vehiclePackPurchaseLoadingMessage =>
      'Cargando detalles del pack de vehículos.';
  String get vehiclePackPurchaseUnavailableMessage =>
      'Los detalles del pack no están disponibles ahora. Inténtalo más tarde.';
  String get vehiclePackPurchaseButton => 'Desbloquear pack';
  String get vehiclePackRestoreButton => 'Restaurar compra';
  String get vehiclePackPurchaseInProgressMessage =>
      'La compra en la tienda está en curso.';
  String get vehiclePackPendingMessage => 'Esperando aprobación de la compra.';
  String get vehiclePackRestoringMessage => 'Comprobando historial de compras.';
  String get vehiclePackRestoreNotFoundMessage =>
      'No se encontró ninguna compra del pack para restaurar.';
  String get vehiclePackPurchasedMessage => 'Pack de vehículos desbloqueado.';
  String get vehiclePackRestoredMessage => 'Compra del pack restaurada.';
  String get vehiclePackCanceledMessage => 'Compra cancelada.';
  String get vehiclePackErrorMessage =>
      'No se pudo completar la compra. Inténtalo de nuevo.';
  String vehiclePackPriceLabel(String price) => 'Precio $price';
}
