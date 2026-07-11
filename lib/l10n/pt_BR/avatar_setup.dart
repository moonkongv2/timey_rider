// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class PtBrAvatarSetupTexts implements AvatarSetupTextSet {
  const PtBrAvatarSetupTexts();

  String get title => 'Criar o rider da criança';
  String get intro =>
      "Crie uma imagem de rider para o Timey Rider e depois escolha aqui a imagem pronta.";
  String get selectedVehicleTitle => 'Veículo selecionado';
  String get currentAvatarModeTitle => 'Modo da imagem do rider';
  String get defaultImageMode => 'Usar imagem padrão';
  String get customAvatarMode => 'Usar rider personalizado';
  String get copyPromptMessage =>
      'Prompt copiado. Cole no serviço externo de IA.';
  String get avatarSaveFailureMessage => 'Não foi possível salvar a imagem.';
  String get avatarSavedMessage => 'Rider salvo.';
  String get defaultImageSavedMessage => 'Mudou para a imagem padrão.';
  String get missingAvatarWarning =>
      'Imagem do rider não encontrada. A imagem padrão será exibida.';
  String get vehicleSelectionTitle => 'Veículo deste rider';
  String get vehicleSelectionSubtitle => 'Referência do prompt';
  String get compositePreviewTitle => 'Prévia do rider';
  String get compositePreviewSubtitle => 'Usar este visual no Timey Rider?';
  String get defaultPreviewTitle => 'Prévia da imagem padrão';
  String get useDefaultImageButton => 'Usar imagem padrão';
  String get adjustmentTitle => 'Ajustar posição do rider';
  String get faceSizeLabel => 'Tamanho do rosto';
  String get horizontalPositionLabel => 'Posição horizontal';
  String get verticalPositionLabel => 'Posição vertical';
  String get rotationLabel => 'Inclinação';
  String get resetPositionButton => 'Redefinir posição';
  String get confirmAvatarButton => 'Usar este rider';
  String get guideTitle => 'Guia da imagem do rider';
  String get guideIntro =>
      'O app não recorta rostos sozinho. Prepare uma imagem de rider para o veículo usando um dos métodos abaixo.';
  String get promptCopyTitle => 'Prompt da imagem do rider (exemplo)';
  String get promptHelperText =>
      'Ao usar um serviço de IA, copie o prompt específico do veículo abaixo e cole no serviço externo.';
  String get promptGuideHint =>
      'Copie o prompt de exemplo abaixo e cole no serviço de IA.';
  String get promptExpandLabel => 'Abrir prompt';
  String get promptCollapseLabel => 'Fechar prompt';
  String get promptToggleSemanticLabel =>
      'Abrir ou fechar o prompt da imagem do rider';
  String get copyPromptButton => 'Copiar prompt';
  String get uploadTitle => 'Importar imagem do rider';
  String get uploadInstructions =>
      'Escolha uma imagem quadrada feita com app de fotos ou serviço externo de IA.\n'
      "Funciona melhor quando o rosto está centralizado em fundo transparente.";
  String get uploadingButton => 'Importando';
  String get reuploadButton => 'Escolher de novo';
  String get uploadButton => 'Escolher imagem do rider';
  String get selectedImageFallback => 'Imagem do rider selecionada';
  String get privacyNote =>
      "Este app não cria imagens de IA nem envia a foto da criança por conta própria.\n"
      'Escolha uma imagem pronta deste dispositivo. O Timey Rider salva localmente e não envia para um servidor.\n'
      'Confira as políticas de fotos e privacidade antes de usar um serviço externo.';

  String get guidePopupTitle => 'Criar o rider da criança';
  String get guideReplayTooltip => 'Ver guia novamente';
  String get guidePopupMethodTitle => '📸 Como preparar uma imagem de rider';
  String get guidePopupMethodIntro =>
      'O app não tem uma função interna para recortar rostos. Prepare a imagem do rosto para colocar no veículo, como no exemplo acima.';
  String get guidePopupMethod1Title => '1. Use um app de fotos';
  String get guidePopupMethod1Body =>
      'Use o recurso de "remover fundo" ou "recortar" no app de fotos do seu iPhone ou Galaxy para recortar apenas o rosto da criança e salve em um formato quase quadrado.';
  String get guidePopupMethod2Title => '2. Use um serviço de IA';
  String get guidePopupMethod2Body =>
      'Escolha uma imagem quadrada de rider criada com um serviço externo de IA.';
  String get guidePopupPrivacyTitle =>
      '🔒 Por que o app não processa as imagens automaticamente?';
  String get guidePopupPrivacyBody =>
      'Para recortar ou converter rostos com precisão dentro do app, tecnicamente a foto original precisaria ser enviada para um servidor externo. Para proteger rigorosamente as fotos e a privacidade da criança, bloqueamos totalmente os envios para servidores e orientamos os pais a prepararem a imagem do rider por conta própria.';
  String get guidePopupSafetyTitle => '🛡️ Sua privacidade está protegida';
  String get guidePopupSafetyBody =>
      'A imagem que você prepara e adiciona fica salva apenas no dispositivo. Ela nunca é enviada a um servidor externo.';
  String get guidePopupConfirmButton => 'Confirmar';
}
