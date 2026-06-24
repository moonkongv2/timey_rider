// ignore_for_file: annotate_overrides

import '../../models/activity_completion_status.dart';
import '../text_sets.dart';

class EnResultTexts implements ResultTextSet {
  const EnResultTexts();

  String get rewardLoading => 'Saving the record...';
  String get recordSaved => "Today's record is saved.";
  String get stickerChoiceTitle => 'Did you review this activity?';
  String get stickerChoiceMessage =>
      "Look back on today's activity together, then choose.";
  String get getStickerButton => 'Get Sticker';
  String get skipStickerButton => 'No Sticker This Time';

  String stickerChoiceTitleForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => 'The planned time is over',
      _ => stickerChoiceTitle,
    };
  }

  String stickerChoiceMessageForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded =>
        'Check in together, then choose whether to get a sticker.',
      _ => stickerChoiceMessage,
    };
  }

  String title(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        "Today's activity is recorded!",
      ActivityCompletionStatus.timeEnded => 'The planned time is over',
      ActivityCompletionStatus.needsMoreTime => 'A little more time was needed',
      ActivityCompletionStatus.canceled => "That's enough for today",
    };
  }

  String primaryMessage(ActivityCompletionStatus status, {String? vehicleId}) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        "We checked and saved today's activity.",
      ActivityCompletionStatus.timeEnded => 'The timer reached the finish.',
      ActivityCompletionStatus.needsMoreTime =>
        _needsMoreTimeMessagesByVehicle[vehicleId] ??
            'A little more time would help.',
      ActivityCompletionStatus.canceled => "Let's pause here for today.",
    };
  }

  String secondaryMessage(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'We will remember the effort, too.',
      ActivityCompletionStatus.timeEnded =>
        "Let's take a moment to decide what's next.",
      ActivityCompletionStatus.needsMoreTime =>
        "That's okay. We can try a little more time next round.",
      ActivityCompletionStatus.canceled => 'We can try again next time.',
    };
  }

  String get parentTipLabel => 'Parent tips';

  String parentTipTitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Try saying this',
      ActivityCompletionStatus.timeEnded => 'Guide the next step calmly',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => 'Encourage the next try',
    };
  }

  String parentTipSubtitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'Notice the participation and effort before the result.',
      ActivityCompletionStatus.timeEnded =>
        'A timer ending can be a normal part of the routine.',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled =>
        'It is a clue for the next try, not a punishment.',
    };
  }

  String parentTipSemanticLabel(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'View parent tips for a completed activity',
      ActivityCompletionStatus.timeEnded =>
        'View parent tips for a time-ended activity',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled =>
        'View parent tips for an incomplete activity',
    };
  }

  String helpButtonLabel(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'Activity record and encouragement tips',
      ActivityCompletionStatus.timeEnded => 'Time-ended next-step tips',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => 'Tips for the next try',
    };
  }

  String helpTitle(ActivityCompletionStatus status) => helpButtonLabel(status);

  List<String> helpBodyParagraphs(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        "What you check together is saved in today's activity record.",
      ],
      ActivityCompletionStatus.timeEnded => const [
        'After the timer ends, check the mission together and save the record.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'If the activity was not wrapped up, keep the record as guidance for the next try.',
      ],
    };
  }

  List<String> helpBulletItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'Choose Get Sticker to receive one sticker for the selected vehicle.',
        'If a reward goal is active, the sticker can fill one goal slot.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'A time-ended activity is still recorded as part of the routine.',
        'Check together, then choose whether to get a sticker.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Choose No Sticker This Time to save the record without a sticker.',
        'An incomplete result is a planning clue, not a punishment.',
      ],
    };
  }

  String resultHelpMeaningTitle(ActivityCompletionStatus status) =>
      'What does this result mean?';

  List<String> resultHelpMeaningItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        "What you check together is saved in today's activity record.",
        'Choose Get Sticker to receive one sticker for the selected vehicle.',
        'If a reward goal is active, the sticker can fill one goal slot.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'The timer reached the end and the activity was recorded.',
        'This is a routine transition, not a pass-or-fail result.',
        'Check together, then choose whether to get a sticker.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'This activity needed a little more time today.',
        'Choose No Sticker This Time to save the record without a sticker.',
        'Use the record to adjust the next try.',
      ],
    };
  }

  String resultHelpSayTitle(ActivityCompletionStatus status) =>
      'Try saying this';

  List<String> resultHelpSayItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'I liked doing this activity with you today.',
        'I saw how hard you tried while the timer was going.',
        'The sticker is fun, but your effort matters most.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        "Time is up. Let's decide the next step.",
        'I saw how hard you tried while the timer was going.',
        'What activity should we try next?',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'That needed a little more time today. That’s okay.',
        'Let’s look at how far you got.',
        'I can give you more time next round.',
      ],
    };
  }

  String resultHelpAvoidTitle(ActivityCompletionStatus status) =>
      'Try to avoid';

  List<String> resultHelpAvoidItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'Good job being fast.',
        'You have to succeed every time.',
        'You have to do better to get a sticker.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Time is up, so you have to stop now.',
        'Why did you not do more?',
        'Hurry to the next thing.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'You failed.',
        'Why did you only do this much?',
        'You did not get a sticker because you did not do well.',
      ],
    };
  }

  String resultHelpNextCourseTitle(ActivityCompletionStatus status) =>
      'For the next activity';

  List<String> resultHelpNextCourseItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'If the activity flow felt short, try adjusting the timer next time.',
        'If your child seemed comfortable, repeat the same duration to build confidence.',
        'Praise the routine flow and effort more than the sticker.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'For activities that end by time, keeping the same duration may be enough.',
        'If your child wanted more time, try a slightly longer timer next time.',
        'Give a short cue before moving to the next activity.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'If incomplete results happen often, try a longer default duration.',
        'If the activity feels hard, break it into smaller visible steps.',
        'Use the record to understand routine patterns, not to grade the child.',
      ],
    };
  }
}

const _needsMoreTimeMessagesByVehicle = {
  'motorcycle': 'This activity needed a little more time today.',
  'fire_truck': 'This activity needed a little more time today.',
  'police_car': 'This activity needed a little more time today.',
  'excavator': 'This activity needed a little more time today.',
  'airplane': 'This activity needed a little more time today.',
  'bus': 'This activity needed a little more time today.',
  'supercar': 'This activity needed a little more time today.',
  'train': 'This activity needed a little more time today.',
  't_rex': 'This activity needed a little more time today.',
  'shark': 'This activity needed a little more time today.',
  'brachio': 'This activity needed a little more time today.',
  'pteranodon': 'This activity needed a little more time today.',
};
