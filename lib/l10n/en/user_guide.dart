// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnUserGuideTexts implements UserGuideTextSet {
  const EnUserGuideTexts();

  String get title => 'Parent Guide';
  String get subtitle => 'Review ingredients, cheer videos, and sticker rules.';
  String get introTitle => 'Guardian guide';
  String get introBody =>
      'Use this guide to understand the meal flow and app rules before starting a Yamyam ride.';
  String get basicFlowTitle => startCourseTitle;
  String get ingredientsTitle => roadIngredientsTitle;
  String get motivationTitle => 'Motivation videos';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => 'Guardian tips';

  String get whatIsYamyamTitle => 'What is Yamyam Rider?';
  List<String> get whatIsYamyamItems => const [
    'Yamyam Rider turns mealtime from a plain countdown into a small course ride.',
    'Children choose a vehicle and follow the course for the set meal time to pace the meal.',
    'At the end, the guardian confirms whether the meal was completed.',
  ];

  String get startCourseTitle => 'Starting a meal course';
  List<String> get startCourseItems => const [
    'After setting the child name, choose a vehicle from the home screen.',
    'Start a 15, 25, or 35 minute course, or choose a custom time.',
    'Depending on settings, ingredients can be selected before the course or shown automatically.',
    'Pausing during the timer is not a failure; it is just a short break in the meal flow.',
  ];

  String get roadIngredientsTitle => 'Road ingredients';
  List<String> get roadIngredientsItems => const [
    'Ingredients are visual cues that help the child think about today’s food.',
    'They are not nutrition scoring and do not decide success or incomplete results.',
    'Off: no ingredients are shown on the road.',
    'Manual: choose up to 5 ingredients before starting. Manually chosen ingredients are saved in meal history.',
    'Auto: the app shows random ingredients on the road. They are not saved in history.',
    'Only manually chosen ingredients are saved to meal records.',
  ];

  List<String> get motivationItems => const [
    'Motivation videos are short cheers that can appear during a meal.',
    'They do not affect rewards, success, or incomplete results.',
    'By default, they appear based on meal progress.',
    'Long courses or custom interval mode may use time-based scheduling.',
    'You can choose 3, 5, or 10 minute intervals.',
    'If sound is off, the video may appear without voice playback.',
  ];

  String get completionTitle => 'Complete, incomplete, and stickers';
  List<String> get completionItems => const [
    'When the guardian confirms the meal is finished, it is recorded as complete.',
    'A completed meal earns 1 random success sticker.',
    'If the timer arrives first and the meal is not finished, tap “Not yet.” The meal is recorded as incomplete.',
    'Incomplete meals are saved in history but do not earn stickers.',
    'The child-facing result keeps a next-try tone instead of harsh failure wording.',
  ];

  String get historyRewardsTitle => 'Meal history and reward goals';
  List<String> get historyRewardsItems => const [
    'Meal history shows target time, actual time, and completion status. It also shows earned stickers and manually chosen ingredients.',
    'Earned stickers collect in the sticker collection screen.',
    'If reward goals are active, success stickers can fill goal slots.',
  ];

  String get exitResumeTitle => 'Leaving and resuming during a timer';
  List<String> get exitResumeItems => const [
    'Using back during a timer asks for confirmation first.',
    'Pausing is not a failure; the meal can continue after a short break.',
    'When an active timer is saved, the home screen may show an in-progress card. Use that card to resume or cancel when it appears.',
  ];

  List<String> get guardianTipsItems => const [
    'Praise the meal rhythm first, not only the sticker.',
    'Set the default meal time to a pace that fits the child instead of making the goal too short.',
    'Treat incomplete results as records for the next try, not as punishment.',
  ];
}
