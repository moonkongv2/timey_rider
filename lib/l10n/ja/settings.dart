// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaSettingsTexts implements SettingsTextSet {
  const JaSettingsTexts();

  String get title => '設定';
  String get showRemainingTime => 'Show remaining time';
  String get soundEnabled => '効果音';
  String get motivationVideoEnabled => '応援動画';
  String get motivationVideoCustomInterval => '動画間隔を自分で設定';
  String get motivationVideoInterval => '応援動画の間隔';
  String get motivationVideoHelpTitle => '応援動画ガイド';
  String get motivationVideoHelpSummary => '応援動画は、タイマー中に流れる短い励まし動画です。';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    '応援動画は、タイマー中に表示される短い励まし動画です。',
    'They do not decide stickers or results.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    'Short timers may skip some milestones so clips do not overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'Custom intervals can be set to 3, 5, or 10 minutes.',
    'Sound effects and video display settings can behave separately.',
    'The app spaces videos out so they do not overlap too frequently.',
  ];
  String get keepScreenAwake => '画面をオンのままにする';
  String get savedOnlySubtitle => 'タイマー中の音をオン/オフします。';
  String get keepScreenAwakeSubtitle => 'タイマー実行中に適用されます。';
  String get markerModeTitle => 'コースマーカー';
  String get markerModeOff => 'オフ';
  String get markerModeManual => '選ぶ';
  String get markerModeActivityDefault => '自動';
  String get markerModeDescription =>
      'Auto previews and uses picture markers that fit the activity. Only manually chosen picture markers are saved to activity records.';
  String get vehicleSelection => 'のりものを選ぶ';
  String get childNameTitle => 'お子さまの名前';
  String get childNameFieldLabel => '名前';
  String get childNameSetupTitle => '今日はだれが乗りますか？';
  String get childNameSetupSubtitle => 'まずお子さまの名前を入力してください。';
  String get saveChildName => '名前を保存';
  String get childNameRequiredMessage => 'お子さまの名前を入力してください。';
  String get childNameSavedMessage => '名前を保存しました。';
  String get avatarSettingsTitle => 'ライダー画像設定';
  String get avatarDefaultState => 'Using default image';
  String get avatarCustomState => 'Using custom rider';
  String get avatarSettingsButton => 'ライダー画像設定を開く';
  String get vehiclePackSettingsTitle => 'のりものパック';
  String get vehiclePackLockedState => 'ロック中ののりものがあります';
  String get vehiclePackUnlockedState => 'のりものパック使用中';
  String get vehiclePackSettingsDescription =>
      'The vehicle pack unlocks all locked vehicles. Purchase and restore options open after a parent check.';
  String get vehiclePackManageButton => 'のりものパックを見る';
  String get vehiclePackRestoreButton => '購入を復元';

  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes min';
}
