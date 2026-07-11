import '../models/vehicle.dart';

abstract final class AvatarPromptCatalog {
  static const _koreanBasePrompt = '''
첨부한 아이 사진을 참고해서 Timey Rider에 사용할 라이더 이미지를 만들어 주세요.
아이의 실제 얼굴 특징을 최대한 유지해 주세요.
새로운 캐릭터처럼 바꾸지 말고, 아이 본인처럼 알아볼 수 있게 만들어 주세요.
정사각형 1:1 이미지로, 얼굴이 중앙에 크게 보이게 해 주세요.
머리카락 끝부터 턱 끝까지 머리 전체와 얼굴만 딱 잘라낸 이미지로 만들어 주세요.
목, 어깨, 몸통, 옷, 손, 전신, 차량 이미지는 절대 포함하지 마세요.
머리 일부가 잘리지 않게 하고, 얼굴 외곽에는 최소한의 여백만 남겨 주세요.
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
Create a tight cutout of only the full head and face, from the top of the hair to the bottom of the chin.
Do not include the neck, shoulders, torso, clothes, hands, full body, or vehicle image.
Do not crop off any part of the head, and leave only minimal padding around the face.
The background must be transparent.
Use a transparent PNG if possible.
Do not add shadows, background colors, or background decorations.
Do not include text, logos, or watermarks.
Avoid multiple people, complex props, or major outfit changes.
''';

  static const _japaneseBasePrompt = '''
添付したお子さまの写真を参考にして、Timey Riderで使うライダー画像を作ってください。
お子さま本人の顔立ちや特徴をできるだけ保ってください。
別人のキャラクターに変えず、お子さまだと分かる見た目にしてください。
正方形1:1の画像で、顔が大きく中央に見えるようにしてください。
髪の上端からあごの下まで、頭全体と顔だけをきれいに切り抜いた画像にしてください。
首、肩、胴体、服、手、全身、乗り物の画像は入れないでください。
頭の一部が切れないようにし、顔の周りの余白は最小限にしてください。
背景は透明にしてください。
可能なら透明背景のPNGにしてください。
透明背景が難しい場合は、白または明るい単色背景にしてください。
影、背景装飾、複雑な背景は入れないでください。
文字、ロゴ、透かしは入れないでください。
全身画像、複数人、複雑な小物、大きな服装変更は避けてください。
''';

  static const _spanishBasePrompt = '''
Usa la foto adjunta del niño o la niña para crear una imagen de rider para Timey Rider.
Conserva sus rasgos faciales reales tanto como sea posible.
No lo conviertas en un personaje distinto; debe seguir siendo reconocible.
Crea una imagen cuadrada 1:1, con la cara grande y centrada.
Haz un recorte ajustado solo de la cabeza completa y la cara, desde la parte superior del cabello hasta la parte inferior de la barbilla.
No incluyas cuello, hombros, torso, ropa, manos, cuerpo completo ni imagen de vehículo.
No cortes ninguna parte de la cabeza y deja solo un margen mínimo alrededor de la cara.
El fondo debe ser transparente.
Usa PNG con fondo transparente si es posible.
Si el fondo transparente es difícil, usa un fondo blanco o de color sólido claro.
No añadas sombras, decoración de fondo ni fondos complejos.
No incluyas texto, logotipos ni marcas de agua.
Evita imágenes de cuerpo completo, varias personas, accesorios complejos o cambios grandes de ropa.
''';

