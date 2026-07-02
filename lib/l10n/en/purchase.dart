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
}
