import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';

void main() {
  test('fake client returns configured availability and products', () async {
    final client = _FakeIapPurchaseClient(
      available: true,
      productQueryResult: const IapProductQueryResult(
        products: [
          IapProductDetails(
            id: 'vehicle_pack',
            title: 'Vehicle Pack',
            description: 'Unlocks vehicles',
            price: r'$2.99',
            rawPrice: 2.99,
            currencyCode: 'USD',
            currencySymbol: r'$',
          ),
        ],
      ),
    );

    expect(await client.isAvailable(), isTrue);

    final result = await client.queryProducts({'vehicle_pack'});

    expect(result.products.single.id, 'vehicle_pack');
    expect(result.products.single.price, r'$2.99');
    expect(client.queriedProductIds.single, {'vehicle_pack'});
  });

  test('fake client records purchase, restore, and complete calls', () async {
    final client = _FakeIapPurchaseClient(
      productQueryResult: const IapProductQueryResult(products: []),
    );
    const product = IapProductDetails(
      id: 'vehicle_pack',
      title: 'Vehicle Pack',
      description: 'Unlocks vehicles',
      price: r'$2.99',
      rawPrice: 2.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
    );
    const purchase = IapPurchaseUpdate(
      productId: 'vehicle_pack',
      status: IapPurchaseStatus.purchased,
      pendingCompletePurchase: true,
    );

    expect(await client.buyNonConsumable(product), isTrue);
    await client.restorePurchases();
    await client.completePurchase(purchase);

    expect(client.purchasedProductIds, ['vehicle_pack']);
    expect(client.restoreCallCount, 1);
    expect(client.completedProductIds, ['vehicle_pack']);
  });

  test('fake client emits purchase stream updates', () async {
    final client = _FakeIapPurchaseClient(
      productQueryResult: const IapProductQueryResult(products: []),
    );
    final purchaseEvents = <List<IapPurchaseUpdate>>[];
    final subscription = client.purchaseStream.listen(purchaseEvents.add);

    client.emitPurchases(const [
      IapPurchaseUpdate(
        productId: 'vehicle_pack',
        status: IapPurchaseStatus.pending,
      ),
    ]);
    await pumpEventQueue();
    await subscription.cancel();

    expect(purchaseEvents, hasLength(1));
    expect(purchaseEvents.single.single.status, IapPurchaseStatus.pending);
  });

  test('query result can represent product lookup failures', () async {
    final client = _FakeIapPurchaseClient(
      productQueryResult: const IapProductQueryResult(
        products: [],
        notFoundIds: ['vehicle_pack'],
        error: IapPurchaseError(
          source: 'store',
          code: 'unavailable',
          message: 'Store is unavailable',
        ),
      ),
    );

    final result = await client.queryProducts({'vehicle_pack'});

    expect(result.products, isEmpty);
    expect(result.notFoundIds, ['vehicle_pack']);
    expect(result.error?.code, 'unavailable');
  });
}

class _FakeIapPurchaseClient implements IapPurchaseClient {
  _FakeIapPurchaseClient({
    this.available = false,
    required this.productQueryResult,
  });

  final bool available;
  final IapProductQueryResult productQueryResult;
  final _purchaseStreamController =
      StreamController<List<IapPurchaseUpdate>>.broadcast();
  final queriedProductIds = <Set<String>>[];
  final purchasedProductIds = <String>[];
  final completedProductIds = <String>[];
  int restoreCallCount = 0;

  @override
  Stream<List<IapPurchaseUpdate>> get purchaseStream {
    return _purchaseStreamController.stream;
  }

  @override
  Future<bool> isAvailable() async {
    return available;
  }

  @override
  Future<IapProductQueryResult> queryProducts(Set<String> productIds) async {
    queriedProductIds.add(Set.unmodifiable(productIds));
    return productQueryResult;
  }

  @override
  Future<bool> buyNonConsumable(IapProductDetails product) async {
    purchasedProductIds.add(product.id);
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCallCount += 1;
  }

  @override
  Future<void> completePurchase(IapPurchaseUpdate purchase) async {
    completedProductIds.add(purchase.productId);
  }

  void emitPurchases(List<IapPurchaseUpdate> purchases) {
    _purchaseStreamController.add(purchases);
  }
}
