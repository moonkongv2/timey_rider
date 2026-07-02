import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/vehicle_unlock_catalog.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/local_purchase_entitlement_store.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';

void main() {
  test('purchased vehicle pack saves entitlement before completing', () async {
    final events = <String>[];
    final client = _FakeIapPurchaseClient(events: events);
    final store = _FakePurchaseEntitlementStore(events: events);
    final controller = _controller(client: client, store: store);

    client.emitPurchases([_purchase(status: IapPurchaseStatus.purchased)]);
    await pumpEventQueue();

    expect(controller.state.vehiclePackUnlocked, isTrue);
    expect(controller.state.status, VehiclePackPurchaseStatus.purchased);
    expect(
      store.savedEntitlements.single.source,
      PurchaseEntitlementSource.storePurchase,
    );
    expect(client.completedProductIds, [
      VehicleUnlockCatalog.vehiclePackProductId,
    ]);
    expect(events, ['save:storePurchase', 'complete:vehicle_pack']);

    controller.dispose();
  });

  test('restored vehicle pack saves restore entitlement', () async {
    final client = _FakeIapPurchaseClient();
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    client.emitPurchases([_purchase(status: IapPurchaseStatus.restored)]);
    await pumpEventQueue();

    expect(controller.state.vehiclePackUnlocked, isTrue);
    expect(controller.state.status, VehiclePackPurchaseStatus.restored);
    expect(
      store.savedEntitlements.single.source,
      PurchaseEntitlementSource.storeRestore,
    );
    expect(client.completedProductIds, [
      VehicleUnlockCatalog.vehiclePackProductId,
    ]);

    controller.dispose();
  });

  test('pending purchase does not unlock vehicle pack', () async {
    final client = _FakeIapPurchaseClient();
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    client.emitPurchases([
      _purchase(
        status: IapPurchaseStatus.pending,
        pendingCompletePurchase: false,
      ),
    ]);
    await pumpEventQueue();

    expect(controller.state.vehiclePackUnlocked, isFalse);
    expect(controller.state.status, VehiclePackPurchaseStatus.pending);
    expect(store.savedEntitlements, isEmpty);
    expect(client.completedProductIds, isEmpty);

    controller.dispose();
  });

  test('error purchase does not unlock vehicle pack', () async {
    final client = _FakeIapPurchaseClient();
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    client.emitPurchases([
      _purchase(
        status: IapPurchaseStatus.error,
        pendingCompletePurchase: false,
        error: const IapPurchaseError(
          source: 'store',
          code: 'billing_error',
          message: 'Billing failed',
        ),
      ),
    ]);
    await pumpEventQueue();

    expect(controller.state.vehiclePackUnlocked, isFalse);
    expect(controller.state.status, VehiclePackPurchaseStatus.error);
    expect(controller.state.error?.code, 'billing_error');
    expect(store.savedEntitlements, isEmpty);

    controller.dispose();
  });

  test('canceled purchase keeps current entitlement locked', () async {
    final client = _FakeIapPurchaseClient();
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    client.emitPurchases([
      _purchase(
        status: IapPurchaseStatus.canceled,
        pendingCompletePurchase: false,
      ),
    ]);
    await pumpEventQueue();

    expect(controller.state.vehiclePackUnlocked, isFalse);
    expect(controller.state.status, VehiclePackPurchaseStatus.canceled);
    expect(store.savedEntitlements, isEmpty);

    controller.dispose();
  });

  test('unknown product purchase update is ignored', () async {
    final client = _FakeIapPurchaseClient();
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    client.emitPurchases([
      const IapPurchaseUpdate(
        productId: 'other_pack',
        status: IapPurchaseStatus.purchased,
        purchaseId: 'purchase-1',
        transactionDate: '2026-07-01',
        pendingCompletePurchase: true,
      ),
    ]);
    await pumpEventQueue();

    expect(controller.state.vehiclePackUnlocked, isFalse);
    expect(controller.state.status, VehiclePackPurchaseStatus.idle);
    expect(store.savedEntitlements, isEmpty);
    expect(client.completedProductIds, isEmpty);

    controller.dispose();
  });

  test('duplicate purchase update is completed once', () async {
    final client = _FakeIapPurchaseClient();
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);
    final purchase = _purchase(status: IapPurchaseStatus.purchased);

    client.emitPurchases([purchase, purchase]);
    await pumpEventQueue();

    expect(store.savedEntitlements, hasLength(1));
    expect(client.completedProductIds, [
      VehicleUnlockCatalog.vehiclePackProductId,
    ]);

    controller.dispose();
  });

  test('loadVehiclePackProduct handles unavailable store', () async {
    final client = _FakeIapPurchaseClient(isAvailable: false);
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    final product = await controller.loadVehiclePackProduct();

    expect(product, isNull);
    expect(
      controller.state.status,
      VehiclePackPurchaseStatus.productUnavailable,
    );
    expect(controller.state.storeAvailable, isFalse);
    expect(controller.state.error?.code, 'store_unavailable');

    controller.dispose();
  });

  test('loadVehiclePackProduct handles missing product details', () async {
    final client = _FakeIapPurchaseClient(
      queryResult: const IapProductQueryResult(
        products: [],
        notFoundIds: [VehicleUnlockCatalog.vehiclePackProductId],
      ),
    );
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    final product = await controller.loadVehiclePackProduct();

    expect(product, isNull);
    expect(
      controller.state.status,
      VehiclePackPurchaseStatus.productUnavailable,
    );
    expect(controller.state.notFoundIds, [
      VehicleUnlockCatalog.vehiclePackProductId,
    ]);
    expect(controller.state.error?.code, 'product_not_found');

    controller.dispose();
  });

  test('buyVehiclePack records purchase start through client', () async {
    final client = _FakeIapPurchaseClient();
    final store = _FakePurchaseEntitlementStore();
    final controller = _controller(client: client, store: store);

    final didStart = await controller.buyVehiclePack(product: _product());

    expect(didStart, isTrue);
    expect(
      controller.state.status,
      VehiclePackPurchaseStatus.purchaseInProgress,
    );
    expect(client.purchasedProductIds, [
      VehicleUnlockCatalog.vehiclePackProductId,
    ]);

    controller.dispose();
  });
}

