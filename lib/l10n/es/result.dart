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
        'Ver consejos para adultos sobre una actividad completada',
      ActivityCompletionStatus.timeEnded =>
        'Ver consejos para adultos sobre una actividad con tiempo terminado',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled =>
        'Ver consejos para adultos sobre una actividad incompleta',
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
        'Lo que revisen juntos se guarda en el registro de actividad de hoy.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Cuando termine el temporizador, revisen juntos la misión y guarden el registro.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Si la actividad no se cerró del todo, usen el registro como guía para el próximo intento.',
      ],
    };
  }

  List<String> helpBulletItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'Elige Obtener pegatina para recibir una pegatina del vehículo seleccionado.',
        'Si hay una meta de recompensa activa, la pegatina puede llenar un espacio de la meta.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Una actividad con tiempo terminado también se registra como parte de la rutina.',
        'Revisen juntos y luego elijan si reciben una pegatina.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Elige Sin pegatina esta vez para guardar el registro sin pegatina.',
        'Un resultado incompleto es una pista para planificar, no un castigo.',
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
        'Lo que revisen juntos se guarda en el registro de actividad de hoy.',
        'Elige Obtener pegatina para recibir una pegatina del vehículo seleccionado.',
        'Si hay una meta de recompensa activa, la pegatina puede llenar un espacio de la meta.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'El temporizador llegó al final y la actividad quedó registrada.',
        'Es una transición de la rutina, no un resultado de aprobado o fallado.',
        'Revisen juntos y luego elijan si reciben una pegatina.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Esta actividad necesitó un poco más de tiempo hoy.',
        'Elige Sin pegatina esta vez para guardar el registro sin pegatina.',
        'Usa el registro para ajustar el próximo intento.',
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
        'Me gustó hacer esta actividad contigo hoy.',
        'Vi cuánto te esforzaste mientras corría el temporizador.',
        'La pegatina es divertida, pero tu esfuerzo es lo más importante.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Se acabó el tiempo. Decidamos el siguiente paso.',
        'Vi cuánto te esforzaste mientras corría el temporizador.',
        '¿Qué actividad probamos ahora?',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Hoy hizo falta un poco más de tiempo. Está bien.',
        'Miremos hasta dónde llegaste.',
        'La próxima vez puedo darte más tiempo.',
      ],
    };
  }

  String resultHelpAvoidTitle(ActivityCompletionStatus status) =>
      'Intenta evitar';

  List<String> resultHelpAvoidItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'Buen trabajo por hacerlo rápido.',
        'Tienes que lograrlo siempre.',
        'Tienes que hacerlo mejor para recibir una pegatina.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Se acabó el tiempo, así que tienes que parar ahora.',
        '¿Por qué no hiciste más?',
        'Apúrate con lo siguiente.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Fallaste.',
        '¿Por qué solo hiciste esto?',
        'No recibiste pegatina porque no lo hiciste bien.',
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
        'Si la actividad se sintió corta, prueba ajustar el temporizador la próxima vez.',
        'Si tu hijo estuvo cómodo, repite la misma duración para darle confianza.',
        'Elogia la rutina y el esfuerzo más que la pegatina.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Para actividades que terminan por tiempo, mantener la misma duración puede ser suficiente.',
        'Si tu hijo quería más tiempo, prueba un temporizador un poco más largo la próxima vez.',
        'Da una señal breve antes de pasar a la siguiente actividad.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Si los resultados incompletos se repiten, prueba una duración predeterminada más larga.',
        'Si la actividad se siente difícil, divídela en pasos visibles más pequeños.',
        'Usa el registro para entender patrones de la rutina, no para calificar al niño.',
      ],
    };
  }
}

const _needsMoreTimeMessagesByVehicle = {
  'motorcycle': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'fire_truck': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'police_car': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'excavator': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'airplane': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'bus': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'supercar': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'train': 'Esta actividad necesitó un poco más de tiempo hoy.',
  't_rex': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'shark': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'brachio': 'Esta actividad necesitó un poco más de tiempo hoy.',
  'pteranodon': 'Esta actividad necesitó un poco más de tiempo hoy.',
};
