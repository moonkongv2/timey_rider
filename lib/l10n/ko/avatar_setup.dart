// ignore_for_file: annotate_overrides

import '../text_sets.dart';

class AvatarSetupTexts implements AvatarSetupTextSet {
  const AvatarSetupTexts();

  String get title => '우리 아이 라이더 만들기';
  String get intro => 'Timey Rider에 사용할 아이 라이더 이미지를 만든 뒤 선택해 주세요.';
  String get selectedVehicleTitle => '현재 선택한 차량';
  String get currentAvatarModeTitle => '현재 라이더 모드';
  String get defaultImageMode => '기본 이미지 사용';
  String get customAvatarMode => '직접 만든 라이더 사용';
  String get copyPromptMessage => '프롬프트를 복사했어요. 외부 AI 서비스에 붙여넣어 사용해 주세요.';
  String get avatarSaveFailureMessage => '라이더 이미지를 저장하지 못했어요.';
  String get avatarSavedMessage => '라이더를 저장했어요.';
  String get defaultImageSavedMessage => '기본 이미지로 변경했어요.';
  String get missingAvatarWarning => '라이더 이미지를 찾을 수 없어 기본 이미지로 보여드려요.';
  String get vehicleSelectionTitle => '라이더를 태울 차량';
  String get vehicleSelectionSubtitle => '프롬프트 기준';
  String get compositePreviewTitle => '합성 미리보기';
  String get compositePreviewSubtitle => '이 모습으로 Timey Rider를 탈까요?';
  String get defaultPreviewTitle => '기본 이미지 미리보기';
  String get useDefaultImageButton => '기본 이미지로 사용하기';
  String get adjustmentTitle => '라이더 위치 조정';
  String get faceSizeLabel => '얼굴 크기';
  String get horizontalPositionLabel => '좌우 위치';
  String get verticalPositionLabel => '위아래 위치';
  String get rotationLabel => '기울기';
  String get resetPositionButton => '위치 초기화';
  String get confirmAvatarButton => '이 라이더로 사용하기';
  String get guideTitle => '라이더 이미지 만들기 가이드';
  String get guideIntro =>
      '앱에서 직접 얼굴을 오려내지는 않으니, 아래 방법 중 하나로 차량에 넣을 라이더 이미지를 준비해 주세요.';
  String get promptCopyTitle => '라이더 이미지 프롬프트 (예시)';
  String get promptHelperText =>
      'AI 서비스로 만들 때는 선택한 차량에 맞춘 아래 프롬프트를 복사해 붙여넣어 주세요.';
  String get promptGuideHint => '아래 예시 프롬프트를 복사해 AI 서비스에 붙여넣어 활용해 보세요.';
  String get promptExpandLabel => '프롬프트 열기';
  String get promptCollapseLabel => '프롬프트 접기';
  String get promptToggleSemanticLabel => '라이더 이미지 프롬프트 열고 닫기';
  String get copyPromptButton => '프롬프트 복사하기';
  String get uploadTitle => '라이더 이미지 가져오기';
  String get uploadInstructions =>
      '사진 앱이나 외부 AI 서비스에서 만든 정사각형 라이더 이미지를 선택해 주세요.\n'
      '아이 얼굴이 중앙에 있고 투명 배경이면 가장 자연스러워요.';
  String get uploadingButton => '가져오는 중';
  String get reuploadButton => '다시 선택';
  String get uploadButton => '라이더 이미지 선택';
  String get selectedImageFallback => '선택한 라이더 이미지';
  String get privacyNote =>
      '앱이 직접 AI 이미지를 만들거나 아이 사진을 업로드하지는 않아요.\n'
      '이 기기에서 완성된 라이더 이미지를 선택하면 Timey Rider가 로컬에만 저장하고 서버로 보내지 않아요.\n'
      '외부 서비스 이용 전 사진/개인정보 처리 방침을 확인해 주세요.';

  String get guidePopupTitle => '우리 아이 라이더 만들기 안내';
  String get guideReplayTooltip => '안내 다시 보기';
  String get guidePopupMethodTitle => '📸 라이더 이미지 준비 방법';
  String get guidePopupMethodIntro =>
      '앱 자체에는 얼굴만 오려내는 기능이 없습니다. 위 예시처럼 차량에 쏙 들어갈 아이의 얼굴 이미지를 준비해 주세요.';
  String get guidePopupMethod1Title => '1. 스마트폰 기본 사진 앱 활용하기';
  String get guidePopupMethod1Body =>
      '갤럭시나 아이폰의 기본 사진 앱에서 제공하는 \'피사체 오려내기(배경 지우기)\' 기능을 사용해 아이의 얼굴 부분만 정사각형에 가깝게 잘라내어 저장해 주세요.';
  String get guidePopupMethod2Title => '2. AI 서비스 활용하기';
  String get guidePopupMethod2Body => '“외부 AI 서비스에서 만든 정사각형 라이더 이미지를 선택해 주세요.”';
  String get guidePopupPrivacyTitle => '🔒 왜 앱에서 자동으로 이미지를 처리하지 않나요?';
  String get guidePopupPrivacyBody =>
      '앱 내에서 사진을 정교하게 오려내거나 변환하려면, 기술적으로 원본 사진을 외부 서버로 전송해 처리해야 합니다. 저희는 소중한 아이의 사진과 프라이버시를 철저하게 보호하기 위해, 서버 전송을 완전히 차단하고 부모님께서 직접 라이더 이미지를 준비해 주시도록 안내하고 있습니다.';
  String get guidePopupSafetyTitle => '🛡️ 안전하게 보호됩니다! 절대 안심하세요!';
  String get guidePopupSafetyBody =>
      '부모님께서 준비해 이 앱에 등록하신 라이더 이미지는 오직 사용 중이신 스마트폰 기기 내부에만 안전하게 저장됩니다. 앱 외부의 어떤 서버로도 절대 전송되지 않으며, 개인정보가 유출될 위험은 전혀 없으니 안심하고 등록해 주세요.';
  String get guidePopupConfirmButton => '확인';
}
