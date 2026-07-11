// ignore_for_file: annotate_overrides

import '../../models/activity_completion_status.dart';
import '../text_sets.dart';

class EsResultTexts implements ResultTextSet {
  const EsResultTexts();

  String get rewardLoading => 'Guardando el registro...';
  String get recordSaved => "El registro de hoy se guardó.";
  String get stickerChoiceTitle => '¿Ya revisaron esta actividad?';
  String get stickerChoiceMessage =>
      "Revisen juntos la actividad de hoy y luego elijan.";
  String get getStickerButton => 'Obtener pegatina';
  String get skipStickerButton => 'Sin pegatina esta vez';

  String stickerChoiceTitleForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded => 'El tiempo previsto terminó',
      _ => stickerChoiceTitle,
    };
  }

  String stickerChoiceMessageForStatus(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.timeEnded =>
        'Revisen juntos y elijan si reciben una pegatina.',
      _ => stickerChoiceMessage,
    };
  }

  String title(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        "¡La actividad de hoy quedó registrada!",
      ActivityCompletionStatus.timeEnded => 'El tiempo previsto terminó',
      ActivityCompletionStatus.needsMoreTime =>
        'Hizo falta un poco más de tiempo',
      ActivityCompletionStatus.canceled => "Por hoy está bien",
    };
  }

  String primaryMessage(ActivityCompletionStatus status, {String? vehicleId}) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        "Revisamos y guardamos la actividad de hoy.",
      ActivityCompletionStatus.timeEnded => 'El temporizador llegó a la meta.',
      ActivityCompletionStatus.needsMoreTime =>
        _needsMoreTimeMessagesByVehicle[vehicleId] ??
            'Un poco más de tiempo ayudaría.',
      ActivityCompletionStatus.canceled => "Paremos aquí por hoy.",
    };
  }

  String secondaryMessage(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'También recordaremos el esfuerzo.',
      ActivityCompletionStatus.timeEnded =>
        "Tomemos un momento para decidir qué sigue.",
      ActivityCompletionStatus.needsMoreTime =>
        "Está bien. La próxima vez podemos probar con un poco más de tiempo.",
      ActivityCompletionStatus.canceled =>
        'Podemos intentarlo de nuevo la próxima vez.',
    };
  }

  String get parentTipLabel => 'Consejos para adultos';

  String parentTipTitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => 'Prueba decir esto',
      ActivityCompletionStatus.timeEnded => 'Guía el siguiente paso con calma',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => 'Anima el próximo intento',
    };
  }

  String parentTipSubtitle(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd =>
        'Observa la participación y el esfuerzo antes que el resultado.',
      ActivityCompletionStatus.timeEnded =>
        'Que termine el temporizador puede ser parte normal de la rutina.',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled =>
        'Es una pista para el próximo intento, no un castigo.',
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
        'Registro y consejos de ánimo',
      ActivityCompletionStatus.timeEnded => 'Consejos para después del tiempo',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => 'Consejos para el próximo intento',
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
        'Choose Obtener pegatina to receive one sticker for the selected vehicle.',
        'If a reward goal is active, the sticker can fill one goal slot.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'A time-ended activity is still recorded as part of the routine.',
        'Check together, then choose whether to get a sticker.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Choose Sin pegatina esta vez to save the record without a sticker.',
        'An incomplete result is a planning clue, not a punishment.',
      ],
    };
  }

  String resultHelpMeaningTitle(ActivityCompletionStatus status) =>
      '¿Qué significa este resultado?';

  List<String> resultHelpMeaningItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        "What you check together is saved in today's activity record.",
        'Choose Obtener pegatina to receive one sticker for the selected vehicle.',
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
        'Choose Sin pegatina esta vez to save the record without a sticker.',
        'Use the record to adjust the next try.',
      ],
    };
  }

  String resultHelpSayTitle(ActivityCompletionStatus status) =>
      'Prueba decir esto';

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
      'Para la próxima actividad';

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
