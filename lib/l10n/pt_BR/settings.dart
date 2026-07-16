// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrSettingsTexts implements SettingsTextSet {
  const PtBrSettingsTexts();

  String get title => 'Configurações';
  String get showRemainingTime => 'Show remaining time';
  String get soundEnabled => 'Efeitos sonoros';
  String get motivationVideoEnabled => 'Vídeos de incentivo';
  String get motivationVideoCustomInterval => 'Use custom video interval';
  String get motivationVideoInterval => 'Motivation video interval';
  String get motivationVideoHelpTitle => 'Motivation video guide';
  String get motivationVideoHelpSummary =>
      'Os vídeos de incentivo são clipes curtos durante o timer.';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    'Os vídeos de incentivo são clipes curtos que podem aparecer durante o timer.',
    'They do not decide stickers or results.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    'Short timers may skip some milestones so clips do not overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'Custom intervals can be set to 3, 5, or 10 minutes.',
    'Sound effects and video display settings can behave separately.',
    'The app spaces videos out so they do not overlap too frequently.',
  ];
  String get keepScreenAwake => 'Manter tela ligada';
  String get savedOnlySubtitle => 'Turns sounds during the timer on or off.';
  String get keepScreenAwakeSubtitle => 'Applies while the timer is running.';
  String get markerModeTitle => 'Marcadores da rota';
  String get markerModeOff => 'Desligado';
  String get markerModeManual => 'Escolher';
  String get markerModeActivityDefault => 'Auto';
  String get markerModeDescription =>
      'Auto previews and uses picture markers that fit the activity. Only manually chosen picture markers are saved to activity records.';
  String get vehicleSelection => 'Escolher veículo';
  String get childNameTitle => 'Nome da criança';
  String get childNameFieldLabel => 'Nome';
  String get childNameSetupTitle => 'Quem vai pilotar hoje?';
  String get childNameSetupSubtitle => 'Primeiro, informe o nome da criança.';
  String get saveChildName => 'Salvar nome';
  String get childNameRequiredMessage => 'Informe o nome da criança.';
  String get childNameSavedMessage => 'Nome salvo.';
  String get avatarSettingsTitle => 'Rider image settings';
  String get avatarDefaultState => 'Using default image';
  String get avatarCustomState => 'Using custom rider';
  String get avatarSettingsButton => 'Open rider image settings';
  String get vehiclePackSettingsTitle => 'Pacote de veículos';
  String get vehiclePackLockedState => 'Locked vehicles available';
  String get vehiclePackUnlockedState => 'Vehicle pack unlocked';
  String get vehiclePackSettingsDescription =>
      'The vehicle pack unlocks all locked vehicles. Purchase and restore options open after a parent check.';
  String get vehiclePackManageButton => 'View vehicle pack';
  String get vehiclePackRestoreButton => 'Restaurar compra';

  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes min';
}
