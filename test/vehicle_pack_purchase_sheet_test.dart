import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/local_purchase_entitlement_store.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';
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
  final _purchaseStreamController =
      StreamController<List<IapPurchaseUpdate>>.broadcast();
  var buyCount = 0;
  var restoreCount = 0;
  var completeCount = 0;

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
    return const IapProductQueryResult(
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
  }

  @override
  Future<void> restorePurchases() async {
    restoreCount += 1;
  }

  void emitPurchase(IapPurchaseUpdate purchase) {
    _purchaseStreamController.add([purchase]);
  }
}
