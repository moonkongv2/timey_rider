// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaUserGuideTexts implements UserGuideTextSet {
  const JaUserGuideTexts();

  String get title => '保護者ガイド';
  String get subtitle => '活動ミッション、応援動画、ステッカーのルールを確認できます。';
  String get introTitle => '保護者ガイド';
  String get introBody =>
      'ライドを始める前に、Timey Riderの活動ミッションとアプリのルールを確認するためのガイドです。毎日のルーティンを支える保護者向けです。';
  String get basicFlowTitle => startMissionTitle;
  String get markersTitle => courseMarkersTitle;
  String get motivationTitle => '応援動画';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => '保護者向けヒント';

  String get whatIsTimeyRiderTitle => 'Timey Riderとは？';
  List<String> get whatIsTimeyRiderItems => const [
    'Timey Riderは、歯みがき、読書、片づけ、遊び時間などのルーティンを小さなライドミッションに変えます。',
    'お子さまはのりものを選び、設定したタイマー時間に沿ってコースを進みます。',
    '最後に、完了確認、時間終了、保護者確認などの完了モードに応じて活動が記録されます。',
  ];

  String get startMissionTitle => '活動ミッションを始める';
  List<String> get startMissionItems => const [
    'お子さまの名前を設定したら、ホーム画面でのりものを選びます。',
    'ホームでタイマーを作るを押し、ミッション、マーカー、時間を選びます。',
    '用意されたミッションに合わないルーティンでは、同じ流れの中で「その他」を使います。',
    'タイマー中に一時停止しても失敗ではありません。必要なときにミッションを再開できます。',
  ];

  String get courseMarkersTitle => 'コースマーカー';
  List<String> get courseMarkersItems => const [
    'コースマーカーは、活動中に表示される小さな目印です。',
    'オフ: コース上にマーカーを表示しません。',
    '自動: 選んだ活動に合う絵マーカーをプレビューして使用します。',
    '選ぶ: 開始前に絵マーカーを最大5個まで選べます。',
    '活動記録に保存されるのは、手動で選んだ絵マーカーだけです。',
    'マーカーは完了判定やステッカーの結果を決めるものではありません。',
  ];

  List<String> get motivationItems => const [
    '応援動画は、タイマー中に流れる短い励まし動画です。',
    'ステッカーや結果を決めるものではありません。',
    '短いタイマーでは、重なりを避けるために一部の区切りをスキップすることがあります。',
    '長いタイマーや間隔を指定するモードでは、時間に合わせて表示されることがあります。',
    '間隔は3分、5分、10分から選べます。',
    '音がオフの場合、動画だけが表示され、音声は再生されないことがあります。',
  ];

  String get completionTitle => '完了とステッカー';
  List<String> get completionItems => const [
    '活動が終わったことを確認すると、完了として記録されます。',
    'タイマーが終わったら一緒に確認し、ステッカーをもらうか選びます。',
    '「ステッカーをもらう」を選ぶと、選択中のステッカーを受け取れます。',
    '「今回はステッカーなし」を選ぶと、記録を保存し、次のタイマー選びの手がかりにできます。',
    'お子さま向けの結果表示は、厳しい失敗の言葉ではなく、次の挑戦につながる言い方にしています。',
  ];

  String get historyRewardsTitle => '活動記録とごほうび目標';
  List<String> get historyRewardsItems => const [
    '活動記録には、活動名、目標時間、実際の時間、完了状況が表示されます。',
    'もらったステッカーや手動で選んだ絵マーカーが、記録と一緒に表示されることがあります。',
    'もらったステッカーは、ステッカーコレクション画面に集まります。',
    '有効なごほうび目標がある場合、受け取ったステッカーで目標の枠を埋められます。',
  ];

  String get exitResumeTitle => 'タイマー中の退出と再開';
  List<String> get exitResumeItems => const [
    'タイマー中に戻る操作をすると、先に確認が表示されます。',
    '一時停止は失敗ではありません。短い休憩のあとでミッションを続けられます。',
    '進行中のタイマーが保存されている場合、ホーム画面に進行中カードが表示されることがあります。表示されたら、そのカードから再開またはキャンセルできます。',
  ];

  List<String> get guardianTipsItems => const [
    'ステッカーだけでなく、まずルーティンに取り組んだことをほめてください。',
    '目標を短くしすぎず、お子さまに合うペースで標準のタイマー時間を設定してください。',
    'もう少し時間が必要だった結果は、罰ではなく次の挑戦のメモとして扱ってください。',
  ];
}
