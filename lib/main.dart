import 'package:flutter/material.dart';

import 'app.dart';
import 'services/active_activity_timer_session_store.dart';
import 'services/iap_purchase_client.dart';
import 'services/local_activity_progress_service.dart';
import 'services/local_purchase_entitlement_store.dart';
import 'services/local_settings_service.dart';
import 'services/orientation_service.dart';
import 'services/vehicle_pack_purchase_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await const SystemOrientationService().lockPortrait();

  final settingsService = LocalSettingsService();
  final activityProgressService = LocalActivityProgressService();
  const purchaseEntitlementStore = LocalPurchaseEntitlementStore();
  final purchaseController = VehiclePackPurchaseController(
    purchaseClient: InAppPurchaseClient(),
    entitlementStore: purchaseEntitlementStore,
  );
  const activeSessionStore = ActiveActivityTimerSessionStore();
  final initialConfig = await settingsService.loadConfig();
  final initialPurchaseEntitlement = await purchaseController
      .loadCachedEntitlement();
  final initialHasSeenOnboarding = await settingsService.loadHasSeenOnboarding(
    childName: initialConfig.childName,
  );

  runApp(
    TimeyRiderApp(
      settingsService: settingsService,
      activityProgressService: activityProgressService,
      activeSessionStore: activeSessionStore,
      purchaseController: purchaseController,
      initialPurchaseEntitlement: initialPurchaseEntitlement,
      disposePurchaseController: true,
      initialConfig: initialConfig,
      initialHasSeenOnboarding: initialHasSeenOnboarding,
    ),
  );
}
