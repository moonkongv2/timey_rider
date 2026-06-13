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
    'They do not decide completion or sticker results.',
  ];
  List<String> get helpBulletItems => const [
    'Match activity: use markers that fit the selected activity.',
    'Choose: pick up to 5 markers before starting. Chosen markers are saved to activity records.',
    'Random: the app picks markers that fit the activity.',
    'Only manually chosen markers are saved to activity records.',
  ];
  String get randomStartButton => 'Start with random';
  String get selectedStartButton => 'Start with markers';

  String selectedCount(int selectedCount, int maxCount) {
    return '$selectedCount/$maxCount selected';
  }
}