  static const _portugueseBasePrompt = '''
Use a foto anexada da criança para criar uma imagem de rider para o Timey Rider.
Preserve ao máximo as características reais do rosto da criança.
Não transforme a criança em um personagem diferente; ela ainda deve ser reconhecível.
Crie uma imagem quadrada 1:1, com o rosto grande e centralizado.
Faça um recorte justo somente da cabeça completa e do rosto, do topo do cabelo até a parte de baixo do queixo.
Não inclua pescoço, ombros, tronco, roupas, mãos, corpo inteiro nem imagem de veículo.
Não corte nenhuma parte da cabeça e deixe apenas uma margem mínima ao redor do rosto.
O fundo deve ser transparente.
Use PNG com fundo transparente, se possível.
Se o fundo transparente for difícil, use um fundo branco ou uma cor sólida clara.
Não adicione sombras, enfeites de fundo nem fundos complexos.
Não inclua texto, logotipos nem marcas-d'água.
Evite imagens de corpo inteiro, várias pessoas, objetos complexos ou grandes mudanças de roupa.
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

  static const _japaneseAdditionsByVehicleId = {
    'motorcycle': '''
オートバイのライダーに合う、ごく控えめな小さなヘルメット風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    'fire_truck': '''
消防車のライダーに合う、ごく控えめな小さな消防士ヘルメット風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    'police_car': '''
警察官ライダーに合う、ごく控えめな小さな警察帽風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    'excavator': '''
ショベルカーのオペレーターに合う、ごく控えめな小さな黄色い安全ヘルメット風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    'airplane': '''
飛行機のパイロットに合う、ごく控えめな小さなパイロット帽風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    'bus': '''
バスの運転手に合う、ごく控えめな小さな運転手帽風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    'supercar': '''
レーシングドライバーに合う、ごく控えめな小さなレーサーキャップ風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    'train': '''
電車の運転士に合う、ごく控えめな小さな制帽風の要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、乗り物自体は作らないでください。
''',
    't_rex': '''
T-rex探検家に合う、ごく控えめな小さな恐竜テーマの要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、恐竜の体や乗り物画像は作らないでください。
''',
    'shark': '''
サメの海の探検家に合う、ごく控えめな小さな海テーマの要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、サメの体や乗り物画像は作らないでください。
''',
    'brachio': '''
ブラキオサウルス探検家に合う、ごく控えめな小さな緑の恐竜テーマの要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、恐竜の体や乗り物画像は作らないでください。
''',
    'pteranodon': '''
プテラノドンの空の探検家に合う、ごく控えめな小さな空テーマの要素を加えてもかまいません。
ただし、お子さまの顔を隠さず、恐竜の体や乗り物画像は作らないでください。
''',
  };

  static const _spanishAdditionsByVehicleId = {
    'motorcycle': '''
Puedes añadir un detalle muy sutil de casco pequeño para que encaje con el rider de moto.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    'fire_truck': '''
Puedes añadir un detalle muy sutil de casco de bombero pequeño para que encaje con el rider de camión de bomberos.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    'police_car': '''
Puedes añadir un detalle muy sutil de gorra de policía pequeña para que encaje con el rider policía.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    'excavator': '''
Puedes añadir un detalle muy sutil de casco amarillo pequeño para que encaje con el operador de excavadora.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    'airplane': '''
Puedes añadir un detalle muy sutil de gorra de piloto pequeña para que encaje con el piloto de avión.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    'bus': '''
Puedes añadir un detalle muy sutil de gorra de conductor pequeña para que encaje con el conductor de autobús.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    'supercar': '''
Puedes añadir un detalle muy sutil de gorra de piloto de carreras para que encaje con el conductor de carreras.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    'train': '''
Puedes añadir un detalle muy sutil de gorra de maquinista para que encaje con el conductor de tren.
No cubras la cara del niño o la niña, y no crees la imagen del vehículo.
''',
    't_rex': '''
Puedes añadir un detalle muy sutil de explorador con tema de T-rex.
No cubras la cara del niño o la niña, y no crees un cuerpo de dinosaurio ni una imagen de vehículo.
''',
    'shark': '''
Puedes añadir un detalle muy sutil de explorador del océano con tema de tiburón.
No cubras la cara del niño o la niña, y no crees un cuerpo de tiburón ni una imagen de vehículo.
''',
    'brachio': '''
Puedes añadir un detalle muy sutil de explorador de dinosaurios con tema de braquiosaurio.
No cubras la cara del niño o la niña, y no crees un cuerpo de dinosaurio ni una imagen de vehículo.
''',
    'pteranodon': '''
Puedes añadir un detalle muy sutil de explorador del cielo con tema de pteranodon.
No cubras la cara del niño o la niña, y no crees un cuerpo de dinosaurio ni una imagen de vehículo.
''',
  };

  static const _portugueseAdditionsByVehicleId = {
    'motorcycle': '''
Você pode adicionar um detalhe bem sutil de capacete pequeno para combinar com o rider de moto.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    'fire_truck': '''
Você pode adicionar um detalhe bem sutil de capacete de bombeiro pequeno para combinar com o rider bombeiro.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    'police_car': '''
Você pode adicionar um detalhe bem sutil de boné de policial pequeno para combinar com o rider policial.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    'excavator': '''
Você pode adicionar um detalhe bem sutil de capacete amarelo pequeno para combinar com o operador de escavadeira.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    'airplane': '''
Você pode adicionar um detalhe bem sutil de quepe de piloto pequeno para combinar com o piloto de avião.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    'bus': '''
Você pode adicionar um detalhe bem sutil de boné de motorista pequeno para combinar com o motorista de ônibus.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    'supercar': '''
Você pode adicionar um detalhe bem sutil de boné de piloto de corrida para combinar com o piloto de corrida.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    'train': '''
Você pode adicionar um detalhe bem sutil de quepe de maquinista para combinar com o maquinista de trem.
Não cubra o rosto da criança e não crie a imagem do veículo.
''',
    't_rex': '''
Você pode adicionar um detalhe bem sutil de explorador com tema de T-rex.
Não cubra o rosto da criança e não crie corpo de dinossauro nem imagem de veículo.
''',
    'shark': '''
Você pode adicionar um detalhe bem sutil de explorador do oceano com tema de tubarão.
Não cubra o rosto da criança e não crie corpo de tubarão nem imagem de veículo.
''',
    'brachio': '''
Você pode adicionar um detalhe bem sutil de explorador de dinossauros com tema de braquiossauro.
Não cubra o rosto da criança e não crie corpo de dinossauro nem imagem de veículo.
''',
    'pteranodon': '''
Você pode adicionar um detalhe bem sutil de explorador do céu com tema de pteranodonte.
Não cubra o rosto da criança e não crie corpo de dinossauro nem imagem de veículo.
''',
  };

  static String promptForVehicle(
    VehicleDefinition vehicle,
    String languageCode,
  ) {
    final basePrompt = switch (languageCode) {
      'ko' => _koreanBasePrompt,
      'ja' => _japaneseBasePrompt,
      'es' => _spanishBasePrompt,
      'pt' => _portugueseBasePrompt,
      _ => _englishBasePrompt,
    };
    final additions = switch (languageCode) {
      'ko' => _koreanAdditionsByVehicleId,
      'ja' => _japaneseAdditionsByVehicleId,
      'es' => _spanishAdditionsByVehicleId,
      'pt' => _portugueseAdditionsByVehicleId,
      _ => _englishAdditionsByVehicleId,
    };
    final vehiclePrompt = additions[vehicle.id] ?? '';

    return '$basePrompt\n$vehiclePrompt'.trim();
  }
}
