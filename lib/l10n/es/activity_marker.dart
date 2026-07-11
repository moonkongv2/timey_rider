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
    'They do not decide completion or sticker results.',
  ];
  List<String> get helpBulletItems => const [
    'Auto: the app previews and uses picture markers that fit the selected activity.',
    'Choose: pick up to 5 picture markers before starting.',
    'Only manually chosen picture markers are saved to activity records.',
  ];
  String get automaticStartButton => 'Empezar automáticamente';
  String get selectedStartButton => 'Empezar con marcadores';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selected';
  }
}
