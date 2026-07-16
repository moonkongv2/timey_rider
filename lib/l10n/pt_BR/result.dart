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
        'Ver dicas para responsáveis sobre uma atividade concluída',
      ActivityCompletionStatus.timeEnded =>
        'Ver dicas para responsáveis sobre uma atividade com tempo encerrado',
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled =>
        'Ver dicas para responsáveis sobre uma atividade incompleta',
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
        'O que vocês conferem juntos é salvo no registro de atividade de hoje.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Depois que o timer terminar, confiram a missão juntos e salvem o registro.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Se a atividade não foi finalizada, mantenha o registro como orientação para a próxima tentativa.',
      ],
    };
  }

  List<String> helpBulletItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'Escolha Ganhar adesivo para receber um adesivo do veículo selecionado.',
        'Se houver uma meta de recompensa ativa, o adesivo pode preencher um espaço da meta.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Uma atividade com tempo encerrado ainda é registrada como parte da rotina.',
        'Confiram juntos e depois escolham se vão ganhar um adesivo.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Escolha Sem adesivo desta vez para salvar o registro sem adesivo.',
        'Um resultado incompleto é uma pista de planejamento, não uma punição.',
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
        'O que vocês conferem juntos é salvo no registro de atividade de hoje.',
        'Escolha Ganhar adesivo para receber um adesivo do veículo selecionado.',
        'Se houver uma meta de recompensa ativa, o adesivo pode preencher um espaço da meta.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'O timer chegou ao fim e a atividade foi registrada.',
        'Isso é uma transição da rotina, não um resultado de passou ou falhou.',
        'Confiram juntos e depois escolham se vão ganhar um adesivo.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Esta atividade precisou de um pouco mais de tempo hoje.',
        'Escolha Sem adesivo desta vez para salvar o registro sem adesivo.',
        'Use o registro para ajustar a próxima tentativa.',
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
        'Gostei de fazer esta atividade com você hoje.',
        'Vi o quanto você se esforçou enquanto o timer estava rodando.',
        'O adesivo é divertido, mas o seu esforço é o mais importante.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'O tempo acabou. Vamos decidir o próximo passo.',
        'Vi o quanto você se esforçou enquanto o timer estava rodando.',
        'Que atividade vamos tentar agora?',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Hoje isso precisou de um pouco mais de tempo. Tudo bem.',
        'Vamos ver até onde você chegou.',
        'Posso dar mais tempo na próxima rodada.',
      ],
    };
  }

  String resultHelpAvoidTitle(ActivityCompletionStatus status) =>
      'Tente evitar';

  List<String> resultHelpAvoidItems(ActivityCompletionStatus status) {
    return switch (status) {
      ActivityCompletionStatus.completedBeforeEnd ||
      ActivityCompletionStatus.completedAtEnd ||
      ActivityCompletionStatus.completedAfterEnd => const [
        'Bom trabalho por ser rápido.',
        'Você precisa conseguir sempre.',
        'Você precisa fazer melhor para ganhar um adesivo.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'O tempo acabou, então você tem que parar agora.',
        'Por que você não fez mais?',
        'Corra para a próxima coisa.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Você falhou.',
        'Por que você só fez isso?',
        'Você não ganhou adesivo porque não foi bem.',
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
        'Se o fluxo da atividade pareceu curto, tente ajustar o timer na próxima vez.',
        'Se a criança pareceu confortável, repita a mesma duração para criar confiança.',
        'Valorize o fluxo da rotina e o esforço mais do que o adesivo.',
      ],
      ActivityCompletionStatus.timeEnded => const [
        'Para atividades que terminam por tempo, manter a mesma duração pode ser suficiente.',
        'Se a criança queria mais tempo, tente um timer um pouco mais longo na próxima vez.',
        'Dê um aviso curto antes de passar para a próxima atividade.',
      ],
      ActivityCompletionStatus.needsMoreTime ||
      ActivityCompletionStatus.canceled => const [
        'Se resultados incompletos acontecem com frequência, tente uma duração padrão mais longa.',
        'Se a atividade parece difícil, divida em passos menores e visíveis.',
        'Use o registro para entender padrões da rotina, não para avaliar a criança.',
      ],
    };
  }
}

const _needsMoreTimeMessagesByVehicle = {
  'motorcycle': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'fire_truck': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'police_car': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'excavator': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'airplane': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'bus': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'supercar': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'train': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  't_rex': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'shark': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'brachio': 'Esta atividade precisou de um pouco mais de tempo hoje.',
  'pteranodon': 'Esta atividade precisou de um pouco mais de tempo hoje.',
};
