// ignore_for_file: annotate_overrides

import '../text_sets.dart';
import '../../models/activity_completion_status.dart';

class EsActivityHistoryTexts implements ActivityHistoryTextSet {
  const EsActivityHistoryTexts();

  String get title => 'Registros de actividad';
  String get emptyTitle => 'Aún no hay registros.';
  String get emptyBody => 'Aquí aparecerán las misiones completadas.';
  String get helpTitle => 'Guía del historial';
  List<String> get helpBulletItems => const [
    'Activity history shows the mission, target time, actual time, completion status, and earned stickers.',
    'Manually chosen picture markers appear when they were saved with the activity.',
    'Auto-selected markers appear on the road only and are not saved in history.',
    'Records without a sticker show No sticker this time.',
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
      'Only the record will be removed. Earned stickers will stay.';
  String get deleteRecordConfirmLabel => 'Eliminar';
  String get deleteRecordSuccessMessage => 'Registro eliminado.';

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

  String overrunTime(String duration) => 'Over +$duration';
}
