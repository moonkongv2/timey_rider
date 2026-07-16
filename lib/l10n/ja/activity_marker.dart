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
    '完了判定やステッカーの結果を決めるものではありません。',
  ];
  List<String> get helpBulletItems => const [
    '自動: 選んだ活動に合う絵マーカーをプレビューして使用します。',
    '選ぶ: 開始前に絵マーカーを最大5個まで選べます。',
    '活動記録に保存されるのは、手動で選んだ絵マーカーだけです。',
  ];
  String get automaticStartButton => '自動で始める';
  String get selectedStartButton => 'マーカー付きで始める';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount個選択中';
  }
}
