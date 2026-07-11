import '../models/vehicle.dart';

abstract final class VehicleCatalog {
  // Avatar slots are placeholders and need visual tuning against the real assets.
  static const motorcycle = VehicleDefinition(
    id: 'motorcycle',
    labelKo: '오토바이',
    labelEn: 'Motorcycle',
    labelJa: 'バイク',
    labelEs: 'Moto',
    labelPtBr: 'Moto',
    emoji: '🏍️',
    assetPath: 'assets/images/vehicle_motorcycle.png',
    selectionAssetPath: 'assets/images/vehicle_motorcycle_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.57,
      centerY: 0.31,
      sizeRatio: 0.28,
    ),
    roadAnchorOffset: VehicleRoadAnchorOffset(
      portraitDyRatio: -0.08,
      landscapeDyRatio: -0.05,
    ),
  );

  static const fireTruck = VehicleDefinition(
    id: 'fire_truck',
    labelKo: '소방차',
    labelEn: 'Fire truck',
    labelJa: '消防車',
    labelEs: 'Camión de bomberos',
    labelPtBr: 'Caminhão de bombeiros',
    emoji: '🚒',
    assetPath: 'assets/images/vehicle_fire_truck.png',
    selectionAssetPath: 'assets/images/vehicle_fire_truck_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.57,
      centerY: 0.30,
      sizeRatio: 0.26,
    ),
  );

  static const policeCar = VehicleDefinition(
    id: 'police_car',
    labelKo: '경찰차',
    labelEn: 'Police car',
    labelJa: 'パトカー',
    labelEs: 'Coche de policía',
    labelPtBr: 'Carro de polícia',
    emoji: '🚓',
    assetPath: 'assets/images/vehicle_police_car.png',
    selectionAssetPath: 'assets/images/vehicle_police_car_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.57,
      centerY: 0.30,
      sizeRatio: 0.26,
    ),
  );

  static const excavator = VehicleDefinition(
    id: 'excavator',
    labelKo: '포크레인',
    labelEn: 'Excavator',
    labelJa: 'ショベルカー',
    labelEs: 'Excavadora',
    labelPtBr: 'Escavadeira',
    emoji: '🚜',
    assetPath: 'assets/images/vehicle_excavator.png',
    selectionAssetPath: 'assets/images/vehicle_excavator_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.48,
      centerY: 0.28,
      sizeRatio: 0.28,
    ),
  );

  static const airplane = VehicleDefinition(
    id: 'airplane',
    labelKo: '비행기',
    labelEn: 'Airplane',
    labelJa: '飛行機',
    labelEs: 'Avión',
    labelPtBr: 'Avião',
    emoji: '✈️',
    assetPath: 'assets/images/vehicle_airplane.png',
    selectionAssetPath: 'assets/images/vehicle_airplane_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.52,
      centerY: 0.33,
      sizeRatio: 0.25,
    ),
    courseKind: VehicleCourseKind.sky,
  );

  static const bus = VehicleDefinition(
    id: 'bus',
    labelKo: '버스',
    labelEn: 'Bus',
    labelJa: 'バス',
    labelEs: 'Autobús',
    labelPtBr: 'Ônibus',
    emoji: '🚌',
    assetPath: 'assets/images/vehicle_bus.png',
    selectionAssetPath: 'assets/images/vehicle_bus_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.75,
      centerY: 0.47,
      sizeRatio: 0.23,
    ),
  );

  static const supercar = VehicleDefinition(
    id: 'supercar',
    labelKo: '슈퍼카',
    labelEn: 'Supercar',
    labelJa: 'スーパーカー',
    labelEs: 'Supercoche',
    labelPtBr: 'Supercarro',
    emoji: '🏎️',
    assetPath: 'assets/images/vehicle_supercar.png',
    selectionAssetPath: 'assets/images/vehicle_supercar_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.41,
      centerY: 0.34,
      sizeRatio: 0.27,
    ),
  );

  static const train = VehicleDefinition(
    id: 'train',
    labelKo: '기차',
    labelEn: 'Train',
    labelJa: '電車',
    labelEs: 'Tren',
    labelPtBr: 'Trem',
    emoji: '🚆',
    assetPath: 'assets/images/vehicle_train.png',
    selectionAssetPath: 'assets/images/vehicle_train_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.36,
      centerY: 0.39,
      sizeRatio: 0.25,
    ),
    courseKind: VehicleCourseKind.rail,
  );

  static const tRex = VehicleDefinition(
    id: 't_rex',
    labelKo: '티렉스',
    labelEn: 'T-rex',
    labelJa: 'ティラノサウルス',
    labelEs: 'T-rex',
    labelPtBr: 'T-rex',
    emoji: '🦖',
    assetPath: 'assets/images/vehicle_t_rex.png',
    selectionAssetPath: 'assets/images/vehicle_t_rex_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.56,
      centerY: 0.31,
      sizeRatio: 0.27,
    ),
    roadAnchorOffset: VehicleRoadAnchorOffset(
      portraitDyRatio: -0.13,
      landscapeDyRatio: -0.08,
    ),
    courseKind: VehicleCourseKind.field,
  );

  static const shark = VehicleDefinition(
    id: 'shark',
    labelKo: '상어',
    labelEn: 'Shark',
    labelJa: 'サメ',
    labelEs: 'Tiburón',
    labelPtBr: 'Tubarão',
    emoji: '🦈',
    assetPath: 'assets/images/vehicle_shark.png',
    selectionAssetPath: 'assets/images/vehicle_shark_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.56,
      centerY: 0.34,
      sizeRatio: 0.26,
    ),
    courseKind: VehicleCourseKind.water,
  );

  static const brachio = VehicleDefinition(
    id: 'brachio',
    labelKo: '브라키오',
    labelEn: 'Brachiosaurus',
    labelJa: 'ブラキオサウルス',
    labelEs: 'Braquiosaurio',
    labelPtBr: 'Braquiossauro',
    emoji: '🦕',
    assetPath: 'assets/images/vehicle_brachio.png',
    selectionAssetPath: 'assets/images/vehicle_brachio_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.52,
      centerY: 0.33,
      sizeRatio: 0.25,
    ),
    roadAnchorOffset: VehicleRoadAnchorOffset(
      portraitDyRatio: -0.18,
      landscapeDyRatio: -0.11,
    ),
    courseKind: VehicleCourseKind.field,
  );

  static const pteranodon = VehicleDefinition(
    id: 'pteranodon',
    labelKo: '프테라노돈',
    labelEn: 'Pteranodon',
    labelJa: 'プテラノドン',
    labelEs: 'Pteranodon',
    labelPtBr: 'Pteranodonte',
    emoji: '🪽',
    assetPath: 'assets/images/vehicle_pteranodon.png',
    selectionAssetPath: 'assets/images/vehicle_pteranodon_chip.png',
    avatarSlot: VehicleAvatarSlot(
      centerX: 0.50,
      centerY: 0.32,
      sizeRatio: 0.24,
    ),
    roadAnchorOffset: VehicleRoadAnchorOffset(
      portraitDyRatio: -0.08,
      landscapeDyRatio: -0.05,
    ),
    courseKind: VehicleCourseKind.sky,
  );

  static const all = [
    motorcycle,
    supercar,
    fireTruck,
    policeCar,
    excavator,
    airplane,
    bus,
    train,
    tRex,
    shark,
    brachio,
    pteranodon,
  ];

  static VehicleDefinition findById(String id) {
    for (final vehicle in all) {
      if (vehicle.id == id) {
        return vehicle;
      }
    }
    return motorcycle;
  }
}
