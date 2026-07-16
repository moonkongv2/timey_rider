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
    'Eles não definem a conclusão da atividade nem os adesivos recebidos.',
  ];
  List<String> get helpBulletItems => const [
    'Auto: o app mostra uma prévia e usa marcadores com imagens que combinam com a atividade escolhida.',
    'Escolher: selecione até 5 marcadores com imagens antes de começar.',
    'Apenas os marcadores escolhidos manualmente são salvos nos registros de atividade.',
  ];
  String get automaticStartButton => 'Começar automaticamente';
  String get selectedStartButton => 'Começar com marcadores';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selecionados';
  }
}
