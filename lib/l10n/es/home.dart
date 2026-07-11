// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class EsHomeTexts implements HomeTextSet {
  const EsHomeTexts();

  String get subtitle => '¿Listos para la rutina de hoy?';
  String get heroMissionTitle => 'Misión de hoy';
  String get heroMissionSubtitle => 'Tu rider espera una llegada divertida';
  String get todayVehicleTitle => 'Vehículo de hoy';
  String get vehiclePickerTitle => 'Elegir vehículo';
  String get vehicleChangeButton => 'Cambiar';
  String get morningCourse => 'Viaje de 15 min';
  String get morningCourseSubtitle => 'Un calentamiento suave';
  String get slowCourse => 'Viaje de 35 min';
  String get slowCourseSubtitle => 'Avanza con calma hasta la meta';
  String get quickCourseTitle => 'Otras actividades';
  String get activityQuickStartTitle => 'Misión de hoy';
  String get customStartButton => 'Iniciar viaje personalizado';
  String get customSheetTitle => 'Tiempo personalizado';
  String get customTimerTitle => 'Otra';
  String get timerBuilderButton => 'Crear temporizador';
  String get timerBuilderSubtitle =>
      'Elige una misión, marcadores y tiempo antes de empezar.';
  String get timerBuilderSheetTitle => 'Crear temporizador';
  String get timerBuilderActivityStepTitle => '1. Misión';
  String get timerBuilderMarkerStepTitle => '2. Marcadores';
  String get timerBuilderAutomaticMarkerOption => 'Auto';
  String get timerBuilderManualMarkerOption => 'Elegir';
  String get timerBuilderRecentPresetTitle => 'Ajuste reciente';
  String get timerBuilderRecentPresetApplyButton => 'Aplicar';
  String get timerBuilderSavedPresetTitle => 'Temporizadores guardados';
  String get timerBuilderSavePresetButton => 'Guardar';
  String get timerBuilderSavedPresetMessage => 'Guardado.';
  String get timerBuilderSavedPresetFullMessage =>
      'Guardado. Los temporizadores antiguos se borran automáticamente.';
  String get timerBuilderSavedPresetLimitHint =>
      'Los nuevos guardados reemplazan el temporizador más antiguo.';
  String get timerBuilderDeletePresetTooltip => 'Eliminar';
  String get timerBuilderFavoritePresetTooltip => 'Mostrar en Inicio';
  String get timerBuilderUnfavoritePresetTooltip => 'Ocultar de Inicio';
  String get timerBuilderFavoritePresetLimitMessage =>
      'Se pueden mostrar hasta 3 temporizadores en Inicio.';
  String get timerBuilderCustomNameDialogTitle => 'Nombre del temporizador';
  String get timerBuilderCustomNameFieldLabel => 'Nombre';
  String get timerBuilderUseOtherNameButton => 'Guardar como Otra';
  String get timerBuilderTimeStepTitle => '3. Tiempo';
  String get timerBuilderStartButton => 'Empezar';
  String get timerBuilderSelectedMarkerEmpty => 'Elige de 1 a 5 marcadores.';
  String get activitySummaryLabel => 'Misiones';
  String get stickerKindSummaryLabel => 'Tipos de vehículo';
  String get stickerSummaryLabel => 'Pegatinas';
  String get noActivityHistory => 'Aún no hay historial.';
  String get openStickerCollection => 'Ver colección de pegatinas';
  String get avatarCtaSubtitle => 'Añade la cara de tu peque al viaje.';
  String get avatarCtaButton => 'Crear';
  String get avatarCtaEditButton => 'Editar';
  String get avatarCtaCreateSemantics => 'Crear imagen del rider';
  String get avatarCtaEditSemantics => 'Editar imagen del rider';
  String get avatarInlineDefaultState => 'Usando cara predeterminada';
  String get avatarInlineCustomState => 'Rider personalizado listo';
  String get activeTimerTitle => 'Hay un temporizador en marcha';
  String get activeTimerResumeButton => 'Continuar';
  String get activeTimerCancelButton => 'Cancelar temporizador';
  String get activeTimerCancelDialogTitle =>
      '¿Cancelar el temporizador en marcha?';
  String get activeTimerCancelDialogMessage =>
      'Este temporizador de actividad no se guardará en el historial.';
  String get activeTimerNewTimerDialogTitle =>
      'Ya hay un temporizador en marcha';
  String get activeTimerNewTimerDialogMessage =>
      'Si empiezas uno nuevo, se cancelará el actual.';
  String get activeTimerStartNewButton => 'Empezar nuevo';
  String get activeTimerArrivedSubtitle => 'El tiempo terminó';

  String recentCustomMinutes(int minutes) => 'Reciente $minutes min';
  String minuteLabel(int minutes) => '$minutes min';
  String timerBuilderSavedPresetCount(int count, int maxCount) {
    return '$count/$maxCount';
  }

  String activeTimerSubtitle(String remainingTime) => '$remainingTime restante';
  String normalCourse(int minutes) => 'Viaje normal de $minutes min';
  String alternateCourse(int minutes) => 'Viaje de $minutes min';
  String alternateCourseSubtitle(int minutes) {
    return switch (minutes) {
      15 => 'Un calentamiento suave',
      25 => 'Un ritmo constante para cada día',
      35 => 'Avanza con calma hasta la meta',
      _ => 'Viaja por $minutes min',
    };
  }

  String progressTitle(String childName) =>
      'Historial de actividades de $childName';
  String activityCount(int count) => '$count';
  String stickerKindCount(int count) => '$count';
  String stickerCount(int count) => '$count';
  String recentActivitySummary(
    String actualDuration,
    ActivityCompletionStatus completionStatus,
  ) {
    final status = switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Completado',
      ActivityCompletionStatus.timeEnded => 'Tiempo terminado',
      ActivityCompletionStatus.needsMoreTime => 'Necesita más tiempo',
      ActivityCompletionStatus.canceled => 'Cancelado',
    };
    return 'Actividad reciente $actualDuration · $status';
  }
}
