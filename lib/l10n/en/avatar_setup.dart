// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class EnAvatarSetupTexts implements AvatarSetupTextSet {
  const EnAvatarSetupTexts();

  String get title => "Create Your Child's Avatar";
  String get intro =>
      "Use an external AI service to turn your child's photo into a cute rider character, then upload the finished image here.";
  String get selectedVehicleTitle => 'Selected vehicle';
  String get currentAvatarModeTitle => 'Avatar mode';
  String get defaultImageMode => 'Use default image';
  String get customAvatarMode => 'Use custom avatar';
  String get copyPromptMessage =>
      'Prompt copied. Paste it into your external AI service.';
  String get avatarSaveFailureMessage => 'Could not save the avatar image.';
  String get avatarSavedMessage => 'Avatar saved.';
  String get defaultImageSavedMessage => 'Switched to the default image.';
  String get missingAvatarWarning =>
      'Avatar image not found. Showing the default image instead.';
  String get vehicleSelectionTitle => 'Vehicle for this avatar';
  String get vehicleSelectionSubtitle => 'Prompt reference';
  String get compositePreviewTitle => 'Composite preview';
  String get compositePreviewSubtitle => 'Use this look for Timey Rider?';
  String get defaultPreviewTitle => 'Default image preview';
  String get useDefaultImageButton => 'Use default image';
  String get adjustmentTitle => 'Adjust avatar position';
  String get faceSizeLabel => 'Face size';
  String get horizontalPositionLabel => 'Horizontal position';
  String get verticalPositionLabel => 'Vertical position';
  String get rotationLabel => 'Tilt';
  String get resetPositionButton => 'Reset position';
  String get confirmAvatarButton => 'Use this avatar';
  String get guideTitle => 'Image generation guide';
  List<String> get guideItems => const [
    "Use a front-facing photo where your child's face is easy to see.",
    'A large, clear face works best.',
    'Avoid photos where hats, masks, hands, or other objects cover the face.',
    'A square 1:1 result works best.',
    'Use a transparent or simple background.',
    'Do not include text, logos, or watermarks.',
  ];
  String get promptCopyTitle => 'Avatar generation prompt';
  String get promptHelperText =>
      'This prompt matches the selected vehicle. Paste it into an external AI service.';
  String get promptExpandLabel => 'Open prompt';
  String get promptCollapseLabel => 'Close prompt';
  String get promptToggleSemanticLabel =>
      'Open or close the avatar generation prompt';
  String get copyPromptButton => 'Copy prompt';
  String get uploadTitle => 'Upload avatar image';
  String get uploadInstructions =>
      'Upload a square avatar image made with generative AI.\n'
      'It works best when the face is centered and the background is simple.';
  String get uploadingButton => 'Uploading';
  String get reuploadButton => 'Upload again';
  String get uploadButton => 'Upload avatar image';
  String get selectedImageFallback => 'Selected avatar image';
  String get privacyNote =>
      "This app does not generate AI images or upload your child's photo itself.\n"
      'Create the image with an external AI service you choose, then upload only the finished avatar image to Timey Rider.\n'
      'Check the photo and privacy policies before using an external service.';
}
