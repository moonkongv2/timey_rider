// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaPurchaseTexts implements PurchaseTextSet {
  const JaPurchaseTexts();

  String get vehiclePackInfoTitle => 'こののりものはパックに含まれています';
  String vehiclePackInfoSubtitle(String vehicleLabel) {
    return '$vehicleLabelはのりものパックに含まれています。';
  }

  String get vehiclePackInfoUnlockAllMessage => 'のりものパックですべてのロック中ののりものを使えます。';
  String get vehiclePackInfoGuardianNote => '購入オプションは保護者確認のあとに開きます。';
  String get vehiclePackInfoContinueButton => '保護者と続ける';
  String get vehiclePackInfoCloseButton => '閉じる';
  String get parentGateTitle => '保護者確認';
  String get parentGateSubtitle => '購入オプションは保護者だけが開いてください。続けるには簡単な確認に答えてください。';
  String parentGateQuestion(int left, int right) => '$left + $right は？';
  String get parentGateAnswerLabel => '答え';
  String get parentGateContinueButton => '続ける';
  String get parentGateErrorMessage => '答えを確認してもう一度お試しください。';
  String get vehiclePackPurchaseTitle => 'のりものパックをアンロック';
  String get vehiclePackPurchaseSubtitle => '一度の購入ですべてのロック中ののりものを使えます。';
  String get vehiclePackPurchaseLoadingMessage => 'のりものパック情報を読み込み中です。';
  String get vehiclePackPurchaseUnavailableMessage =>
      '現在のりものパック情報を利用できません。あとでお試しください。';
  String get vehiclePackPurchaseButton => 'のりものパックを購入';
  String get vehiclePackRestoreButton => '購入を復元';
  String get vehiclePackPurchaseInProgressMessage => 'ストアで購入処理中です。';
  String get vehiclePackPendingMessage => '購入承認を待っています。';
  String get vehiclePackRestoringMessage => '購入履歴を確認中です。';
  String get vehiclePackRestoreNotFoundMessage => '復元できるのりものパック購入が見つかりませんでした。';
  String get vehiclePackPurchasedMessage => 'のりものパックをアンロックしました。';
  String get vehiclePackRestoredMessage => 'のりものパック購入を復元しました。';
  String get vehiclePackCanceledMessage => '購入をキャンセルしました。';
  String get vehiclePackErrorMessage => '購入を完了できませんでした。もう一度お試しください。';
  String vehiclePackPriceLabel(String price) => '価格 $price';
}
