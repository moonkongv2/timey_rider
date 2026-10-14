import 'package:flutter/foundation.dart';

import '../models/purchase_entitlement.dart';
import 'vehicle_catalog.dart';

abstract final class VehicleUnlockCatalog {
  static const androidVehiclePackProductId = 'vehicle_pack';
  static const iosVehiclePackProductId = 'com.timeyrider.vehicle_pack';

  static String get vehiclePackProductId =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? iosVehiclePackProductId
      : androidVehiclePackProductId;

  static const freeVehicleIds = {'motorcycle', 'supercar'};

  static bool isFreeVehicle(String vehicleId) {
    return freeVehicleIds.contains(vehicleId);
  }

  static bool isKnownVehicle(String vehicleId) {
    return VehicleCatalog.all.any((vehicle) => vehicle.id == vehicleId);
  }

  static bool requiresVehiclePack(String vehicleId) {
    return isKnownVehicle(vehicleId) && !isFreeVehicle(vehicleId);
  }

  static bool isVehicleUnlocked(
    String vehicleId,
    PurchaseEntitlement entitlement,
  ) {
    if (!isKnownVehicle(vehicleId)) {
      return false;
    }
    if (isFreeVehicle(vehicleId)) {
      return true;
    }
    return entitlement.vehiclePackUnlocked;
  }
}
