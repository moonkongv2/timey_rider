// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnPurchaseTexts implements PurchaseTextSet {
  const EnPurchaseTexts();

  String get vehiclePackInfoTitle => 'This vehicle is in the vehicle pack';
  String vehiclePackInfoSubtitle(String vehicleLabel) {
    return '$vehicleLabel is included in the vehicle pack.';
  }

  String get vehiclePackInfoUnlockAllMessage =>
      'The vehicle pack unlocks all locked vehicles.';
  String get vehiclePackInfoGuardianNote =>
      'Purchase options open only after a parent check.';
  String get vehiclePackInfoContinueButton => 'Continue with a parent';
  String get vehiclePackInfoCloseButton => 'Close';
  String get parentGateTitle => 'Parent check';
  String get parentGateSubtitle =>
      'Only a parent or guardian should open purchase options. Solve this quick check to continue.';
  String parentGateQuestion(int left, int right) => 'What is $left + $right?';
  String get parentGateAnswerLabel => 'Answer';
  String get parentGateContinueButton => 'Continue';
  String get parentGateErrorMessage => 'Check the answer and try again.';
  String get vehiclePackPurchaseTitle => 'Unlock the vehicle pack';
  String get vehiclePackPurchaseSubtitle =>
      'A one-time purchase unlocks all locked vehicles.';
  String get vehiclePackPurchaseLoadingMessage =>
      'Loading vehicle pack details.';
  String get vehiclePackPurchaseUnavailableMessage =>
      'Vehicle pack details are not available right now. Try again later.';
  String get vehiclePackPurchaseButton => 'Unlock vehicle pack';
  String get vehiclePackRestoreButton => 'Restore purchase';
  String get vehiclePackPurchaseInProgressMessage =>
      'The store purchase is in progress.';
  String get vehiclePackPendingMessage => 'Waiting for purchase approval.';
  String get vehiclePackPurchasedMessage => 'Vehicle pack unlocked.';
  String get vehiclePackRestoredMessage => 'Vehicle pack purchase restored.';
  String get vehiclePackCanceledMessage => 'Purchase canceled.';
  String get vehiclePackErrorMessage =>
      'The purchase could not be completed. Try again.';
  String vehiclePackPriceLabel(String price) => 'Price $price';
}
