// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaSettingsTexts implements SettingsTextSet {
  const JaSettingsTexts();

  String get title => '設定';
  String get showRemainingTime => '残り時間を表示';
  String get soundEnabled => '効果音';
  String get motivationVideoEnabled => '応援動画';
  String get motivationVideoCustomInterval => '動画間隔を自分で設定';
  String get motivationVideoInterval => '応援動画の間隔';
  String get motivationVideoHelpTitle => '応援動画ガイド';
  String get motivationVideoHelpSummary => '応援動画は、タイマー中に流れる短い励まし動画です。';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    '応援動画は、タイマー中に表示される短い励まし動画です。',
    'ステッカーや結果を決めるものではありません。',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    '短いタイマーでは、動画が重ならないように一部の区切りをスキップすることがあります。',
    '長いタイマーや間隔を指定するモードでは、時間に合わせて表示されることがあります。',
    'カスタム間隔は3分、5分、10分から選べます。',
    '効果音と動画表示の設定は別々に動作します。',
    '動画が頻繁に重なって出ないよう、アプリが間隔を空けます。',
  ];
  String get keepScreenAwake => '画面をオンのままにする';
  String get savedOnlySubtitle => 'タイマー中の音をオン/オフします。';
  String get keepScreenAwakeSubtitle => 'タイマー実行中に適用されます。';
  String get markerModeTitle => 'コースマーカー';
  String get markerModeOff => 'オフ';
  String get markerModeManual => '選ぶ';
  String get markerModeActivityDefault => '自動';
  String get markerModeDescription =>
      '自動では、活動に合う絵マーカーをプレビューして使用します。活動記録に保存されるのは、手動で選んだ絵マーカーだけです。';
  String get vehicleSelection => 'のりものを選ぶ';
  String get childNameTitle => 'お子さまの名前';
  String get childNameFieldLabel => '名前';
  String get childNameSetupTitle => '今日はだれが乗りますか？';
  String get childNameSetupSubtitle => 'まずお子さまの名前を入力してください。';
  String get saveChildName => '名前を保存';
  String get childNameRequiredMessage => 'お子さまの名前を入力してください。';
  String get childNameSavedMessage => '名前を保存しました。';
  String get avatarSettingsTitle => 'ライダー画像設定';
  String get avatarDefaultState => '標準画像を使用中';
  String get avatarCustomState => 'カスタムライダーを使用中';
  String get avatarSettingsButton => 'ライダー画像設定を開く';
  String get vehiclePackSettingsTitle => 'のりものパック';
  String get vehiclePackLockedState => 'ロック中ののりものがあります';
  String get vehiclePackUnlockedState => 'のりものパック使用中';
  String get vehiclePackSettingsDescription =>
      'のりものパックを使うと、ロック中ののりものをすべて使えるようになります。購入と復元の操作は、保護者確認のあとに開きます。';
  String get vehiclePackManageButton => 'のりものパックを見る';
  String get vehiclePackRestoreButton => '購入を復元';
  String get helpAndSupportSectionTitle => 'ヘルプとサポート';
  String get userGuideSettingsItemTitle => '使い方ガイド';
  String get restorePurchaseSettingsItemTitle => '購入を復元';
  String get contactSupportSettingsItemTitle => 'サポートに問い合わせる';
  String get aboutSectionTitle => '情報';
  String get privacyPolicySettingsItemTitle => 'プライバシーポリシー';
  String get appVersionSettingsItemTitle => 'アプリバージョン';
  String get externalLinkOpenErrorMessage => 'リンクを開けませんでした。';

  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes min';
}
