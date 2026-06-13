// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnUserGuideTexts implements UserGuideTextSet {
  const EnUserGuideTexts();

  String get title => 'Parent Guide';
  String get subtitle =>
      'Review activity missions, cheer videos, and sticker rules.';
  String get introTitle => 'Parent Guide';
  String get introBody =>
      'Use this guide to understand Ticky Rider activity missions and app rules before starting a ride. This guide is for parents and other caregivers helping with daily routines.';
  String get basicFlowTitle => startMissionTitle;
  String get markersTitle => courseMarkersTitle;
  String get motivationTitle => 'Motivation videos';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => 'Parent tips';

  String get whatIsTickyRiderTitle => 'What is Ticky Rider?';
  List<String> get whatIsTickyRiderItems => const [
    'Ticky Rider turns routines like brushing teeth, reading, cleanup, and play time into small riding missions.',
    'Children choose a vehicle and follow the course for the set timer duration.',
    'At the end, each activity is recorded through its completion mode: confirm done, time ended, or parent check.',
  ];

  String get startMissionTitle => 'Start an activity mission';
  List<String> get startMissionItems => const [
    'After setting the child name, choose a vehicle from the home screen.',
    'Pick an activity card on Home to use its default duration.',
    'For Custom Timer, choose the duration before starting.',
    'Pausing during the timer is not a failure; the mission can resume when needed.',
  ];

  String get courseMarkersTitle => 'Course markers';
  List<String> get courseMarkersItems => const [
    'Course markers are small route goals shown during an activity.',
    'Off: no markers are shown on the road.',
    'Match activity: use markers that fit the selected activity.',
    'Choose: pick up to 5 markers before starting. Chosen markers are saved to activity records.',
    'Random: the app shows random markers that fit the activity.',
    'Markers do not decide completion or sticker results.',
  ];

  List<String> get motivationItems => const [
    'Motivation videos are short encouragement clips during the timer.',
    'They do not decide stickers or results.',
    'Short timers may skip some milestones to avoid overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'You can choose 3, 5, or 10 minute intervals.',
    'If sound is off, the video may appear without voice playback.',
  ];

  String get completionTitle => 'Completion and stickers';
  List<String> get completionItems => const [
    'When you confirm the activity is done, it is recorded as complete.',
    'Some activities, like Play Time, can finish when the timer ends.',
    'Completed missions may earn a random success sticker.',
    'Needs-more-time or canceled records are saved without stickers and can guide the next timer choice.',
    'The child-facing result keeps a next-try tone instead of harsh failure wording.',
  ];

  String get historyRewardsTitle => 'Activity history and reward goals';
  List<String> get historyRewardsItems => const [
    'Activity history shows activity name, target time, actual time, and completion status.',
    'Earned stickers and manually chosen markers can appear with the record.',
    'Earned stickers collect in the sticker collection screen.',
    'If reward goals are active, success stickers can fill goal slots.',
  ];

  String get exitResumeTitle => 'Leaving and resuming during a timer';
  List<String> get exitResumeItems => const [
    'Using back during a timer asks for confirmation first.',
    'Pausing is not a failure; the mission can continue after a short break.',
    'When an active timer is saved, the home screen may show an in-progress card. Use that card to resume or cancel when it appears.',
  ];

  List<String> get guardianTipsItems => const [
    'Praise the routine attempt first, not only the sticker.',
    'Set the default timer duration to a pace that fits the child instead of making the goal too short.',
    'Treat needs-more-time results as notes for the next try, not as punishment.',
  ];
}
