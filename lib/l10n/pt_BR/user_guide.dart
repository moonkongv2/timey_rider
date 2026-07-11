// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrUserGuideTexts implements UserGuideTextSet {
  const PtBrUserGuideTexts();

  String get title => 'Guia para responsáveis';
  String get subtitle =>
      'Revise missões, vídeos de incentivo e regras dos adesivos.';
  String get introTitle => 'Guia para responsáveis';
  String get introBody =>
      'Use este guia para entender as missões e regras do Timey Rider antes de começar. Ele é feito para responsáveis que ajudam nas rotinas diárias.';
  String get basicFlowTitle => startMissionTitle;
  String get markersTitle => courseMarkersTitle;
  String get motivationTitle => 'Vídeos de incentivo';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => 'Dicas para responsáveis';

  String get whatIsTimeyRiderTitle => 'O que é o Timey Rider?';
  List<String> get whatIsTimeyRiderItems => const [
    'Timey Rider turns routines like brushing teeth, reading, cleanup, and play time into small riding missions.',
    'Children choose a vehicle and follow the course for the set timer duration.',
    'At the end, each activity is recorded through its completion mode: confirm done, time ended, or parent check.',
  ];

  String get startMissionTitle => 'Iniciar uma missão';
  List<String> get startMissionItems => const [
    'After setting the child name, choose a vehicle from the home screen.',
    'Toque em Criar timer no Início e escolha missão, marcadores e duração.',
    'Use Other in the same flow when the routine does not match a preset mission.',
    'Pausing during the timer is not a failure; the mission can resume when needed.',
  ];

  String get courseMarkersTitle => 'Marcadores da rota';
  List<String> get courseMarkersItems => const [
    'Os marcadores da rota são pequenas metas visuais durante uma atividade.',
    'Off: no markers are shown on the road.',
    'Auto: the app previews and uses picture markers that fit the selected activity.',
    'Choose: pick up to 5 picture markers before starting.',
    'Only manually chosen picture markers are saved to activity records.',
    'Markers do not decide completion or sticker results.',
  ];

  List<String> get motivationItems => const [
    'Os vídeos de incentivo são clipes curtos durante o timer.',
    'They do not decide stickers or results.',
    'Short timers may skip some milestones to avoid overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'You can choose 3, 5, or 10 minute intervals.',
    'If sound is off, the video may appear without voice playback.',
  ];

  String get completionTitle => 'Conclusão e adesivos';
  List<String> get completionItems => const [
    'When you confirm the activity is done, it is recorded as complete.',
    'After the timer ends, check together and choose whether to get a sticker.',
    'Choose Ganhar adesivo to receive the selected sticker.',
    'Choose Sem adesivo desta vez to save the record and guide the next timer choice.',
    'The child-facing result keeps a next-try tone instead of harsh failure wording.',
  ];

  String get historyRewardsTitle => 'Histórico e metas de recompensa';
  List<String> get historyRewardsItems => const [
    'Activity history shows activity name, target time, actual time, and completion status.',
    'Earned stickers and manually chosen picture markers can appear with the record.',
    'Earned stickers collect in the sticker collection screen.',
    'If reward goals are active, received stickers can fill goal slots.',
  ];

  String get exitResumeTitle => 'Sair e continuar durante um timer';
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
