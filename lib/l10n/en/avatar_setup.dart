// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnAvatarSetupTexts implements AvatarSetupTextSet {
  const EnAvatarSetupTexts();

  String get title => "Create Your Child's Rider Image";
  String get intro =>
      "Create a rider image for Timey Rider, then upload the finished image here.";
  String get selectedVehicleTitle => 'Selected vehicle';
  String get currentAvatarModeTitle => 'Rider image mode';
  String get defaultImageMode => 'Use default image';
  String get customAvatarMode => 'Use custom rider';
  String get copyPromptMessage =>
      'Prompt copied. Paste it into your external AI service.';
  String get avatarSaveFailureMessage => 'Could not save the rider image.';
  String get avatarSavedMessage => 'Rider saved.';
  String get defaultImageSavedMessage => 'Switched to the default image.';
  String get missingAvatarWarning =>
      'Rider image not found. Showing the default image instead.';
  String get vehicleSelectionTitle => 'Vehicle for this rider';
  String get vehicleSelectionSubtitle => 'Prompt reference';
  String get compositePreviewTitle => 'Composite preview';
  String get compositePreviewSubtitle => 'Use this look for Timey Rider?';
  String get defaultPreviewTitle => 'Default image preview';
  String get useDefaultImageButton => 'Use default image';
  String get adjustmentTitle => 'Adjust rider position';
  String get faceSizeLabel => 'Face size';
  String get horizontalPositionLabel => 'Horizontal position';
  String get verticalPositionLabel => 'Vertical position';
  String get rotationLabel => 'Tilt';
  String get resetPositionButton => 'Reset position';
  String get confirmAvatarButton => 'Use this rider';
  String get guideTitle => 'Rider image guide';
  String get guideIntro =>
      'The app does not cut out faces itself. Prepare a rider image for the vehicle with one of the methods below.';
  String get promptCopyTitle => 'Rider image prompt (example)';
  String get promptHelperText =>
      'When using an AI service, copy the vehicle-specific prompt below and paste it into the external AI service.';
  String get promptExpandLabel => 'Open prompt';
  String get promptCollapseLabel => 'Close prompt';
  String get promptToggleSemanticLabel =>
      'Open or close the rider image prompt';
  String get copyPromptButton => 'Copy prompt';
  String get uploadTitle => 'Upload rider image';
  String get uploadInstructions =>
      'Upload a square rider image made with an external AI service.\n'
      'It works best when the child face is centered on a transparent background.';
  String get uploadingButton => 'Uploading';
  String get reuploadButton => 'Upload again';
  String get uploadButton => 'Upload rider image';
  String get selectedImageFallback => 'Selected rider image';
  String get privacyNote =>
      "This app does not create AI images or upload your child's photo itself.\n"
      'Create the image with an external AI service you choose, then upload only the finished rider image to Timey Rider.\n'
      'Check the photo and privacy policies before using an external service.';

  String get guidePopupTitle => "Create Your Child's Rider Guide";
  String get guideReplayTooltip => 'View guide again';
  String get guidePopupMethodTitle => '📸 How to Prepare a Rider Image';
  String get guidePopupMethodIntro =>
      'The app does not have a built-in feature to cut out faces. Please prepare the image of your child\'s face to place in the vehicle yourself, as shown in the example above.';
  String get guidePopupMethod1Title => '1. Use a Smartphone Photo App';
  String get guidePopupMethod1Body =>
      'Use the "Remove Background" or "Cutout" feature in your Galaxy or iPhone\'s default photo app to crop just your child\'s face and save it in a nearly square shape.';
  String get guidePopupMethod2Title => '2. Use an AI Service';
  String get guidePopupMethod2Body =>
      '“Please upload a square rider image created using an external AI service.”';
  String get guidePopupPrivacyTitle =>
      '🔒 Why doesn\'t the app process images automatically?';
  String get guidePopupPrivacyBody =>
      'To precisely cut out or convert faces within the app, the original photo would technically need to be sent to an external server. To strictly protect your child\'s photos and privacy, we block server transmissions entirely and guide parents to prepare the rider image themselves.';
  String get guidePopupSafetyTitle => '🛡️ Safely protected! Rest assured!';
  String get guidePopupSafetyBody =>
      'The rider image you prepare and register in this app is safely stored ONLY on your device. It is never transmitted to any external server, so there is absolutely no risk of your personal information being leaked. Please register with peace of mind.';
  String get guidePopupConfirmButton => 'Confirm';
}
