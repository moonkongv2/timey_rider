import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/app.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';

void main() {
  test('premium saved vehicle falls back while entitlement is locked', () {
    final config = _premiumConfig();

    final effectiveConfig = effectiveConfigForPurchaseEntitlement(
      config: config,
      entitlement: const PurchaseEntitlement.locked(),
    );

    expect(effectiveConfig.vehicleId, VehicleCatalog.motorcycle.id);
    expect(config.vehicleId, VehicleCatalog.fireTruck.id);
  });

  test('saving fallback config preserves current premium vehicle', () {
    final currentConfig = _premiumConfig();
    final incomingConfig = currentConfig.copyWith(
      vehicleId: VehicleCatalog.motorcycle.id,
      showRemainingTime: false,
    );

    final configForSaving = configForSavingPurchaseEntitlementFallback(
      currentConfig: currentConfig,
      incomingConfig: incomingConfig,
      entitlement: const PurchaseEntitlement.locked(),
    );

    expect(configForSaving.vehicleId, VehicleCatalog.fireTruck.id);
    expect(configForSaving.showRemainingTime, isFalse);
  });

  test('unlocked entitlement reuses saved premium vehicle', () {
    final config = _premiumConfig();

    final effectiveConfig = effectiveConfigForPurchaseEntitlement(
      config: config,
      entitlement: const PurchaseEntitlement(vehiclePackUnlocked: true),
    );

    expect(effectiveConfig.vehicleId, VehicleCatalog.fireTruck.id);
  });

  test('saving explicit unlocked vehicle selection is not rewritten', () {
    final currentConfig = _premiumConfig();
    final incomingConfig = currentConfig.copyWith(
      vehicleId: VehicleCatalog.supercar.id,
    );

    final configForSaving = configForSavingPurchaseEntitlementFallback(
      currentConfig: currentConfig,
      incomingConfig: incomingConfig,
      entitlement: const PurchaseEntitlement.locked(),
    );

    expect(configForSaving.vehicleId, VehicleCatalog.supercar.id);
  });
}

ActivityTimerConfig _premiumConfig() {
  return ActivityTimerConfig.defaults().copyWith(
    childName: 'Haru',
    vehicleId: VehicleCatalog.fireTruck.id,
  );
}
