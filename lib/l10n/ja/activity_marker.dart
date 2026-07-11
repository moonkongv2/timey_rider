// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class JaActivityMarkerTexts implements ActivityMarkerTextSet {
  const JaActivityMarkerTexts();

  String get title => 'コースマーカーを選ぶ';
  String get subtitle => '選んだマーカーがコースに表示されます。';
  String get helpLinkLabel => 'コースマーカーガイド';
  String get helpTitle => 'コースマーカーガイド';
  List<String> get helpBodyParagraphs => const [
    'コースマーカーは、活動中に表示される小さな目印です。',
    'They do not decide completion or sticker results.',
  ];
  List<String> get helpBulletItems => const [
    'Auto: the app previews and uses picture markers that fit the selected activity.',
    'Choose: pick up to 5 picture markers before starting.',
    'Only manually chosen picture markers are saved to activity records.',
  ];
  String get automaticStartButton => '自動で始める';
  String get selectedStartButton => 'マーカー付きで始める';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selected';
  }
}
