// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaAvatarSetupTexts implements AvatarSetupTextSet {
  const JaAvatarSetupTexts();

  String get title => 'お子さまのライダーを作る';
  String get intro => 'Timey Rider用のライダー画像を作り、完成した画像をここで選びます。';
  String get selectedVehicleTitle => '選択中ののりもの';
  String get currentAvatarModeTitle => 'ライダー画像モード';
  String get defaultImageMode => '標準画像を使う';
  String get customAvatarMode => 'カスタムライダーを使う';
  String get copyPromptMessage => 'プロンプトをコピーしました。外部AIサービスに貼り付けてください。';
  String get avatarSaveFailureMessage => 'ライダー画像を保存できませんでした。';
  String get avatarSavedMessage => 'ライダーを保存しました。';
  String get defaultImageSavedMessage => '標準画像に切り替えました。';
  String get missingAvatarWarning => 'ライダー画像が見つかりません。標準画像を表示します。';
  String get vehicleSelectionTitle => 'このライダーののりもの';
  String get vehicleSelectionSubtitle => 'プロンプト参考';
  String get compositePreviewTitle => 'ライダープレビュー';
  String get compositePreviewSubtitle => 'この見た目をTimey Riderで使いますか？';
  String get defaultPreviewTitle => '標準画像プレビュー';
  String get useDefaultImageButton => '標準画像を使う';
  String get adjustmentTitle => 'ライダー位置を調整';
  String get faceSizeLabel => '顔の大きさ';
  String get horizontalPositionLabel => '横位置';
  String get verticalPositionLabel => '縦位置';
  String get rotationLabel => '傾き';
  String get resetPositionButton => '位置をリセット';
  String get confirmAvatarButton => 'このライダーを使う';
  String get guideTitle => 'ライダー画像ガイド';
  String get guideIntro =>
      'このアプリ内では顔の切り抜きは行いません。下の方法で、のりものに合わせるライダー画像を準備してください。';
  String get promptCopyTitle => 'ライダー画像プロンプト（例）';
  String get promptHelperText =>
      'AIサービスを使う場合は、下ののりもの別プロンプトをコピーして外部AIサービスに貼り付けてください。';
  String get promptGuideHint => '下の例文をコピーして、AIサービスに貼り付けてください。';
  String get promptExpandLabel => 'プロンプトを開く';
  String get promptCollapseLabel => 'プロンプトを閉じる';
  String get promptToggleSemanticLabel => 'ライダー画像プロンプトを開閉';
  String get copyPromptButton => 'プロンプトをコピー';
  String get uploadTitle => 'ライダー画像を取り込む';
  String get uploadInstructions =>
      '写真アプリや外部AIサービスで作った正方形のライダー画像を選んでください。\n'
      "お子さまの顔が透明背景の中央にある画像が最もきれいに合います。";
  String get uploadingButton => '取り込み中';
  String get reuploadButton => 'もう一度選ぶ';
  String get uploadButton => 'ライダー画像を選ぶ';
  String get selectedImageFallback => '選択したライダー画像';
  String get privacyNote =>
      "このアプリ自体はAI画像を作成せず、お子さまの写真をアップロードしません。\n"
      'この端末にある完成済みのライダー画像を選んでください。Timey Riderは画像を端末内に保存し、サーバーへ送信しません。\n'
      '外部サービスを使う前に、写真とプライバシーの扱いを確認してください。';

  String get guidePopupTitle => 'お子さまのライダーを作る';
  String get guideReplayTooltip => 'ガイドをもう一度見る';
  String get guidePopupMethodTitle => '📸 ライダー画像の準備方法';
  String get guidePopupMethodIntro =>
      'このアプリには顔を切り抜く機能はありません。上の例のように、のりものに載せるお子さまの顔画像を保護者の方が準備してください。';
  String get guidePopupMethod1Title => '1. スマホの写真アプリを使う';
  String get guidePopupMethod1Body =>
      'GalaxyやiPhoneの標準写真アプリの「背景切り抜き」機能を使って、お子さまの顔だけを切り抜き、正方形に近い形で保存してください。';
  String get guidePopupMethod2Title => '2. AIサービスを使う';
  String get guidePopupMethod2Body => '外部AIサービスで作成した正方形のライダー画像を選んでください。';
  String get guidePopupPrivacyTitle => '🔒 なぜアプリ内で自動処理しないの？';
  String get guidePopupPrivacyBody =>
      'アプリ内で顔を正確に切り抜いたり変換したりするには、技術的に元の写真を外部サーバーに送信する必要があります。お子さまの写真とプライバシーを厳格に守るため、サーバーへの送信を一切行わず、保護者の方にライダー画像をご準備いただいています。';
  String get guidePopupSafetyTitle => '🛡️ プライバシーを守ります';
  String get guidePopupSafetyBody =>
      '準備して追加したライダー画像は、この端末内だけに保存されます。外部サーバーへ送信されないため、個人情報を守れます。';
  String get guidePopupConfirmButton => '確認';
}
