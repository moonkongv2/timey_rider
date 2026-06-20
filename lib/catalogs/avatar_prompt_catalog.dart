import '../models/vehicle.dart';

abstract final class AvatarPromptCatalog {
  static const _koreanBasePrompt = '''
첨부한 아이 사진을 참고해서 Timey Rider에 사용할 라이더 이미지를 만들어 주세요.
아이의 실제 얼굴 특징을 최대한 유지해 주세요.
새로운 캐릭터처럼 바꾸지 말고, 아이 본인처럼 알아볼 수 있게 만들어 주세요.
정사각형 1:1 이미지로, 얼굴이 중앙에 크게 보이게 해 주세요.
머리 전체와 얼굴이 보이게 하고, 몸통/전신/차량 이미지는 만들지 마세요.
배경은 반드시 투명 배경으로 만들어 주세요.
가능하면 PNG 투명 배경으로 만들어 주세요.
그림자, 배경색, 배경 장식은 넣지 마세요.
텍스트, 로고, 워터마크 금지.
여러 사람, 복잡한 소품, 과한 의상 변화는 피해주세요.
''';

  static const _englishBasePrompt = '''
Use the attached child photo to create a rider image for Timey Rider.
Preserve the child's real facial features as much as possible.
Do not turn the child into a new character. The child should still be recognizable.
Use a square 1:1 image with the face large and centered.
Show the full head and face, but do not create a full body, torso, or vehicle image.
The background must be transparent.
Use a transparent PNG if possible.
Do not add shadows, background colors, or background decorations.
Do not include text, logos, or watermarks.
Avoid multiple people, complex props, or major outfit changes.
''';

  static const _koreanAdditionsByVehicleId = {
    'motorcycle': '''
오토바이에 어울리도록 작은 헬멧 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    'fire_truck': '''
소방차에 어울리도록 작은 소방관 헬멧 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    'police_car': '''
경찰차에 어울리도록 작은 경찰 모자 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    'excavator': '''
포크레인에 어울리도록 작은 노란 안전모 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    'airplane': '''
비행기에 어울리도록 작은 파일럿 모자 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    'bus': '''
버스에 어울리도록 작은 운전기사 모자 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    'supercar': '''
슈퍼카에 어울리도록 작은 레이서 모자 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    'train': '''
기차에 어울리도록 작은 기관사 모자 느낌을 아주 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 차량 이미지는 만들지 마세요.
''',
    't_rex': '''
티렉스에 어울리도록 아주 작은 공룡 테마 소품을 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 티렉스 몸이나 차량 이미지는 만들지 마세요.
''',
    'shark': '''
상어에 어울리도록 아주 작은 바다 테마 소품을 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 상어 몸이나 차량 이미지는 만들지 마세요.
''',
    'brachio': '''
브라키오에 어울리도록 아주 작은 초록 공룡 테마 소품을 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 공룡 몸이나 차량 이미지는 만들지 마세요.
''',
    'pteranodon': '''
프테라노돈에 어울리도록 아주 작은 하늘 테마 소품을 약하게 넣어도 됩니다.
단, 아이 얼굴을 가리지 말고 공룡 몸이나 차량 이미지는 만들지 마세요.
''',
  };

  static const _englishAdditionsByVehicleId = {
    'motorcycle': '''
You may add a very subtle small helmet detail to match the motorcycle.
Do not cover the child's face, and do not create the vehicle itself.
''',
    'fire_truck': '''
You may add a very subtle small firefighter helmet detail to match the fire truck.
Do not cover the child's face, and do not create the vehicle itself.
''',
    'police_car': '''
You may add a very subtle small police hat detail to match the police car.
Do not cover the child's face, and do not create the vehicle itself.
''',
    'excavator': '''
You may add a very subtle small yellow safety helmet detail to match the excavator.
Do not cover the child's face, and do not create the vehicle itself.
''',
    'airplane': '''
You may add a very subtle small pilot hat detail to match the airplane.
Do not cover the child's face, and do not create the vehicle itself.
''',
    'bus': '''
You may add a very subtle small driver hat detail to match the bus.
Do not cover the child's face, and do not create the vehicle itself.
''',
    'supercar': '''
You may add a very subtle small racer cap detail to match the supercar.
Do not cover the child's face, and do not create the vehicle itself.
''',
    'train': '''
You may add a very subtle small train engineer hat detail to match the train.
Do not cover the child's face, and do not create the vehicle itself.
''',
    't_rex': '''
You may add a very subtle small dinosaur-themed detail to match the T-rex.
Do not cover the child's face, and do not create a dinosaur body or vehicle image.
''',
    'shark': '''
You may add a very subtle small ocean-themed detail to match the shark.
Do not cover the child's face, and do not create a shark body or vehicle image.
''',
    'brachio': '''
You may add a very subtle small green dinosaur-themed detail to match the brachio.
Do not cover the child's face, and do not create a dinosaur body or vehicle image.
''',
    'pteranodon': '''
You may add a very subtle small sky-themed detail to match the pteranodon.
Do not cover the child's face, and do not create a dinosaur body or vehicle image.
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
