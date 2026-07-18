import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/local_purchase_entitlement_store.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';
import 'package:timey_rider/widgets/app/app_bouncy_button.dart';
import 'package:timey_rider/widgets/purchase/vehicle_pack_purchase_sheet.dart';

void main() {
  testWidgets('vehicle pack purchase sheet loads product and starts purchase', (
    tester,
  ) async {
    final client = _FakeIapPurchaseClient();
    final controller = VehiclePackPurchaseController(
      purchaseClient: client,
      entitlementStore: _FakePurchaseEntitlementStore(),
    );
    addTearDown(controller.dispose);

    await _pumpPurchaseSheetHost(tester, controller: controller);
    await tester.tap(find.byKey(const ValueKey('openPurchaseSheetButton')));
    await tester.pumpAndSettle();

    expect(find.text('Unlock the vehicle pack'), findsOneWidget);
    expect(find.text('Price \$2.99'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('vehiclePackPurchaseButton')));
    await tester.pump();

    expect(client.buyCount, 1);
  });

  testWidgets('vehicle pack purchase sheet restores purchases', (tester) async {
    final client = _FakeIapPurchaseClient();
    final controller = VehiclePackPurchaseController(
      purchaseClient: client,
      entitlementStore: _FakePurchaseEntitlementStore(),
    );
    addTearDown(controller.dispose);

    await _pumpPurchaseSheetHost(
      tester,
      controller: controller,
      locale: const Locale('ko'),
    );
    await tester.tap(find.byKey(const ValueKey('openPurchaseSheetButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('vehiclePackRestoreButton')));
    await tester.pump();

    expect(client.restoreCount, 1);
    expect(find.text('복원할 차량팩 구매 내역을 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('vehicle pack purchase sheet disables actions while pending', (
    tester,
  ) async {
    final client = _FakeIapPurchaseClient();
    final controller = VehiclePackPurchaseController(
      purchaseClient: client,
      entitlementStore: _FakePurchaseEntitlementStore(),
    );
    addTearDown(controller.dispose);

    await _pumpPurchaseSheetHost(tester, controller: controller);
    await tester.tap(find.byKey(const ValueKey('openPurchaseSheetButton')));
    await tester.pumpAndSettle();

    client.emitPurchase(
      const IapPurchaseUpdate(
        productId: 'vehicle_pack',
        status: IapPurchaseStatus.pending,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Waiting for purchase approval.'), findsOneWidget);
    expect(
      tester
          .widget<AppBouncyButton>(
            find.byKey(const ValueKey('vehiclePackPurchaseButton')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<AppBouncyButton>(
            find.byKey(const ValueKey('vehiclePackRestoreButton')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('vehicle pack purchase sheet retries product loading and buys', (
    tester,
  ) async {
    final client = _FakeIapPurchaseClient(
      queryResults: [
        const IapProductQueryResult(
          products: [],
          notFoundIds: ['vehicle_pack'],
        ),
        _FakeIapPurchaseClient.successfulQueryResult,
      ],
    );
    final controller = VehiclePackPurchaseController(
      purchaseClient: client,
      entitlementStore: _FakePurchaseEntitlementStore(),
    );
    addTearDown(controller.dispose);

    await _pumpPurchaseSheetHost(tester, controller: controller);
    await tester.tap(find.byKey(const ValueKey('openPurchaseSheetButton')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Vehicle pack details are not available right now. Try again later.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('vehiclePackPurchaseButton')));
    await tester.pump();

    expect(find.text('Price \$2.99'), findsOneWidget);
    expect(client.queryCount, 2);
    expect(client.buyCount, 1);
  });

  testWidgets(
    'vehicle pack purchase sheet shows success after purchase update',
    (tester) async {
      final client = _FakeIapPurchaseClient();
      final store = _FakePurchaseEntitlementStore();
      final controller = VehiclePackPurchaseController(
        purchaseClient: client,
        entitlementStore: store,
        now: () => DateTime(2026, 7, 3),
      );
      addTearDown(controller.dispose);

      await _pumpPurchaseSheetHost(tester, controller: controller);
      await tester.tap(find.byKey(const ValueKey('openPurchaseSheetButton')));
      await tester.pumpAndSettle();

      client.emitPurchase(
        const IapPurchaseUpdate(
          productId: 'vehicle_pack',
          status: IapPurchaseStatus.purchased,
          purchaseId: 'purchase-1',
          pendingCompletePurchase: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(store.savedEntitlement?.vehiclePackUnlocked, isTrue);
      expect(client.completeCount, 1);
      expect(find.text('Vehicle pack unlocked.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vehiclePackPurchaseDoneButton')),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpPurchaseSheetHost(
  WidgetTester tester, {
  required VehiclePackPurchaseController controller,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppTexts.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('openPurchaseSheetButton'),
                onPressed: () {
                  showVehiclePackPurchaseSheet(
                    context,
                    controller: controller,
                    vehicleId: 'fire_truck',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _FakePurchaseEntitlementStore implements PurchaseEntitlementStore {
  PurchaseEntitlement? savedEntitlement;

  @override
  Future<PurchaseEntitlement> load() async {
    return const PurchaseEntitlement.locked();
  }

  @override
  Future<void> save(PurchaseEntitlement entitlement) async {
    savedEntitlement = entitlement;
  }
}

class _FakeIapPurchaseClient implements IapPurchaseClient {
  _FakeIapPurchaseClient({List<IapProductQueryResult>? queryResults})
    : queryResults = queryResults ?? const [successfulQueryResult];

  static const successfulQueryResult = IapProductQueryResult(
    products: [
      IapProductDetails(
        id: 'vehicle_pack',
        title: 'Vehicle Pack',
        description: 'Unlock all vehicles',
        price: '\$2.99',
        rawPrice: 2.99,
        currencyCode: 'USD',
        currencySymbol: r'$',
      ),
    ],
  );

  final List<IapProductQueryResult> queryResults;
  final _purchaseStreamController =
      StreamController<List<IapPurchaseUpdate>>.broadcast();
  var buyCount = 0;
  var restoreCount = 0;
  var completeCount = 0;
  var queryCount = 0;

  @override
  Stream<List<IapPurchaseUpdate>> get purchaseStream {
    return _purchaseStreamController.stream;
  }

  @override
  Future<bool> buyNonConsumable(IapProductDetails product) async {
    buyCount += 1;
    return true;
  }

  @override
  Future<void> completePurchase(IapPurchaseUpdate purchase) async {
    completeCount += 1;
  }

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<IapProductQueryResult> queryProducts(Set<String> productIds) async {
    final index = queryCount.clamp(0, queryResults.length - 1);
    queryCount += 1;
    return queryResults[index];
  }

  @override
  Future<void> restorePurchases() async {
    restoreCount += 1;
  }

  void emitPurchase(IapPurchaseUpdate purchase) {
    _purchaseStreamController.add([purchase]);
  }
}
