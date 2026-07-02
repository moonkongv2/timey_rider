// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PurchaseTexts implements PurchaseTextSet {
  const PurchaseTexts();

  String get vehiclePackInfoTitle => '차량팩이 필요한 빠방이에요';
  String vehiclePackInfoSubtitle(String vehicleLabel) {
    return '$vehicleLabel 빠방은 차량팩에 포함되어 있어요.';
  }

  String get vehiclePackInfoUnlockAllMessage => '차량팩을 열면 잠긴 빠방을 모두 사용할 수 있어요.';
  String get vehiclePackInfoGuardianNote => '구매 관련 화면은 보호자 확인 후에만 열려요.';
  String get vehiclePackInfoContinueButton => '보호자와 계속하기';
  String get vehiclePackInfoCloseButton => '닫기';
  String get parentGateTitle => '보호자 확인';
  String get parentGateSubtitle => '구매 화면은 보호자만 열 수 있어요. 아래 문제를 풀어 주세요.';
  String parentGateQuestion(int left, int right) => '$left + $right = ?';
  String get parentGateAnswerLabel => '정답';
  String get parentGateContinueButton => '계속';
  String get parentGateErrorMessage => '정답을 다시 확인해 주세요.';
  String get vehiclePackPurchaseTitle => '차량팩 열기';
  String get vehiclePackPurchaseSubtitle =>
      '차량팩은 한 번만 구매하면 잠긴 빠방을 모두 사용할 수 있어요.';
  String get vehiclePackPurchaseLoadingMessage => '차량팩 정보를 불러오는 중이에요.';
  String get vehiclePackPurchaseUnavailableMessage =>
      '지금은 차량팩 정보를 불러올 수 없어요. 잠시 후 다시 시도해 주세요.';
  String get vehiclePackPurchaseButton => '차량팩 열기';
  String get vehiclePackRestoreButton => '구매 복원';
  String get vehiclePackPurchaseInProgressMessage => '스토어에서 구매를 진행하고 있어요.';
  String get vehiclePackPendingMessage => '구매 승인을 기다리고 있어요.';
  String get vehiclePackPurchasedMessage => '차량팩이 열렸어요.';
  String get vehiclePackRestoredMessage => '차량팩 구매를 복원했어요.';
  String get vehiclePackCanceledMessage => '구매가 취소되었어요.';
  String get vehiclePackErrorMessage => '구매를 완료하지 못했어요. 다시 시도해 주세요.';
  String vehiclePackPriceLabel(String price) => '가격 $price';
}
