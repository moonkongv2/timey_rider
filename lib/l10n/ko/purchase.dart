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
}
