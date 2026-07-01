enum PurchaseEntitlementSource { none, localCache, storePurchase, storeRestore }

class PurchaseEntitlement {
  const PurchaseEntitlement({
    required this.vehiclePackUnlocked,
    this.updatedAt,
    this.source = PurchaseEntitlementSource.none,
  });

  const PurchaseEntitlement.locked()
    : vehiclePackUnlocked = false,
      updatedAt = null,
      source = PurchaseEntitlementSource.none;

  final bool vehiclePackUnlocked;
  final DateTime? updatedAt;
  final PurchaseEntitlementSource source;

  PurchaseEntitlement copyWith({
    bool? vehiclePackUnlocked,
    DateTime? updatedAt,
    PurchaseEntitlementSource? source,
  }) {
    return PurchaseEntitlement(
      vehiclePackUnlocked: vehiclePackUnlocked ?? this.vehiclePackUnlocked,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseEntitlement &&
        other.vehiclePackUnlocked == vehiclePackUnlocked &&
        other.updatedAt == updatedAt &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(vehiclePackUnlocked, updatedAt, source);
}
