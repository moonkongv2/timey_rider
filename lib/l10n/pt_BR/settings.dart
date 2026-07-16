// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrSettingsTexts implements SettingsTextSet {
  const PtBrSettingsTexts();

  String get title => 'Configurações';
  String get showRemainingTime => 'Mostrar tempo restante';
  String get soundEnabled => 'Efeitos sonoros';
  String get motivationVideoEnabled => 'Vídeos de incentivo';
  String get motivationVideoCustomInterval =>
      'Usar intervalo de vídeo personalizado';
  String get motivationVideoInterval => 'Intervalo dos vídeos de incentivo';
  String get motivationVideoHelpTitle => 'Guia dos vídeos de incentivo';
  String get motivationVideoHelpSummary =>
      'Os vídeos de incentivo são clipes curtos durante o timer.';
  List<String> get motivationVideoHelpBodyParagraphs => const [
    'Os vídeos de incentivo são clipes curtos que podem aparecer durante o timer.',
    'Eles não definem figurinhas nem resultados.',
  ];
  List<String> get motivationVideoHelpBulletItems => const [
    'Timers curtos podem pular alguns marcos para que os clipes não se sobreponham.',
    'Timers mais longos ou o modo de intervalo personalizado podem usar uma programação por tempo.',
    'Os intervalos personalizados podem ser de 3, 5 ou 10 minutos.',
    'Os efeitos sonoros e a exibição de vídeos podem ser configurados separadamente.',
    'O app espaça os vídeos para que eles não apareçam com frequência demais.',
  ];
  String get keepScreenAwake => 'Manter tela ligada';
  String get savedOnlySubtitle => 'Ativa ou desativa os sons durante o timer.';
  String get keepScreenAwakeSubtitle =>
      'Aplica-se enquanto o timer está em andamento.';
  String get markerModeTitle => 'Marcadores da rota';
  String get markerModeOff => 'Desligado';
  String get markerModeManual => 'Escolher';
  String get markerModeActivityDefault => 'Auto';
  String get markerModeDescription =>
      'Auto mostra uma prévia e usa marcadores com imagens que combinam com a atividade. Apenas os marcadores escolhidos manualmente são salvos nos registros de atividade.';
  String get vehicleSelection => 'Escolher veículo';
  String get childNameTitle => 'Nome da criança';
  String get childNameFieldLabel => 'Nome';
  String get childNameSetupTitle => 'Quem vai pilotar hoje?';
  String get childNameSetupSubtitle => 'Primeiro, informe o nome da criança.';
  String get saveChildName => 'Salvar nome';
  String get childNameRequiredMessage => 'Informe o nome da criança.';
  String get childNameSavedMessage => 'Nome salvo.';
  String get avatarSettingsTitle => 'Configurações da imagem do piloto';
  String get avatarDefaultState => 'Usando imagem padrão';
  String get avatarCustomState => 'Usando piloto personalizado';
  String get avatarSettingsButton => 'Abrir configurações da imagem do piloto';
  String get vehiclePackSettingsTitle => 'Pacote de veículos';
  String get vehiclePackLockedState => 'Veículos bloqueados disponíveis';
  String get vehiclePackUnlockedState => 'Pacote de veículos desbloqueado';
  String get vehiclePackSettingsDescription =>
      'O pacote de veículos desbloqueia todos os veículos bloqueados. As opções de compra e restauração abrem depois de uma verificação dos pais.';
  String get vehiclePackManageButton => 'Ver pacote de veículos';
  String get vehiclePackRestoreButton => 'Restaurar compra';

  String motivationVideoIntervalSegmentLabel(int minutes) => '$minutes min';
}
