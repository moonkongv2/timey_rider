// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsTimerTexts implements TimerTextSet {
  const EsTimerTexts();

  String get missionTitle => 'Misión de hoy';
  String get progressJustStarted => '¡Allá vamos!';
  String get progressGoingWell => '¡Lo estás haciendo genial!';
  String get progressPastHalfway => '¡Ya avanzaste mucho!';
  String get progressAlmostThere => '¡Ya casi!';
  String get progressArrived => '¡Llegaste!';
  String completeDialogTitle(String activityLabel) =>
      '¿Terminaste $activityLabel?';
  String completeDialogMessage(String activityLabel) =>
      '¿Terminar esta misión de $activityLabel?';
  String get exitDialogTitle => '¿Salir de este viaje?';
  String get exitDialogMessage => 'Si sales ahora, esta misión no se guardará.';
  String get exitDialogCancelButton => 'Seguir';
  String get exitDialogConfirmButton => 'Salir';
  String get pauseButton => 'Pausa';
  String completeActivityButton(String activityId) {
    return switch (activityId) {
      'brushing' => 'Dientes listos',
      'reading' => 'Lectura lista',
      'cleanup' => 'Orden listo',
      'play' => 'Juego listo',
      _ => 'Misión lista',
    };
  }

  String get remainingTimeLabel => 'Tiempo restante';
  String get pausedTimeLabel => 'Descanso';
  String get arrivedTimeLabel => 'Llegó';
  String get idleTimeLabel => 'Preparándose';
  String get pausedProgressMessage => 'Tomando un pequeño descanso';
  String get arrivedProgressMessage => '¡Llegaste!';
  String get idleProgressMessage => 'Preparándose';
  String get finishDriveProgressMessage => '¡Rumbo a la meta!';
  String get finishDriveTimeLabel => 'Terminando';
  String get previewReady => 'Listos... 🚦';
  String get previewGo => '¡Vamos! 🌟';
  String get arrivalConfirmButton => 'Ver llegada';
  String get arrivalResultButton => 'Ver resultado';

  String arrivalDialogMessage(String vehicleLabel, String activityLabel) {
    return 'El ${vehicleLabel.toLowerCase()} llegó. ¿Terminaste la misión?';
  }

  String arrivalReachedMessage(String vehicleLabel) {
    return 'El ${vehicleLabel.toLowerCase()} llegó.';
  }

  String remainingTime(String remaining) => 'Tiempo restante $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label, quedan $remaining';
  }
}
