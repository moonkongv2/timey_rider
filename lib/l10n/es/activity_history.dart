// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class EsActivityHistoryTexts implements ActivityHistoryTextSet {
  const EsActivityHistoryTexts();

  String get title => 'Registros de actividad';
  String get emptyTitle => 'Aún no hay registros.';
  String get emptyBody => 'Aquí aparecerán las misiones completadas.';
  String get helpTitle => 'Guía del historial';
  List<String> get helpBulletItems => [
    deleteRecordOnlyWarning,
    deleteLinkedRewardsBody,
    'El historial muestra la misión, el tiempo objetivo, el tiempo real, el estado de finalización y las pegatinas ganadas.',
    'Los marcadores con imágenes elegidos manualmente aparecen cuando se guardaron con la actividad.',
    'Los marcadores seleccionados automáticamente solo aparecen en la ruta y no se guardan en el historial.',
    'Los registros sin pegatina muestran Sin pegatina esta vez.',
  ];
  String get targetTimeLabel => 'Objetivo';
  String get actualTimeLabel => 'Real';
  String get overrunTimeLabel => 'Extra';
  String get rewardLabel => 'Pegatinas ganadas';
  String get noRewardLabel => 'Sin pegatina esta vez';
  String get selectedMarkerLabel => 'Marcadores elegidos';
  String get deleteRecordLabel => 'Eliminar registro';
  String get deleteRecordDialogTitle => '¿Eliminar este registro?';
  String get deleteRecordDialogBody =>
      'Solo se eliminará el registro. Las pegatinas ganadas se conservarán.';
  String get deleteRecordConfirmLabel => 'Eliminar';
  String get deleteRecordSuccessMessage => 'Registro eliminado.';

  String get deleteLinkedRewardsLabel =>
      'Eliminar también las pegatinas de esta actividad';
  String get deleteLinkedRewardsBody =>
      'Se eliminan sus pegatinas y las casillas vinculadas de tableros sin usar. Las recompensas que ya no alcancen la meta vuelven a estar en curso. Las recompensas usadas se conservan.';
  String get deleteRecordOnlyLabel => 'Eliminar solo el registro';
  String get deleteWithRewardsLabel => 'Eliminar con pegatinas';
  String get loadFailureMessage =>
      'No se pudo cargar tu progreso. Inténtalo de nuevo.';
  String get storageFailureMessage =>
      'No se pudo completar el guardado. Reintenta para recuperar el estado guardado.';
  String get dataFailureMessage =>
      'Hay un problema con los datos guardados. Si persiste al reintentar, contacta con soporte.';
  String get deletedActivityMessage =>
      'Esta actividad se ha eliminado. No se volverán a entregar sus pegatinas.';
  String get goHomeLabel => 'Ir al inicio';
  String additionalGoals(int count) => '$count más';
  String get deleteRecordOnlyWarning =>
      'Si eliminas solo el registro, ya no podrás eliminar sus pegatinas vinculadas desde esta actividad.';

  String completedStatus(ActivityCompletionStatus completionStatus) {
    return switch (completionStatus) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Completado',
      ActivityCompletionStatus.timeEnded => 'Tiempo terminado',
      ActivityCompletionStatus.needsMoreTime => 'Necesita más tiempo',
      ActivityCompletionStatus.canceled => 'Cancelado',
    };
  }

  String dateLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} $hour:$minute';
  }

  String overrunTime(String duration) => 'Extra +$duration';
}
