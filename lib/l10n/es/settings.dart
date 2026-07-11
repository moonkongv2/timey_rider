// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsSettingsTexts implements SettingsTextSet {
  const EsSettingsTexts();

  String get title => 'Ajustes';
  String get showRemainingTime => 'Show remaining time';
  String get soundEnabled => 'Efectos de sonido';
  String get motivationVideoEnabled => 'Videos de ánimo';
  String get motivationVideoCustomInterval => 'Use custom video interval';
  String get motivationVideoInterval => 'Motivation video interval';
  String get motivationVideoHelpTitle => 'Motivation video guide';
  String get motivationVideoHelpSummary =>
      'Los videos de ánimo son clips breves de apoyo durante el temporizador.';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    'Los videos de ánimo son clips breves que pueden aparecer durante el temporizador.',
    'They do not decide stickers or results.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    'Short timers may skip some milestones so clips do not overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'Custom intervals can be set to 3, 5, or 10 minutes.',
    'Sound effects and video display settings can behave separately.',
    'The app spaces videos out so they do not overlap too frequently.',
  ];
  String get keepScreenAwake => 'Mantener pantalla encendida';
  String get savedOnlySubtitle => 'Turns sounds during the timer on or off.';
  String get keepScreenAwakeSubtitle => 'Applies while the timer is running.';
  String get markerModeTitle => 'Marcadores de ruta';
  String get markerModeOff => 'No';
  String get markerModeManual => 'Elegir';
  String get markerModeActivityDefault => 'Auto';
  String get markerModeDescription =>
      'Auto previews and uses picture markers that fit the activity. Only manually chosen picture markers are saved to activity records.';
  String get vehicleSelection => 'Elegir vehículo';
  String get childNameTitle => 'Nombre del niño';
  String get childNameFieldLabel => 'Nombre';
  String get childNameSetupTitle => 'Who is riding today?';
  String get childNameSetupSubtitle => "Enter your child's name first.";
  String get saveChildName => 'Guardar nombre';
  String get childNameRequiredMessage => "Enter your child's name.";
  String get childNameSavedMessage => 'Nombre guardado.';
  String get avatarSettingsTitle => 'Rider image settings';
  String get avatarDefaultState => 'Using default image';
  String get avatarCustomState => 'Using custom rider';
  String get avatarSettingsButton => 'Open rider image settings';
  String get vehiclePackSettingsTitle => 'Pack de vehículos';
  String get vehiclePackLockedState => 'Locked vehicles available';
  String get vehiclePackUnlockedState => 'Vehicle pack unlocked';
  String get vehiclePackSettingsDescription =>
      'The vehicle pack unlocks all locked vehicles. Purchase and restore options open after a parent check.';
  String get vehiclePackManageButton => 'View vehicle pack';
  String get vehiclePackRestoreButton => 'Restaurar compra';

  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes min';
}
