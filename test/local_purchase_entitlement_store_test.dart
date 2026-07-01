import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';
import 'package:timey_rider/services/local_purchase_entitlement_store.dart';
import 'package:timey_rider/services/local_settings_service.dart';

void main() {
  test('load returns locked entitlement by default', () async {
    SharedPreferences.setMockInitialValues({});

    final entitlement = await const LocalPurchaseEntitlementStore().load();

    expect(entitlement, const PurchaseEntitlement.locked());
  });

  test('save and load preserves unlocked vehicle pack entitlement', () async {
    SharedPreferences.setMockInitialValues({});
    final updatedAt = DateTime.utc(2026, 7, 1, 3, 4, 5);
    const store = LocalPurchaseEntitlementStore();

    await store.save(
      PurchaseEntitlement(
        vehiclePackUnlocked: true,
        updatedAt: updatedAt,
        source: PurchaseEntitlementSource.storePurchase,
      ),
    );

    expect(
      await store.load(),
      PurchaseEntitlement(
        vehiclePackUnlocked: true,
        updatedAt: updatedAt,
        source: PurchaseEntitlementSource.storePurchase,
      ),
    );
  });

  test(
    'load treats malformed values as locked or local cache fallback',
    () async {
      SharedPreferences.setMockInitialValues({
        'purchase.vehiclePackUnlocked': true,
        'purchase.vehiclePackUpdatedAt': 'not-a-date',
        'purchase.vehiclePackSource': 'missing',
      });

      final entitlement = await const LocalPurchaseEntitlementStore().load();

      expect(
        entitlement,
        const PurchaseEntitlement(
          vehiclePackUnlocked: true,
          source: PurchaseEntitlementSource.localCache,
        ),
      );
    },
  );

  test('load treats wrong unlocked value type as locked', () async {
    SharedPreferences.setMockInitialValues({
      'purchase.vehiclePackUnlocked': 'true',
      'purchase.vehiclePackUpdatedAt': '2026-07-01T00:00:00.000Z',
      'purchase.vehiclePackSource': 'storeRestore',
    });

    final entitlement = await const LocalPurchaseEntitlementStore().load();

    expect(entitlement, const PurchaseEntitlement.locked());
  });

  test('saving locked entitlement clears metadata', () async {
    SharedPreferences.setMockInitialValues({});
    const store = LocalPurchaseEntitlementStore();
    await store.save(
      PurchaseEntitlement(
        vehiclePackUnlocked: true,
        updatedAt: DateTime.utc(2026, 7, 1),
        source: PurchaseEntitlementSource.storeRestore,
      ),
    );

    await store.save(const PurchaseEntitlement.locked());

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('purchase.vehiclePackUnlocked'), isFalse);
    expect(preferences.containsKey('purchase.vehiclePackUpdatedAt'), isFalse);
    expect(preferences.containsKey('purchase.vehiclePackSource'), isFalse);
  });

  test('purchase entitlement keys do not affect local settings keys', () async {
    SharedPreferences.setMockInitialValues({
      'durationMinutes': 25,
      'vehicleId': 'supercar',
      'childName': 'Haru',
    });

    await const LocalPurchaseEntitlementStore().save(
      PurchaseEntitlement(
        vehiclePackUnlocked: true,
        updatedAt: DateTime.utc(2026, 7, 1),
        source: PurchaseEntitlementSource.storePurchase,
      ),
    );

    final config = await LocalSettingsService().loadConfig();

    expect(config.duration, const Duration(minutes: 25));
    expect(config.vehicleId, 'supercar');
    expect(config.childName, 'Haru');
  });
}
