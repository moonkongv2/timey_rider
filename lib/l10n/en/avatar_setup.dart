// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnAvatarSetupTexts implements AvatarSetupTextSet {
  const EnAvatarSetupTexts();

  String get title => "Create Your Child's Rider Image";
  String get intro =>
      "Use an external AI service to create a rider image for Timey Rider, then upload the finished image here.";
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
  List<String> get guideItems => const [
    "Use a front-facing photo where your child's face is easy to see.",
    'A large, clear face works best.',
    'Avoid photos where hats, masks, hands, or other objects cover the face.',
    'A square 1:1 result works best.',
    'Use a transparent or simple background.',
    'Do not include text, logos, or watermarks.',
  ];
  String get promptCopyTitle => 'Rider image prompt';
  String get promptHelperText =>
      'This rider image prompt matches the selected vehicle. Paste it into an external AI service.';
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
}
