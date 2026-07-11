// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrTimerTexts implements TimerTextSet {
  const PtBrTimerTexts();

  String get missionTitle => 'Missão de hoje';
  String get progressJustStarted => 'Partiu!';
  String get progressGoingWell => 'Você está indo muito bem!';
  String get progressPastHalfway => 'Você já avançou bastante!';
  String get progressAlmostThere => 'Quase lá!';
  String get progressArrived => 'Você chegou!';
  String completeDialogTitle(String activityLabel) =>
      'Você terminou $activityLabel?';
  String completeDialogMessage(String activityLabel) =>
      'Concluir esta missão de $activityLabel?';
  String get exitDialogTitle => 'Sair desta corrida?';
  String get exitDialogMessage => 'Se sair agora, esta missão não será salva.';
  String get exitDialogCancelButton => 'Continuar';
  String get exitDialogConfirmButton => 'Sair';
  String get pauseButton => 'Pausar';
  String completeActivityButton(String activityId) {
    return switch (activityId) {
      'brushing' => 'Escovação pronta',
      'reading' => 'Leitura pronta',
      'cleanup' => 'Arrumação pronta',
      'play' => 'Brincadeira pronta',
      _ => 'Missão concluída',
    };
  }

  String get remainingTimeLabel => 'Tempo restante';
  String get pausedTimeLabel => 'Pausa';
  String get arrivedTimeLabel => 'Chegou';
  String get idleTimeLabel => 'Preparando';
  String get pausedProgressMessage => 'Fazendo uma pequena pausa';
  String get arrivedProgressMessage => 'Chegou!';
  String get idleProgressMessage => 'Preparando';
  String get finishDriveProgressMessage => 'Indo para a chegada!';
  String get finishDriveTimeLabel => 'Finalizando';
  String get previewReady => 'Preparar... 🚦';
  String get previewGo => 'Vai! 🌟';
  String get arrivalConfirmButton => 'Ver chegada';
  String get arrivalResultButton => 'Ver resultado';

  String arrivalDialogMessage(String vehicleLabel, String activityLabel) {
    return 'O ${vehicleLabel.toLowerCase()} chegou. Você terminou a missão?';
  }

  String arrivalReachedMessage(String vehicleLabel) {
    return 'O ${vehicleLabel.toLowerCase()} chegou.';
  }

  String remainingTime(String remaining) => 'Tempo restante $remaining';
  String remainingTimeSemanticLabel(String label, String remaining) {
    return '$label, faltam $remaining';
  }
}
