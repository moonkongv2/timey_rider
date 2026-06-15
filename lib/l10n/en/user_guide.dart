// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnUserGuideTexts implements UserGuideTextSet {
  const EnUserGuideTexts();

  String get title => 'Parent Guide';
  String get subtitle =>
      'Review activity missions, cheer videos, and vehicle sticker rules.';
  String get introTitle => 'Parent Guide';
  String get introBody =>
      'Use this guide to understand Timey Rider activity missions and app rules before starting a ride. This guide is for parents and other caregivers helping with daily routines.';
  String get basicFlowTitle => startMissionTitle;
  String get markersTitle => courseMarkersTitle;
  String get motivationTitle => 'Motivation videos';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => 'Parent tips';

  String get whatIsTimeyRiderTitle => 'What is Timey Rider?';
  List<String> get whatIsTimeyRiderItems => const [
    'Timey Rider turns routines like brushing teeth, reading, cleanup, and play time into small riding missions.',
    'Children choose a vehicle and follow the course for the set timer duration.',
    'At the end, each activity is recorded through its completion mode: confirm done, time ended, or parent check.',
  ];

  String get startMissionTitle => 'Start an activity mission';
  List<String> get startMissionItems => const [
    'After setting the child name, choose a vehicle from the home screen.',
    'Tap Create Timer on Home, then choose a mission, markers, and duration.',
    'Use Other in the same flow when the routine does not match a preset mission.',
    'Pausing during the timer is not a failure; the mission can resume when needed.',
  ];

  String get courseMarkersTitle => 'Course markers';
  List<String> get courseMarkersItems => const [
    'Course markers are small route goals shown during an activity.',
    'Off: no markers are shown on the road.',
    'Auto: the app previews and uses picture markers that fit the selected activity.',
    'Choose: pick up to 5 picture markers before starting.',
    'Only manually chosen picture markers are saved to activity records.',
    'Markers do not decide completion or vehicle sticker results.',
  ];

  List<String> get motivationItems => const [
    'Motivation videos are short encouragement clips during the timer.',
    'They do not decide vehicle stickers or results.',
    'Short timers may skip some milestones to avoid overlap.',
    'Longer timers or custom interval mode may use time-based scheduling.',
    'You can choose 3, 5, or 10 minute intervals.',
    'If sound is off, the video may appear without voice playback.',
  ];

  String get completionTitle => 'Completion and vehicle stickers';
  List<String> get completionItems => const [
    'When you confirm the activity is done, it is recorded as complete.',
    'After the timer ends, check together and choose whether to get a vehicle sticker.',
    'Choose Get Vehicle Sticker to receive the selected vehicle sticker.',
    'Choose No Vehicle Sticker This Time to save the record and guide the next timer choice.',
    'The child-facing result keeps a next-try tone instead of harsh failure wording.',
  ];

  String get historyRewardsTitle => 'Activity history and reward goals';
  List<String> get historyRewardsItems => const [
    'Activity history shows activity name, target time, actual time, and completion status.',
    'Earned vehicle stickers and manually chosen picture markers can appear with the record.',
    'Earned vehicle stickers collect in the vehicle sticker collection screen.',
    'If reward goals are active, received vehicle stickers can fill goal slots.',
  ];

  String get exitResumeTitle => 'Leaving and resuming during a timer';
  List<String> get exitResumeItems => const [
    'Using back during a timer asks for confirmation first.',
    'Pausing is not a failure; the mission can continue after a short break.',
    'When an active timer is saved, the home screen may show an in-progress card. Use that card to resume or cancel when it appears.',
  ];

  List<String> get guardianTipsItems => const [
    'Praise the routine attempt first, not only the vehicle sticker.',
    'Set the default timer duration to a pace that fits the child instead of making the goal too short.',
    'Treat needs-more-time results as notes for the next try, not as punishment.',
  ];
}
