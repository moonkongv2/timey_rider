import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'catalogs/vehicle_catalog.dart';
import 'catalogs/vehicle_unlock_catalog.dart';
import 'l10n/app_texts.dart';
import 'models/activity_timer_config.dart';
import 'models/purchase_entitlement.dart';
import 'navigation/app_route_observer.dart';
import 'screens/child_name_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/active_activity_timer_session_store.dart';
import 'services/local_activity_progress_service.dart';
import 'services/local_settings_service.dart';
import 'services/vehicle_pack_purchase_controller.dart';
import 'theme/app_theme.dart';

class TimeyRiderApp extends StatefulWidget {
  const TimeyRiderApp({
    super.key,
    required this.settingsService,
    required this.activityProgressService,
    required this.initialConfig,
    required this.initialHasSeenOnboarding,
    this.activeSessionStore = const ActiveActivityTimerSessionStore(),
    this.purchaseController,
    this.initialPurchaseEntitlement = const PurchaseEntitlement.locked(),
    this.disposePurchaseController = false,
    this.showSplashOnStart = true,
  });

  final LocalSettingsService settingsService;
  final LocalActivityProgressService activityProgressService;
  final ActivityTimerConfig initialConfig;
  final bool initialHasSeenOnboarding;
  final ActiveActivityTimerSessionStore activeSessionStore;
  final VehiclePackPurchaseController? purchaseController;
  final PurchaseEntitlement initialPurchaseEntitlement;
  final bool disposePurchaseController;
  final bool showSplashOnStart;

  @override
  State<TimeyRiderApp> createState() => _TimeyRiderAppState();
}

class _TimeyRiderAppState extends State<TimeyRiderApp> {
  late ActivityTimerConfig _config = widget.initialConfig;
  late VehiclePackPurchaseState _purchaseState =
      (widget.purchaseController?.state ??
              const VehiclePackPurchaseState.initial())
          .copyWith(entitlement: widget.initialPurchaseEntitlement);
  late bool _showSplash = widget.showSplashOnStart;
  late bool _hasSeenOnboarding = widget.initialHasSeenOnboarding;
  VehiclePackPurchaseController? _purchaseController;

  @override
  void initState() {
    super.initState();
    _purchaseController = widget.purchaseController;
    _purchaseController?.addListener(_handlePurchaseStateChanged);
  }

  @override
  void didUpdateWidget(covariant TimeyRiderApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.purchaseController != widget.purchaseController) {
      oldWidget.purchaseController?.removeListener(_handlePurchaseStateChanged);
      _purchaseController = widget.purchaseController;
      _purchaseController?.addListener(_handlePurchaseStateChanged);
      final purchaseController = _purchaseController;
      if (purchaseController != null) {
        _purchaseState = purchaseController.state;
      }
    }
  }

  @override
  void dispose() {
    _purchaseController?.removeListener(_handlePurchaseStateChanged);
    if (widget.disposePurchaseController) {
      _purchaseController?.dispose();
    }
    super.dispose();
  }

  void _handlePurchaseStateChanged() {
    final purchaseController = _purchaseController;
    if (purchaseController == null) {
      return;
    }
    setState(() => _purchaseState = purchaseController.state);
  }

  Future<void> _saveConfig(ActivityTimerConfig config) async {
    final configForSaving = _configForSaving(config);
    setState(() => _config = configForSaving);
    await widget.settingsService.saveConfig(configForSaving);
  }

  void _finishSplash() {
    if (!_showSplash) {
      return;
    }
    setState(() => _showSplash = false);
  }

  bool get _hasChildName => _config.childName.trim().isNotEmpty;

  Future<void> _finishOnboarding() async {
    if (!_hasSeenOnboarding) {
      setState(() => _hasSeenOnboarding = true);
    }
    await widget.settingsService.saveHasSeenOnboarding(true);
  }

  Future<void> _saveChildName(String name) {
    return _saveConfig(_config.copyWith(childName: name.trim()));
  }

  ActivityTimerConfig get _effectiveConfig {
    return effectiveConfigForPurchaseEntitlement(
      config: _config,
      entitlement: _purchaseState.entitlement,
    );
  }

  ActivityTimerConfig _configForSaving(ActivityTimerConfig config) {
    return configForSavingPurchaseEntitlementFallback(
      currentConfig: _config,
      incomingConfig: config,
      entitlement: _purchaseState.entitlement,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = _effectiveConfig;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppTexts.of(context).common.appTitle,
      supportedLocales: AppTexts.supportedLocales,
      navigatorObservers: [appRouteObserver],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: _showSplash
          ? SplashScreen(onFinished: _finishSplash)
          : !_hasSeenOnboarding
          ? OnboardingScreen(onFinished: _finishOnboarding)
          : _hasChildName
          ? HomeScreen(
              config: effectiveConfig,
              activityProgressService: widget.activityProgressService,
              activeSessionStore: widget.activeSessionStore,
              purchaseController: widget.purchaseController,
              purchaseState: _purchaseState,
              onConfigChanged: _saveConfig,
            )
          : ChildNameSetupScreen(onNameSaved: _saveChildName),
    );
  }
}

ActivityTimerConfig effectiveConfigForPurchaseEntitlement({
  required ActivityTimerConfig config,
  required PurchaseEntitlement entitlement,
}) {
  final fallbackVehicleId = fallbackVehicleIdForPurchaseEntitlement(
    config: config,
    entitlement: entitlement,
  );
  if (fallbackVehicleId == null) {
    return config;
  }
  return config.copyWith(vehicleId: fallbackVehicleId);
}

ActivityTimerConfig configForSavingPurchaseEntitlementFallback({
  required ActivityTimerConfig currentConfig,
  required ActivityTimerConfig incomingConfig,
  required PurchaseEntitlement entitlement,
}) {
  final fallbackVehicleId = fallbackVehicleIdForPurchaseEntitlement(
    config: currentConfig,
    entitlement: entitlement,
  );
  if (fallbackVehicleId != null &&
      incomingConfig.vehicleId == fallbackVehicleId) {
    return incomingConfig.copyWith(vehicleId: currentConfig.vehicleId);
  }
  return incomingConfig;
}

String? fallbackVehicleIdForPurchaseEntitlement({
  required ActivityTimerConfig config,
  required PurchaseEntitlement entitlement,
}) {
  final vehicleId = config.vehicleId;
  if (VehicleUnlockCatalog.isVehicleUnlocked(vehicleId, entitlement)) {
    return null;
  }
  return VehicleCatalog.motorcycle.id;
}
