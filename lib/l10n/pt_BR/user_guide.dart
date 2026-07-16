// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrUserGuideTexts implements UserGuideTextSet {
  const PtBrUserGuideTexts();

  String get title => 'Guia para responsáveis';
  String get subtitle =>
      'Revise missões, vídeos de incentivo e regras dos adesivos.';
  String get introTitle => 'Guia para responsáveis';
  String get introBody =>
      'Use este guia para entender as missões e regras do Timey Rider antes de começar. Ele é feito para responsáveis que ajudam nas rotinas diárias.';
  String get basicFlowTitle => startMissionTitle;
  String get markersTitle => courseMarkersTitle;
  String get motivationTitle => 'Vídeos de incentivo';
  String get resultRewardsTitle => completionTitle;
  String get historyTitle => historyRewardsTitle;
  String get guardianTipsTitle => 'Dicas para responsáveis';

  String get whatIsTimeyRiderTitle => 'O que é o Timey Rider?';
  List<String> get whatIsTimeyRiderItems => const [
    'O Timey Rider transforma rotinas como escovar os dentes, ler, arrumar e brincar em pequenas missões de corrida.',
    'As crianças escolhem um veículo e seguem o percurso durante o tempo definido no timer.',
    'No final, cada atividade é registrada pelo modo de conclusão: confirmar que terminou, tempo encerrado ou verificação dos responsáveis.',
  ];

  String get startMissionTitle => 'Iniciar uma missão';
  List<String> get startMissionItems => const [
    'Depois de definir o nome da criança, escolha um veículo na tela inicial.',
    'Toque em Criar timer no Início e escolha missão, marcadores e duração.',
    'Use Outro no mesmo fluxo quando a rotina não combinar com uma missão predefinida.',
    'Pausar durante o timer não é uma falha; a missão pode continuar quando necessário.',
  ];

  String get courseMarkersTitle => 'Marcadores da rota';
  List<String> get courseMarkersItems => const [
    'Os marcadores da rota são pequenas metas visuais durante uma atividade.',
    'Desligado: nenhum marcador aparece na rota.',
    'Auto: o app mostra uma prévia e usa marcadores com imagens que combinam com a atividade escolhida.',
    'Escolher: selecione até 5 marcadores com imagens antes de começar.',
    'Apenas os marcadores escolhidos manualmente são salvos nos registros de atividade.',
    'Os marcadores não definem a conclusão da atividade nem os adesivos recebidos.',
  ];

  List<String> get motivationItems => const [
    'Os vídeos de incentivo são clipes curtos durante o timer.',
    'Eles não definem adesivos nem resultados.',
    'Timers curtos podem pular alguns marcos para evitar sobreposição.',
    'Timers mais longos ou o modo de intervalo personalizado podem usar uma programação por tempo.',
    'Você pode escolher intervalos de 3, 5 ou 10 minutos.',
    'Se o som estiver desligado, o vídeo pode aparecer sem reprodução de voz.',
  ];

  String get completionTitle => 'Conclusão e adesivos';
  List<String> get completionItems => const [
    'Quando você confirma que a atividade terminou, ela é registrada como concluída.',
    'Depois que o timer terminar, confiram juntos e escolham se vão ganhar um adesivo.',
    'Escolha Ganhar adesivo para receber o adesivo selecionado.',
    'Escolha Sem adesivo desta vez para salvar o registro e orientar a próxima escolha de timer.',
    'O resultado mostrado para a criança mantém um tom de próxima tentativa, sem palavras duras de falha.',
  ];

  String get historyRewardsTitle => 'Histórico e metas de recompensa';
  List<String> get historyRewardsItems => const [
    'O histórico mostra o nome da atividade, o tempo previsto, o tempo real e o status de conclusão.',
    'Adesivos ganhos e marcadores com imagens escolhidos manualmente podem aparecer com o registro.',
    'Os adesivos ganhos ficam reunidos na tela de coleção de adesivos.',
    'Se houver metas de recompensa ativas, os adesivos recebidos podem preencher espaços da meta.',
  ];

  String get exitResumeTitle => 'Sair e continuar durante um timer';
  List<String> get exitResumeItems => const [
    'Usar voltar durante um timer pede confirmação primeiro.',
    'Pausar não é uma falha; a missão pode continuar depois de uma pausa curta.',
    'Quando um timer ativo é salvo, a tela inicial pode mostrar um cartão em andamento. Use esse cartão para retomar ou cancelar quando ele aparecer.',
  ];

  List<String> get guardianTipsItems => const [
    'Elogie primeiro a tentativa de rotina, não apenas o adesivo.',
    'Defina a duração padrão do timer em um ritmo que combine com a criança, em vez de deixar a meta curta demais.',
    'Trate os resultados que precisam de mais tempo como notas para a próxima tentativa, não como punição.',
  ];
}
