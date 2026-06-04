import '../models/vehicle.dart';

abstract final class AvatarPromptCatalog {
  static const _koreanBasePrompt = '''
첨부한 아이 사진을 참고해서 아이의 주요 얼굴 특징은 유지해 주세요.
귀엽고 친근한 캐릭터 스타일로 만들어 주세요.
정사각형 1:1 헤드샷 구도로, 얼굴 중앙에 배치해 주세요.
머리 전체 + 얼굴 + 목 일부가 보이게 하고, 어깨/몸통은 최소화해 주세요.
모바일 앱에 어울리는 단순하고 선명한 캐릭터풍 또는 부드러운 3D 캐릭터풍으로 만들어 주세요.
투명 배경을 권장합니다.
투명 배경이 어렵다면 단순한 흰색 또는 밝은 단색 배경으로 만들어 주세요.
텍스트, 로고, 워터마크 금지.
전신, 여러 사람, 복잡한 배경은 금지해 주세요.
''';

  static const _englishBasePrompt = '''
Use the attached child photo as reference and keep the child's main facial features.
Create a cute, friendly character-style square 1:1 headshot.
Place the face in the center, showing the full head, face, and a small part of the neck.
Minimize shoulders and torso.
Use a simple, clear character style or a soft 3D character style suitable for a mobile app.
A transparent background is recommended.
If transparency is difficult, use a simple white or bright solid background.
Do not include text, logos, or watermarks.
Avoid full-body images, multiple people, or complex backgrounds.
''';

  static const _koreanAdditionsByVehicleId = {
    'motorcycle': '''
오토바이 라이더 컨셉으로 만들어 주세요.
귀여운 헬멧을 씌워 주세요.
필요하면 고글/선글라스를 추가해도 됩니다.
얼굴은 가리지 않게 해 주세요.
''',
    'fire_truck': '''
소방관 라이더 컨셉으로 만들어 주세요.
소방관 헬멧 또는 소방관 모자를 씌워 주세요.
밝고 든든한 느낌으로 만들어 주세요.
''',
    'police_car': '''
경찰관 라이더 컨셉으로 만들어 주세요.
경찰 모자 또는 경찰 헬멧을 씌워 주세요.
밝고 자신감 있는 표정으로 만들어 주세요.
''',
    'excavator': '''
포크레인 기사 컨셉으로 만들어 주세요.
노란 안전모를 씌워 주세요.
필요하면 작업복 느낌은 아주 약하게 넣어 주세요.
얼굴 중심을 유지해 주세요.
''',
    'airplane': '''
비행기 조종사 컨셉으로 만들어 주세요.
파일럿 모자 또는 항공 헬멧을 씌워 주세요.
밝고 자신감 있는 표정으로 만들어 주세요.
''',
    'bus': '''
버스 기사 컨셉으로 만들어 주세요.
운전기사 모자 또는 단정한 모자를 씌워 주세요.
친근하고 든든한 느낌으로 만들어 주세요.
''',
    'supercar': '''
레이서 드라이버 컨셉으로 만들어 주세요.
스포티한 모자 또는 가벼운 헬멧을 씌워 주세요.
신나고 활기찬 표정으로 만들어 주세요.
''',
    'train': '''
기차 기관사 컨셉으로 만들어 주세요.
기관사 모자 또는 기차 승무원 느낌의 모자를 씌워 주세요.
차분하고 믿음직한 느낌으로 만들어 주세요.
''',
    't_rex': '''
티렉스 탐험가 컨셉으로 만들어 주세요.
귀여운 탐험가 모자 또는 공룡 테마 소품을 아주 약하게 넣어 주세요.
신나고 용감한 표정으로 만들어 주세요.
''',
    'shark': '''
상어 바다 탐험가 컨셉으로 만들어 주세요.
귀여운 선원 모자 또는 바다 테마 소품을 아주 약하게 넣어 주세요.
밝고 장난기 있는 표정으로 만들어 주세요.
''',
    'brachio': '''
브라키오 공룡 탐험가 컨셉으로 만들어 주세요.
귀여운 사파리 모자 또는 초록 공룡 테마 소품을 아주 약하게 넣어 주세요.
차분하고 다정한 표정으로 만들어 주세요.
''',
    'pteranodon': '''
프테라노돈 하늘 탐험가 컨셉으로 만들어 주세요.
귀여운 파일럿 고글 또는 하늘 테마 소품을 아주 약하게 넣어 주세요.
밝고 용감한 표정으로 만들어 주세요.
''',
  };

  static const _englishAdditionsByVehicleId = {
    'motorcycle': '''
Use a motorcycle rider concept.
Add a cute helmet.
Goggles or sunglasses are okay if needed.
Do not cover the face.
''',
    'fire_truck': '''
Use a firefighter rider concept.
Add a firefighter helmet or firefighter hat.
Make the character feel bright and dependable.
''',
    'police_car': '''
Use a police officer rider concept.
Add a police hat or police helmet.
Use a bright, confident expression.
''',
    'excavator': '''
Use an excavator operator concept.
Add a yellow safety helmet.
If needed, add only a very subtle workwear feeling.
Keep the face centered.
''',
    'airplane': '''
Use an airplane pilot concept.
Add a pilot hat or aviation helmet.
Use a bright, confident expression.
''',
    'bus': '''
Use a bus driver concept.
Add a driver hat or neat cap.
Make the character feel friendly and dependable.
''',
    'supercar': '''
Use a race driver concept.
Add a sporty cap or light helmet.
Use an excited, energetic expression.
''',
    'train': '''
Use a train engineer concept.
Add a train engineer hat or conductor-style cap.
Make the character feel calm and reliable.
''',
    't_rex': '''
Use a T-rex explorer concept.
Add a cute explorer hat or very subtle dinosaur-themed detail.
Use an excited, brave expression.
''',
    'shark': '''
Use a shark ocean explorer concept.
Add a cute sailor hat or very subtle ocean-themed detail.
Use a bright, playful expression.
''',
    'brachio': '''
Use a brachio dinosaur explorer concept.
Add a cute safari hat or very subtle green dinosaur-themed detail.
Use a calm, kind expression.
''',
    'pteranodon': '''
Use a pteranodon sky explorer concept.
Add cute pilot goggles or very subtle sky-themed detail.
Use a bright, brave expression.
''',
  };

  static String promptForVehicle(
    VehicleDefinition vehicle,
    String languageCode,
  ) {
    final isKorean = languageCode == 'ko';
    final basePrompt = isKorean ? _koreanBasePrompt : _englishBasePrompt;
    final additions = isKorean
        ? _koreanAdditionsByVehicleId
        : _englishAdditionsByVehicleId;
    final vehiclePrompt = additions[vehicle.id] ?? '';

    return '$basePrompt\n$vehiclePrompt'.trim();
  }
}
