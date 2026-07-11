// ignore_for_file: annotate_overrides

import '../../models/activity_completion_status.dart';
import '../text_sets.dart';

class JaResultTexts implements ResultTextSet {
  const JaResultTexts();

  String get rewardLoading => '記録を保存中...';
  String get recordSaved => "今日の記録を保存しました。";
  String get stickerChoiceTitle => 'この活動を確認しましたか？';
  String get stickerChoiceMessage => "今日の活動を一緒に振り返ってから選んでください。";
  String get getStickerButton => 'ステッカーをもらう';
  String get skipStickerButton => '今回はステッカーなし';

  String stickerChoiceTitleForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => '予定の時間が終わりました',
      _ => stickerChoiceTitle,
    };
  }

  String stickerChoiceMessageForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => '一緒に確認して、ステッカーをもらうか選んでください。',
      _ => stickerChoiceMessage,
    };
  }

  String title(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => "今日の活動を記録しました！",
      ActivityCompletionStatus.timeEnded => '予定の時間が終わりました',
      ActivityCompletionStatus.needsMoreTime => 'もう少し時間が必要でした',
      ActivityCompletionStatus.canceled => "今日はここまで",
    };
  }

  String primaryMessage(ActivityCompletionStatus status, {String? vehicleId}) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => "今日の活動を確認して保存しました。",
      ActivityCompletionStatus.timeEnded => 'タイマーがゴールしました。',
      ActivityCompletionStatus.needsMoreTime =>
        _needsMoreTimeMessagesByVehicle[vehicleId] ?? 'もう少し時間があるとよさそうです。',
      ActivityCompletionStatus.canceled => "今日はここでひと休みしましょう。",
    };
  }

  String secondaryMessage(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'がんばった過程も一緒に覚えておきます。',
      ActivityCompletionStatus.timeEnded => "次にどうするか、落ち着いて決めましょう。",
      ActivityCompletionStatus.needsMoreTime => "大丈夫。次は少し時間を増やしてみましょう。",
      ActivityCompletionStatus.canceled => 'また次に試せます。',
    };
  }

  String get parentTipLabel => '保護者向けヒント';

  String parentTipTitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'こんな声かけを試す',
      ActivityCompletionStatus.timeEnded => '次の流れを落ち着いて伝える',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '次の挑戦をやさしく応援',
    };
  }

  String parentTipSubtitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        '結果より先に、参加したことと努力を見てあげてください。',
      ActivityCompletionStatus.timeEnded => 'タイマーが終わることも、いつもの流れの一部です。',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '罰ではなく、次に調整するための手がかりです。',
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
      ActivityCompletionStatus.completedAfterEnd => '活動記録と声かけのヒント',
      ActivityCompletionStatus.timeEnded => '時間終了後の次のヒント',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => '次の挑戦のヒント',
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
        'Choose ステッカーをもらう to receive one sticker for the selected vehicle.',
        'If a reward goal is active, the sticker can fill one goal slot.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'A time-ended activity is still recorded as part of the routine.',
        'Check together, then choose whether to get a sticker.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Choose 今回はステッカーなし to save the record without a sticker.',
        'An incomplete result is a planning clue, not a punishment.',
      ],
    };
  }

  String resultHelpMeaningTitle(ActivityCompletionStatus status) => 'この結果の意味';

  List<String> resultHelpMeaningItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        "What you check together is saved in today's activity record.",
        'Choose ステッカーをもらう to receive one sticker for the selected vehicle.',
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
        'Choose 今回はステッカーなし to save the record without a sticker.',
        'Use the record to adjust the next try.',
      ],
    };
  }

  String resultHelpSayTitle(ActivityCompletionStatus status) => 'こんな声かけを試す';

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
      '次の活動に向けて';

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
