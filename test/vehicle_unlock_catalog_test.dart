import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_unlock_catalog.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';

void main() {
  test('free vehicles are motorcycle and supercar', () {
    expect(VehicleUnlockCatalog.freeVehicleIds, {
      VehicleCatalog.motorcycle.id,
      VehicleCatalog.supercar.id,
    });
    expect(
      VehicleUnlockCatalog.isVehicleUnlocked(
        VehicleCatalog.motorcycle.id,
        const PurchaseEntitlement.locked(),
      ),
      isTrue,
    );
    expect(
      VehicleUnlockCatalog.isVehicleUnlocked(
        VehicleCatalog.supercar.id,
        const PurchaseEntitlement.locked(),
      ),
      isTrue,
    );
  });

  test('premium vehicles require the vehicle pack while locked', () {
    final locked = const PurchaseEntitlement.locked();

    for (final vehicle in VehicleCatalog.all) {
      if (VehicleUnlockCatalog.isFreeVehicle(vehicle.id)) {
        continue;
      }

      expect(
        VehicleUnlockCatalog.requiresVehiclePack(vehicle.id),
        isTrue,
        reason: vehicle.id,
      );
      expect(
        VehicleUnlockCatalog.isVehicleUnlocked(vehicle.id, locked),
        isFalse,
        reason: vehicle.id,
      );
    }
  });

  test('vehicle pack entitlement unlocks premium vehicles', () {
    const unlocked = PurchaseEntitlement(vehiclePackUnlocked: true);

    for (final vehicle in VehicleCatalog.all) {
      expect(
        VehicleUnlockCatalog.isVehicleUnlocked(vehicle.id, unlocked),
        isTrue,
        reason: vehicle.id,
      );
    }
  });

  test('unknown vehicle ids are not treated as unlocked', () {
    const unlocked = PurchaseEntitlement(vehiclePackUnlocked: true);

    expect(VehicleUnlockCatalog.isKnownVehicle('missing'), isFalse);
    expect(VehicleUnlockCatalog.isFreeVehicle('missing'), isFalse);
    expect(VehicleUnlockCatalog.requiresVehiclePack('missing'), isFalse);
    expect(
      VehicleUnlockCatalog.isVehicleUnlocked('missing', unlocked),
      isFalse,
    );
  });

  test('purchase entitlement behaves as a value object', () {
    final updatedAt = DateTime.utc(2026, 7, 1);

    expect(
      PurchaseEntitlement(
        vehiclePackUnlocked: true,
        updatedAt: updatedAt,
        source: PurchaseEntitlementSource.storePurchase,
      ),
      PurchaseEntitlement(
        vehiclePackUnlocked: true,
        updatedAt: updatedAt,
        source: PurchaseEntitlementSource.storePurchase,
      ),
    );
  });
}
