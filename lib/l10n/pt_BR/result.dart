// ignore_for_file: annotate_overrides

import '../../models/activity_completion_status.dart';
import '../text_sets.dart';

class PtBrResultTexts implements ResultTextSet {
  const PtBrResultTexts();

  String get rewardLoading => 'Salvando o registro...';
  String get recordSaved => "O registro de hoje foi salvo.";
  String get stickerChoiceTitle => 'Vocês revisaram esta atividade?';
  String get stickerChoiceMessage =>
      "Revisem juntos a atividade de hoje e depois escolham.";
  String get getStickerButton => 'Ganhar adesivo';
  String get skipStickerButton => 'Sem adesivo desta vez';

  String stickerChoiceTitleForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => 'O tempo planejado acabou',
      _ => stickerChoiceTitle,
    };
  }

  String stickerChoiceMessageForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded =>
        'Conversem juntos e escolham se vão ganhar um adesivo.',
      _ => stickerChoiceMessage,
    };
  }

  String title(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        "A atividade de hoje foi registrada!",
      ActivityCompletionStatus.timeEnded => 'O tempo planejado acabou',
      ActivityCompletionStatus.needsMoreTime =>
        'Foi preciso um pouco mais de tempo',
      ActivityCompletionStatus.canceled => "Por hoje está bom",
    };
  }

  String primaryMessage(ActivityCompletionStatus status, {String? vehicleId}) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        "Conferimos e salvamos a atividade de hoje.",
      ActivityCompletionStatus.timeEnded => 'O timer chegou ao fim.',
      ActivityCompletionStatus.needsMoreTime =>
        _needsMoreTimeMessagesByVehicle[vehicleId] ??
            'Um pouco mais de tempo pode ajudar.',
      ActivityCompletionStatus.canceled => "Vamos parar por aqui hoje.",
    };
  }

  String secondaryMessage(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'Também vamos lembrar do esforço.',
      ActivityCompletionStatus.timeEnded =>
        "Vamos decidir com calma o próximo passo.",
      ActivityCompletionStatus.needsMoreTime =>
        "Tudo bem. Na próxima, podemos tentar com um pouco mais de tempo.",
      ActivityCompletionStatus.canceled => 'Podemos tentar de novo na próxima.',
    };
  }

  String get parentTipLabel => 'Dicas para responsáveis';

  String parentTipTitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Tente dizer isto',
      ActivityCompletionStatus.timeEnded => 'Oriente o próximo passo com calma',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => 'Incentive a próxima tentativa',
    };
  }

  String parentTipSubtitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'Valorize a participação e o esforço antes do resultado.',
      ActivityCompletionStatus.timeEnded =>
        'O fim do timer pode ser uma parte normal da rotina.',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled =>
        'É uma pista para a próxima tentativa, não uma punição.',
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
        'Registro e dicas de incentivo',
      ActivityCompletionStatus.timeEnded => 'Dicas para depois do fim do tempo',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => 'Dicas para a próxima tentativa',
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
        'Choose Ganhar adesivo to receive one sticker for the selected vehicle.',
        'If a reward goal is active, the sticker can fill one goal slot.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'A time-ended activity is still recorded as part of the routine.',
        'Check together, then choose whether to get a sticker.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Choose Sem adesivo desta vez to save the record without a sticker.',
        'An incomplete result is a planning clue, not a punishment.',
      ],
    };
  }

  String resultHelpMeaningTitle(ActivityCompletionStatus status) =>
      'O que este resultado significa?';

  List<String> resultHelpMeaningItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        "What you check together is saved in today's activity record.",
        'Choose Ganhar adesivo to receive one sticker for the selected vehicle.',
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
        'Choose Sem adesivo desta vez to save the record without a sticker.',
        'Use the record to adjust the next try.',
      ],
    };
  }

  String resultHelpSayTitle(ActivityCompletionStatus status) =>
      'Tente dizer isto';

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
      'Para a próxima atividade';

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
