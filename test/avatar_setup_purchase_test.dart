import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';

import 'support/avatar_test_harness.dart';

void main() {
  testWidgets('Avatar setup does not select locked premium vehicles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    final infoSheetVehicleIds = <String>[];
    var parentGateCallCount = 0;
    final purchaseSheetVehicleIds = <String>[];
    final purchaseClient = TestIapPurchaseClient();
    addTearDown(purchaseClient.close);
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: purchaseClient,
      entitlementStore: TestPurchaseEntitlementStore(),
    );
    addTearDown(purchaseController.dispose);

    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
      purchaseController: purchaseController,
      purchaseState: const VehiclePackPurchaseState.initial(),
      vehiclePackInfoPresenter: (_, {required vehicleId}) async {
        infoSheetVehicleIds.add(vehicleId);
        return false;
      },
      parentGatePresenter: (_) async {
        parentGateCallCount += 1;
        return true;
      },
      vehiclePackPurchasePresenter:
          (_, {required controller, required vehicleId}) async {
            purchaseSheetVehicleIds.add(vehicleId);
          },
    );
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);
    await scrollAvatarVehicleSelectionIntoView(tester);

    await tapVisible(tester, vehicleChoiceFinder('fire_truck'));
    await tester.pump();

    expect(changedConfig, isNull);
    expect(infoSheetVehicleIds, ['fire_truck']);
    expect(parentGateCallCount, 0);
    expect(purchaseSheetVehicleIds, isEmpty);

    await tapVisible(tester, vehicleChoiceFinder('supercar'));
    await tester.pump();

    expect(changedConfig?.vehicleId, 'supercar');
  });

  testWidgets('Avatar setup selects locked vehicle after successful purchase', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    final purchaseClient = TestIapPurchaseClient();
    addTearDown(purchaseClient.close);
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: purchaseClient,
      entitlementStore: TestPurchaseEntitlementStore(),
    );
    addTearDown(purchaseController.dispose);

    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
      purchaseController: purchaseController,
      purchaseState: const VehiclePackPurchaseState.initial(),
      vehiclePackInfoPresenter: (_, {required vehicleId}) async {
        return true;
      },
      parentGatePresenter: (_) async {
        return true;
      },
      vehiclePackPurchasePresenter:
          (_, {required controller, required vehicleId}) async {
            purchaseClient.emitPurchase(
              const IapPurchaseUpdate(
                productId: 'vehicle_pack',
                status: IapPurchaseStatus.purchased,
                purchaseId: 'avatar-purchase',
              ),
            );
            await pumpPurchaseControllerUnlock(controller);
          },
    );
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);
    await scrollAvatarVehicleSelectionIntoView(tester);

    await tapVisible(tester, vehicleChoiceFinder('fire_truck'));
    await tester.pump();

    expect(changedConfig?.vehicleId, 'fire_truck');
  });
}
