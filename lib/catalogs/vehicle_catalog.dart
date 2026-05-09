import '../models/vehicle.dart';

abstract final class VehicleCatalog {
  static const motorcycle = VehicleDefinition(
    id: 'motorcycle',
    labelKo: '오토바이',
    labelEn: 'Motorcycle',
    emoji: '🏍️',
    assetPath: 'assets/images/jy_the_rider_flipped.png',
  );

  static const fireTruck = VehicleDefinition(
    id: 'fire_truck',
    labelKo: '소방차',
    labelEn: 'Fire truck',
    emoji: '🚒',
    assetPath: 'assets/images/vehicle_fire_truck.png',
  );

  static const policeCar = VehicleDefinition(
    id: 'police_car',
    labelKo: '경찰차',
    labelEn: 'Police car',
    emoji: '🚓',
    assetPath: 'assets/images/vehicle_police_car.png',
  );

  static const excavator = VehicleDefinition(
    id: 'excavator',
    labelKo: '포크레인',
    labelEn: 'Excavator',
    emoji: '🚜',
    assetPath: 'assets/images/vehicle_excavator.png',
  );

  static const all = [motorcycle, fireTruck, policeCar, excavator];

  static VehicleDefinition findById(String id) {
    for (final vehicle in all) {
      if (vehicle.id == id) {
        return vehicle;
      }
    }
    return motorcycle;
  }
}
