// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrActivityMarkerTexts implements ActivityMarkerTextSet {
  const PtBrActivityMarkerTexts();

  String get title => 'Escolha marcadores da rota';
  String get subtitle => 'Os marcadores escolhidos aparecem na rota.';
  String get helpLinkLabel => 'Guia de marcadores';
  String get helpTitle => 'Guia de marcadores';
  List<String> get helpBodyParagraphs => const [
    'Os marcadores da rota são pequenas metas visuais durante uma atividade.',
    'They do not decide completion or sticker results.',
  ];
  List<String> get helpBulletItems => const [
    'Auto: the app previews and uses picture markers that fit the selected activity.',
    'Choose: pick up to 5 picture markers before starting.',
    'Only manually chosen picture markers are saved to activity records.',
  ];
  String get automaticStartButton => 'Começar automaticamente';
  String get selectedStartButton => 'Começar com marcadores';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selected';
  }
}
