// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsActivityMarkerTexts implements ActivityMarkerTextSet {
  const EsActivityMarkerTexts();

  String get title => 'Elige marcadores de ruta';
  String get subtitle => 'Los marcadores elegidos aparecen en la ruta.';
  String get helpLinkLabel => 'Guía de marcadores';
  String get helpTitle => 'Guía de marcadores';
  List<String> get helpBodyParagraphs => const [
    'Los marcadores de ruta son pequeñas metas visuales durante una actividad.',
    'No determinan si la actividad se completa ni las pegatinas obtenidas.',
  ];
  List<String> get helpBulletItems => const [
    'Auto: la app muestra una vista previa y usa marcadores con imágenes que encajan con la actividad elegida.',
    'Elegir: selecciona hasta 5 marcadores con imágenes antes de empezar.',
    'Solo los marcadores elegidos manualmente se guardan en los registros de actividad.',
  ];
  String get automaticStartButton => 'Empezar automáticamente';
  String get selectedStartButton => 'Empezar con marcadores';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount seleccionados';
  }
}