VehiclePackPurchaseController _controller({
  required _FakeIapPurchaseClient client,
  required _FakePurchaseEntitlementStore store,
}) {
  return VehiclePackPurchaseController(
    purchaseClient: client,
    entitlementStore: store,
    now: () => DateTime.utc(2026, 7, 1),
  );
}

IapProductDetails _product() {
  return const IapProductDetails(
    id: VehicleUnlockCatalog.vehiclePackProductId,
    title: 'Vehicle Pack',
    description: 'Unlocks vehicles',
    price: r'$2.99',
    rawPrice: 2.99,
    currencyCode: 'USD',
    currencySymbol: r'$',
  );
}

IapPurchaseUpdate _purchase({
  required IapPurchaseStatus status,
  bool pendingCompletePurchase = true,
  IapPurchaseError? error,
}) {
  return IapPurchaseUpdate(
    productId: VehicleUnlockCatalog.vehiclePackProductId,
    status: status,
    purchaseId: 'purchase-1',
    transactionDate: '2026-07-01',
    pendingCompletePurchase: pendingCompletePurchase,
    error: error,
  );
}

class _FakePurchaseEntitlementStore implements PurchaseEntitlementStore {
  _FakePurchaseEntitlementStore({List<String>? events})
    : events = events ?? <String>[];

  PurchaseEntitlement entitlement = const PurchaseEntitlement.locked();
  final savedEntitlements = <PurchaseEntitlement>[];
  final List<String> events;

  @override
  Future<PurchaseEntitlement> load() async {
    return entitlement;
  }

  @override
  Future<void> save(PurchaseEntitlement entitlement) async {
    this.entitlement = entitlement;
    savedEntitlements.add(entitlement);
    events.add('save:${entitlement.source.name}');
  }
}

class _FakeIapPurchaseClient implements IapPurchaseClient {
  _FakeIapPurchaseClient({
    bool isAvailable = true,
    this.queryResult,
    List<String>? events,
  }) : _isAvailable = isAvailable,
       events = events ?? <String>[];

  final bool _isAvailable;
  final IapProductQueryResult? queryResult;
  final _purchaseStreamController =
      StreamController<List<IapPurchaseUpdate>>.broadcast();
  final purchasedProductIds = <String>[];
  final completedProductIds = <String>[];
  final List<String> events;
  int restoreCallCount = 0;

  @override
  Stream<List<IapPurchaseUpdate>> get purchaseStream {
    return _purchaseStreamController.stream;
  }

  @override
  Future<bool> buyNonConsumable(IapProductDetails product) async {
    purchasedProductIds.add(product.id);
    events.add('buy:${product.id}');
    return true;
  }

  @override
  Future<void> completePurchase(IapPurchaseUpdate purchase) async {
    completedProductIds.add(purchase.productId);
    events.add('complete:${purchase.productId}');
  }

  @override
  Future<bool> isAvailable() async {
    return _isAvailable;
  }

  @override
  Future<IapProductQueryResult> queryProducts(Set<String> productIds) async {
    return queryResult ?? IapProductQueryResult(products: [_product()]);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCallCount += 1;
    events.add('restore');
  }

  void emitPurchases(List<IapPurchaseUpdate> purchases) {
    _purchaseStreamController.add(purchases);
  }
}
