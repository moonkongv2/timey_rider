import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/app.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/local_purchase_entitlement_store.dart';
import 'package:timey_rider/services/local_settings_service.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';

void main() {
  testWidgets('app queries interrupted purchases on startup and foreground', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final client = _RecoveryClient();
    final controller = VehiclePackPurchaseController(
      purchaseClient: client,
      entitlementStore: const LocalPurchaseEntitlementStore(),
    );
    await tester.pumpWidget(
      TimeyRiderApp(
        settingsService: LocalSettingsService(),
        activityProgressService: LocalActivityProgressService(),
        initialConfig: ActivityTimerConfig.defaults().copyWith(childName: ''),
        initialHasSeenOnboarding: true,
        showSplashOnStart: false,
        purchaseController: controller,
      ),
    );
    await tester.pump();
    expect(client.queryCount, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(client.queryCount, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await client.updates.close();
  });
}

class _RecoveryClient implements IapPurchaseClient, IapPurchaseRecoveryClient {
  final updates = StreamController<List<IapPurchaseUpdate>>.broadcast();
  int queryCount = 0;
  @override
  Stream<List<IapPurchaseUpdate>> get purchaseStream => updates.stream;
  @override
  Future<List<IapPurchaseUpdate>> queryExistingPurchases() async {
    queryCount++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
