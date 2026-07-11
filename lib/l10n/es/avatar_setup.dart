// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EsAvatarSetupTexts implements AvatarSetupTextSet {
  const EsAvatarSetupTexts();

  String get title => 'Crear el rider de tu peque';
  String get intro =>
      "Crea una imagen de rider para Timey Rider y luego elige aquí la imagen terminada.";
  String get selectedVehicleTitle => 'Vehículo seleccionado';
  String get currentAvatarModeTitle => 'Modo de imagen del rider';
  String get defaultImageMode => 'Usar imagen predeterminada';
  String get customAvatarMode => 'Usar rider personalizado';
  String get copyPromptMessage =>
      'Prompt copiado. Pégalo en tu servicio de IA externo.';
  String get avatarSaveFailureMessage => 'No se pudo guardar la imagen.';
  String get avatarSavedMessage => 'Rider guardado.';
  String get defaultImageSavedMessage =>
      'Se cambió a la imagen predeterminada.';
  String get missingAvatarWarning =>
      'No se encontró la imagen del rider. Se mostrará la imagen predeterminada.';
  String get vehicleSelectionTitle => 'Vehículo para este rider';
  String get vehicleSelectionSubtitle => 'Referencia del prompt';
  String get compositePreviewTitle => 'Vista previa del rider';
  String get compositePreviewSubtitle => '¿Usar este aspecto en Timey Rider?';
  String get defaultPreviewTitle => 'Vista previa predeterminada';
  String get useDefaultImageButton => 'Usar imagen predeterminada';
  String get adjustmentTitle => 'Ajustar posición del rider';
  String get faceSizeLabel => 'Tamaño de la cara';
  String get horizontalPositionLabel => 'Posición horizontal';
  String get verticalPositionLabel => 'Posición vertical';
  String get rotationLabel => 'Inclinación';
  String get resetPositionButton => 'Restablecer posición';
  String get confirmAvatarButton => 'Usar este rider';
  String get guideTitle => 'Guía de imagen del rider';
  String get guideIntro =>
      'La app no recorta caras por sí sola. Prepara una imagen de rider para el vehículo con uno de los métodos de abajo.';
  String get promptCopyTitle => 'Prompt de imagen del rider (ejemplo)';
  String get promptHelperText =>
      'Si usas un servicio de IA, copia el prompt específico del vehículo y pégalo en el servicio externo.';
  String get promptGuideHint =>
      'Copia el prompt de ejemplo y pégalo en tu servicio de IA.';
  String get promptExpandLabel => 'Abrir prompt';
  String get promptCollapseLabel => 'Cerrar prompt';
  String get promptToggleSemanticLabel =>
      'Abrir o cerrar el prompt de imagen del rider';
  String get copyPromptButton => 'Copiar prompt';
  String get uploadTitle => 'Importar imagen del rider';
  String get uploadInstructions =>
      'Elige una imagen cuadrada creada con una app de fotos o un servicio externo de IA.\n'
      "Funciona mejor si la cara está centrada sobre fondo transparente.";
  String get uploadingButton => 'Importando';
  String get reuploadButton => 'Elegir de nuevo';
  String get uploadButton => 'Elegir imagen del rider';
  String get selectedImageFallback => 'Imagen del rider seleccionada';
  String get privacyNote =>
      "Esta app no crea imágenes de IA ni sube la foto del niño por sí misma.\n"
      'Elige una imagen terminada desde este dispositivo. Timey Rider la guarda localmente y no la envía a un servidor.\n'
      'Revisa las políticas de fotos y privacidad antes de usar un servicio externo.';

  String get guidePopupTitle => 'Crear el rider de tu peque';
  String get guideReplayTooltip => 'Ver guía de nuevo';
  String get guidePopupMethodTitle => '📸 Cómo preparar una imagen de rider';
  String get guidePopupMethodIntro =>
      'La app no tiene una función integrada para recortar caras. Prepara tú la imagen de la cara para colocarla en el vehículo, como en el ejemplo.';
  String get guidePopupMethod1Title => '1. Usar una app de fotos';
  String get guidePopupMethod1Body =>
      'Usa la función de "recortar" o "eliminar fondo" en la app de fotos de tu iPhone o Galaxy para recortar solo la cara de tu peque y guárdala en formato casi cuadrado.';
  String get guidePopupMethod2Title => '2. Usar un servicio de IA';
  String get guidePopupMethod2Body =>
      'Elige una imagen cuadrada de rider creada con un servicio externo de IA.';
  String get guidePopupPrivacyTitle =>
      '🔒 ¿Por qué la app no procesa las imágenes automáticamente?';
  String get guidePopupPrivacyBody =>
      'Para recortar o procesar caras con precisión dentro de la app, técnicamente la foto original tendría que enviarse a un servidor externo. Para proteger estrictamente las fotos y la privacidad de tu peque, bloqueamos por completo las transmisiones a servidores y pedimos a los padres que preparen la imagen del rider ellos mismos.';
  String get guidePopupSafetyTitle => '🛡️ Tu privacidad está protegida';
  String get guidePopupSafetyBody =>
      'La imagen que prepares y añadas se guarda solo en tu dispositivo. Nunca se envía a un servidor externo.';
  String get guidePopupConfirmButton => 'Confirmar';
}
