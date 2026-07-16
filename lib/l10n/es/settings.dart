// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsSettingsTexts implements SettingsTextSet {
  const EsSettingsTexts();

  String get title => 'Ajustes';
  String get showRemainingTime => 'Mostrar tiempo restante';
  String get soundEnabled => 'Efectos de sonido';
  String get motivationVideoEnabled => 'Videos de ánimo';
  String get motivationVideoCustomInterval =>
      'Intervalo de video personalizado';
  String get motivationVideoInterval => 'Intervalo de videos de ánimo';
  String get motivationVideoHelpTitle => 'Guía de videos de ánimo';
  String get motivationVideoHelpSummary =>
      'Los videos de ánimo son clips breves de apoyo durante el temporizador.';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    'Los videos de ánimo son clips breves que pueden aparecer durante el temporizador.',
    'No determinan las pegatinas ni los resultados.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    'En temporizadores cortos, algunos hitos pueden omitirse para que los clips no se superpongan.',
    'Los temporizadores más largos o el modo de intervalo personalizado pueden usar una programación por tiempo.',
    'Los intervalos personalizados pueden ser de 3, 5 o 10 minutos.',
    'Los efectos de sonido y la visualización de videos se pueden configurar por separado.',
    'La app separa los videos para que no aparezcan demasiado seguido.',
  ];
  String get keepScreenAwake => 'Mantener pantalla encendida';
  String get savedOnlySubtitle =>
      'Activa o desactiva los sonidos durante el temporizador.';
  String get keepScreenAwakeSubtitle =>
      'Se aplica mientras el temporizador está en marcha.';
  String get markerModeTitle => 'Marcadores de ruta';
  String get markerModeOff => 'No';
  String get markerModeManual => 'Elegir';
  String get markerModeActivityDefault => 'Auto';
  String get markerModeDescription =>
      'Auto muestra una vista previa y usa marcadores con imágenes que encajan con la actividad. Solo los marcadores elegidos manualmente se guardan en los registros de actividad.';
  String get vehicleSelection => 'Elegir vehículo';
  String get childNameTitle => 'Nombre del niño';
  String get childNameFieldLabel => 'Nombre';
  String get childNameSetupTitle => '¿Quién va a montar hoy?';
  String get childNameSetupSubtitle => 'Primero escribe el nombre de tu hijo.';
  String get saveChildName => 'Guardar nombre';
  String get childNameRequiredMessage => 'Escribe el nombre de tu hijo.';
  String get childNameSavedMessage => 'Nombre guardado.';
  String get avatarSettingsTitle => 'Ajustes de imagen del piloto';
  String get avatarDefaultState => 'Usando imagen predeterminada';
  String get avatarCustomState => 'Usando piloto personalizado';
  String get avatarSettingsButton => 'Abrir ajustes de imagen del piloto';
  String get vehiclePackSettingsTitle => 'Pack de vehículos';
  String get vehiclePackLockedState => 'Vehículos bloqueados disponibles';
  String get vehiclePackUnlockedState => 'Pack de vehículos desbloqueado';
  String get vehiclePackSettingsDescription =>
      'El pack de vehículos desbloquea todos los vehículos bloqueados. Las opciones de compra y restauración se abren después de una comprobación para padres.';
  String get vehiclePackManageButton => 'Ver pack de vehículos';
  String get vehiclePackRestoreButton => 'Restaurar compra';

  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes min';
}
