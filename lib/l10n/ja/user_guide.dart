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
    'Timey Rider turns routines like brushing teeth, reading, cleanup, and play time into small riding missions.',
    'Children choose a vehicle and follow the course for the set timer duration.',
    'At the end, each activity is recorded through its completion mode: confirm done, time ended, or parent check.',
  ];

  String get startMissionTitle => '活動ミッションを始める';
  List<String> get startMissionItems => const [
    'After setting the child name, choose a vehicle from the home screen.',
    'ホームでタイマーを作るを押し、ミッション、マーカー、時間を選びます。',
    'Use Other in the same flow when the routine does not match a preset mission.',
    'Pausing during the timer is not a failure; the mission can resume when needed.',
  ];

  String get courseMarkersTitle => 'コースマーカー';
  List<String> get courseMarkersItems => const [
    'コースマーカーは、活動中に表示される小さな目印です。',
    'Off: no markers are shown on the road.',
    'Auto: the app previews and uses picture markers that fit the selected activity.',
    'Choose: pick up to 5 picture markers before starting.',
    'Only manually chosen picture markers are saved to activity records.',
    'Markers do not decide completion or sticker results.',
  ];

  List<String> get motivationItems => const [
    '応援動画は、タイマー中に流れる短い励まし動画です。',
    'They do not decide stickers or results.',
    'Short timers may skip some milestones to avoid overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'You can choose 3, 5, or 10 minute intervals.',
    'If sound is off, the video may appear without voice playback.',
  ];

  String get completionTitle => '完了とステッカー';
  List<String> get completionItems => const [
    'When you confirm the activity is done, it is recorded as complete.',
    'After the timer ends, check together and choose whether to get a sticker.',
    'Choose ステッカーをもらう to receive the selected sticker.',
    'Choose 今回はステッカーなし to save the record and guide the next timer choice.',
    'The child-facing result keeps a next-try tone instead of harsh failure wording.',
  ];

  String get historyRewardsTitle => '活動記録とごほうび目標';
  List<String> get historyRewardsItems => const [
    'Activity history shows activity name, target time, actual time, and completion status.',
    'Earned stickers and manually chosen picture markers can appear with the record.',
    'Earned stickers collect in the sticker collection screen.',
    'If reward goals are active, received stickers can fill goal slots.',
  ];

  String get exitResumeTitle => 'タイマー中の退出と再開';
  List<String> get exitResumeItems => const [
    'Using back during a timer asks for confirmation first.',
    'Pausing is not a failure; the mission can continue after a short break.',
    'When an active timer is saved, the home screen may show an in-progress card. Use that card to resume or cancel when it appears.',
  ];

  List<String> get guardianTipsItems => const [
    'Praise the routine attempt first, not only the sticker.',
    'Set the default timer duration to a pace that fits the child instead of making the goal too short.',
    'Treat needs-more-time results as notes for the next try, not as punishment.',
  ];
}
