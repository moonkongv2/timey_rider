// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnActivityMarkerTexts implements ActivityMarkerTextSet {
  const EnActivityMarkerTexts();

  String get title => 'Choose course markers';
  String get subtitle => 'Chosen markers appear along the route.';
  String get helpLinkLabel => 'Course marker guide';
  String get helpTitle => 'Course marker guide';
  List<String> get helpBodyParagraphs => const [
    'Course markers are small route goals shown during an activity.',
    'They do not decide completion or vehicle sticker results.',
  ];
  List<String> get helpBulletItems => const [
    'Auto: the app previews and uses picture markers that fit the selected activity.',
    'Choose: pick up to 5 picture markers before starting.',
    'Only manually chosen picture markers are saved to activity records.',
  ];
  String get automaticStartButton => 'Start automatically';
  String get selectedStartButton => 'Start with markers';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selected';
  }
}
