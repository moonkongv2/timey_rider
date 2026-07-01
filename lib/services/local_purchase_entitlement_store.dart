import 'package:shared_preferences/shared_preferences.dart';

import '../models/purchase_entitlement.dart';

class LocalPurchaseEntitlementStore {
  const LocalPurchaseEntitlementStore();

  static const _vehiclePackUnlockedKey = 'purchase.vehiclePackUnlocked';
  static const _vehiclePackUpdatedAtKey = 'purchase.vehiclePackUpdatedAt';
  static const _vehiclePackSourceKey = 'purchase.vehiclePackSource';

  Future<PurchaseEntitlement> load() async {
    final preferences = await SharedPreferences.getInstance();
    final unlockedValue = preferences.get(_vehiclePackUnlockedKey);
    final vehiclePackUnlocked = unlockedValue is bool && unlockedValue;
    if (!vehiclePackUnlocked) {
      return const PurchaseEntitlement.locked();
    }

    return PurchaseEntitlement(
      vehiclePackUnlocked: true,
      updatedAt: _dateTimeFromPreference(
        preferences.get(_vehiclePackUpdatedAtKey),
      ),
      source:
          _sourceFromPreference(preferences.get(_vehiclePackSourceKey)) ??
          PurchaseEntitlementSource.localCache,
    );
  }

  Future<void> save(PurchaseEntitlement entitlement) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      _vehiclePackUnlockedKey,
      entitlement.vehiclePackUnlocked,
    );

    if (!entitlement.vehiclePackUnlocked) {
      await preferences.remove(_vehiclePackUpdatedAtKey);
      await preferences.remove(_vehiclePackSourceKey);
      return;
    }

    final updatedAt = entitlement.updatedAt;
    if (updatedAt == null) {
      await preferences.remove(_vehiclePackUpdatedAtKey);
    } else {
      await preferences.setString(
        _vehiclePackUpdatedAtKey,
        updatedAt.toIso8601String(),
      );
    }

    if (entitlement.source == PurchaseEntitlementSource.none) {
      await preferences.remove(_vehiclePackSourceKey);
    } else {
      await preferences.setString(
        _vehiclePackSourceKey,
        entitlement.source.name,
      );
    }
  }

  DateTime? _dateTimeFromPreference(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  PurchaseEntitlementSource? _sourceFromPreference(Object? value) {
    if (value is! String) {
      return null;
    }
    for (final source in PurchaseEntitlementSource.values) {
      if (source.name == value) {
        return source;
      }
    }
    return null;
  }
}
