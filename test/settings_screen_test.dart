import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/settings_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/screens/user_guide_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';
import 'package:timey_rider/widgets/vehicle_selection_card.dart';

import 'support/app_test_harness.dart';
import 'support/avatar_test_harness.dart';

void main() {
  testWidgets('Remaining time setting can be turned off', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'durationMinutes': 25,
      'markerMode': 'off',
    });

    await startTestApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('남은 시간 보여주기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('남은 시간 보여주기'), findsOneWidget);
    await tester.tap(find.text('남은 시간 보여주기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await openTimerBuilder(tester);
    await startTimerBuilder(tester);

    expect(find.textContaining('남은 시간'), findsNothing);
  });

  testWidgets('Settings screen opens Korean parent guide', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var parentGateCallCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          parentGatePresenter: (_) async {
            parentGateCallCount += 1;
            return true;
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('userGuideSettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('userGuideSettingsTile')), findsOneWidget);
    expect(find.text('도움말 및 지원'), findsOneWidget);
    expect(find.text('사용 가이드'), findsOneWidget);
    expect(find.text('활동 미션, 코스 마커, 차량 스티커 규칙을 확인해요.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('userGuideSettingsTile')));
    await tester.pumpAndSettle();

    expect(find.byType(UserGuideScreen), findsOneWidget);
    expect(find.text('사용 안내'), findsOneWidget);
    expect(find.text('보호자 가이드'), findsOneWidget);
    expect(
      find.textContaining('아이의 루틴을 함께 돕는 보호자도 참고할 수 있어요.'),
      findsOneWidget,
    );
    expect(parentGateCallCount, 0);
  });

  testWidgets('Settings screen opens vehicle pack purchase after parent gate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var parentGateCallCount = 0;
    final purchaseSheetVehicleIds = <String>[];
    final purchaseClient = TestIapPurchaseClient();
    addTearDown(purchaseClient.close);
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: purchaseClient,
      entitlementStore: TestPurchaseEntitlementStore(),
    );
    addTearDown(purchaseController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            vehicleId: 'fire_truck',
          ),
          onConfigChanged: (_) {},
          purchaseController: purchaseController,
          purchaseState: const VehiclePackPurchaseState.initial(),
          parentGatePresenter: (_) async {
            parentGateCallCount += 1;
            return true;
          },
          vehiclePackPurchasePresenter:
              (_, {required controller, required vehicleId}) async {
                purchaseSheetVehicleIds.add(vehicleId);
              },
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('vehiclePackSettingsManageButton')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('차량팩'), findsOneWidget);
    expect(find.text('잠긴 빠방이 있어요'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('vehiclePackSettingsManageButton')),
    );
    await tester.pump();

    expect(parentGateCallCount, 1);
    expect(purchaseSheetVehicleIds, ['fire_truck']);
  });

  testWidgets('Settings screen restores vehicle pack after parent gate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var parentGateCallCount = 0;
    var purchaseSheetCallCount = 0;
    final purchaseClient = TestIapPurchaseClient();
    addTearDown(purchaseClient.close);
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: purchaseClient,
      entitlementStore: TestPurchaseEntitlementStore(),
    );
    addTearDown(purchaseController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            vehicleId: 'fire_truck',
          ),
          onConfigChanged: (_) {},
          purchaseController: purchaseController,
          purchaseState: const VehiclePackPurchaseState.initial(),
          parentGatePresenter: (_) async {
            parentGateCallCount += 1;
            return true;
          },
          vehiclePackPurchasePresenter:
              (_, {required controller, required vehicleId}) async {
                purchaseSheetCallCount += 1;
              },
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('restorePurchaseSettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('restorePurchaseSettingsTile')));
    await tester.pump();
    await tester.pump();

    expect(parentGateCallCount, 1);
    expect(purchaseClient.restoreCallCount, 1);
    expect(purchaseSheetCallCount, 0);
    expect(find.text('복원할 차량팩 구매 내역을 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('Settings screen opens support link after parent gate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final events = <String>[];
    final launchedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          parentGatePresenter: (_) async {
            events.add('gate');
            return true;
          },
          urlLauncher: (uri) async {
            events.add('launch');
            launchedUris.add(uri);
            return true;
          },
          appVersionLoader: () async => '1.0.0 (1)',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('contactSupportSettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('contactSupportSettingsTile')));
    await tester.pump();

    expect(events, ['gate', 'launch']);
    expect(launchedUris, [SettingsScreen.supportUri]);
  });

  testWidgets('Settings screen opens privacy link after parent gate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final events = <String>[];
    final launchedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          parentGatePresenter: (_) async {
            events.add('gate');
            return true;
          },
          urlLauncher: (uri) async {
            events.add('launch');
            launchedUris.add(uri);
            return true;
          },
          appVersionLoader: () async => '1.0.0 (1)',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('privacyPolicySettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('privacyPolicySettingsTile')));
    await tester.pump();

    expect(events, ['gate', 'launch']);
    expect(launchedUris, [SettingsScreen.privacyPolicyUri]);
  });

  testWidgets('Settings screen blocks privacy link when parent gate fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var parentGateCallCount = 0;
    final launchedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          parentGatePresenter: (_) async {
            parentGateCallCount += 1;
            return false;
          },
          urlLauncher: (uri) async {
            launchedUris.add(uri);
            return true;
          },
          appVersionLoader: () async => '1.0.0 (1)',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('privacyPolicySettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('privacyPolicySettingsTile')));
    await tester.pump();

    expect(parentGateCallCount, 1);
    expect(launchedUris, isEmpty);
  });

  testWidgets('Settings screen shows link failure message', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          parentGatePresenter: (_) async => true,
          urlLauncher: (_) async => false,
          appVersionLoader: () async => '1.0.0 (1)',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('contactSupportSettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('contactSupportSettingsTile')));
    await tester.pump();

    expect(find.text('Could not open the link.'), findsOneWidget);
  });

  testWidgets('Settings screen shows unlocked vehicle pack state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final purchaseClient = TestIapPurchaseClient();
    addTearDown(purchaseClient.close);
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: purchaseClient,
      entitlementStore: TestPurchaseEntitlementStore(
        const PurchaseEntitlement(vehiclePackUnlocked: true),
      ),
    );
    addTearDown(purchaseController.dispose);
    await purchaseController.loadCachedEntitlement();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          purchaseController: purchaseController,
          appVersionLoader: () async => '1.0.0 (1)',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Vehicle pack unlocked'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Vehicle pack'), findsOneWidget);
    expect(find.text('Vehicle pack unlocked'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vehiclePackSettingsManageButton')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('vehiclePackSettingsRestoreButton')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('restorePurchaseSettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restorePurchaseSettingsTile')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('appVersionSettingsTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final appVersionTile = tester.widget<ListTile>(
      find.byKey(const ValueKey('appVersionSettingsTile')),
    );
    expect(appVersionTile.onTap, isNull);
    expect(find.text('App Version'), findsOneWidget);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
  });

  testWidgets('User guide uses English localization', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('ko'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: UserGuideScreen(),
      ),
    );

    expect(find.text('Parent Guide'), findsWidgets);
    expect(find.textContaining('parents and other caregivers'), findsOneWidget);
    expect(
      find.text(
        'Review activity missions, course markers, and sticker rules.',
      ),
      findsOneWidget,
    );
    expect(find.text('What is Timey Rider?'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Course markers'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Course markers'), findsOneWidget);
    expect(
      find.textContaining('Only manually chosen picture markers'),
      findsOneWidget,
    );
  });

  testWidgets('User guide hides motivation section when unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: [Locale('ko'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: UserGuideScreen(),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('동기부여 영상'), findsNothing);
    expect(find.textContaining('일부 구간을 건너뛸 수 있어요'), findsNothing);
  });

  testWidgets('User guide shows motivation section when available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: [Locale('ko'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: UserGuideScreen(motivationMediaAvailable: true),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('동기부여 영상'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('동기부여 영상'), findsOneWidget);
    expect(find.textContaining('일부 구간을 건너뛸 수 있어요'), findsOneWidget);
  });

  testWidgets('User guide shows key Korean guide copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: [Locale('ko'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: UserGuideScreen(motivationMediaAvailable: true),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('코스 마커'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('코스 마커'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('직접 고른 그림 마커').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('직접 고른 그림 마커'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('동기부여 영상'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('동기부여 영상'), findsOneWidget);
    expect(find.textContaining('일부 구간을 건너뛸 수 있어요'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('차량 스티커 받기를 선택하면 선택한 차량 스티커'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('스티커'), findsWidgets);
  });

  testWidgets('Settings screen opens course marker help sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('markerModeHelpButton')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('markerModeHelpButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('markerModeHelpButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.textContaining('직접 고른 그림 마커'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('appHelpSheet')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Settings screen updates course marker mode', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var latestConfig = ActivityTimerConfig.defaults();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: latestConfig,
          onConfigChanged: (config) => latestConfig = config,
        ),
      ),
    );

    expect(find.text('코스 마커'), findsOneWidget);
    final segmentedButtonFinder = find.byKey(
      const ValueKey('markerModeSegmentedButton'),
    );
    final segmentedButton = tester.widget<SegmentedButton<ActivityMarkerMode>>(
      segmentedButtonFinder,
    );
    final segmentedButtonRect = tester.getRect(segmentedButtonFinder);
    final cardRect = tester.getRect(
      find.ancestor(of: segmentedButtonFinder, matching: find.byType(Card)),
    );
    expect(segmentedButton.selected, {ActivityMarkerMode.activityDefault});
    expect(segmentedButton.showSelectedIcon, isFalse);
    expect(segmentedButtonRect.left, greaterThanOrEqualTo(cardRect.left));
    expect(segmentedButtonRect.right, lessThanOrEqualTo(cardRect.right));
    expect(find.text('사용 안 함'), findsOneWidget);
    expect(find.text('직접 선택'), findsOneWidget);
    expect(find.text('자동'), findsOneWidget);
    expect(find.text('활동에 맞게'), findsNothing);
    expect(
      find.text('자동은 활동에 맞는 그림 마커를 미리 보여주고 사용해요. 직접 고른 그림 마커만 활동 기록에 남아요.'),
      findsOneWidget,
    );

    segmentedButton.onSelectionChanged!({ActivityMarkerMode.manual});
    await tester.pump();

    expect(latestConfig.markerMode, ActivityMarkerMode.manual);
  });

  testWidgets('Settings screen hides motivation section when unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('motivationVideoHelpButton')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsNothing,
    );
    expect(changedConfig, isNull);
  });

  testWidgets('Settings screen shows motivation section when available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          motivationMediaAvailable: true,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('motivationVideoHelpButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
      findsOneWidget,
    );
  });

  testWidgets('Settings screen updates motivation video settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var latestConfig = ActivityTimerConfig.defaults();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: latestConfig,
          onConfigChanged: (config) => latestConfig = config,
          motivationMediaAvailable: true,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
        )
        .onChanged!(true);
    await tester.pump();

    expect(latestConfig.motivationVideoUseCustomInterval, isTrue);
    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsOneWidget,
    );

    tester
        .widget<SegmentedButton<int>>(
          find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
        )
        .onSelectionChanged!({10});
    await tester.pump();

    expect(latestConfig.motivationVideoInterval, const Duration(minutes: 10));

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        )
        .onChanged!(false);
    await tester.pump();

    expect(latestConfig.motivationVideoEnabled, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
          )
          .onChanged,
      isNull,
    );
    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsNothing,
    );
  });

  testWidgets('Settings screen opens motivation video help sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
          motivationMediaAvailable: true,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('motivationVideoHelpButton')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('motivationVideoHelpButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('motivationVideoHelpButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.text('동기부여 영상 안내'), findsWidgets);
    expect(find.textContaining('일부 구간을 건너뛸 수 있어요'), findsOneWidget);
    expect(find.textContaining('3분, 5분, 10분'), findsOneWidget);
  });

  testWidgets('Home settings apply motivation video settings to new timers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    ActivityTimerConfig? changedConfig;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            childName: '지율',
            duration: const Duration(minutes: 25),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (config) => changedConfig = config,
          motivationMediaAvailable: true,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
        )
        .onChanged!(true);
    await tester.pump();

    tester
        .widget<SegmentedButton<int>>(
          find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
        )
        .onSelectionChanged!({5});
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(changedConfig?.motivationVideoUseCustomInterval, isTrue);
    expect(changedConfig?.motivationVideoInterval, const Duration(minutes: 5));

    await openTimerBuilder(tester);
    await startTimerBuilder(tester);

    final timerConfig = tester
        .widget<TimerScreen>(find.byType(TimerScreen))
        .config;
    expect(timerConfig.duration, const Duration(minutes: 2));
    expect(timerConfig.motivationVideoUseCustomInterval, isTrue);
    expect(timerConfig.motivationVideoInterval, const Duration(minutes: 5));
  });

  testWidgets('Settings screen keeps vehicle and avatar actions on home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    await startTestApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('라이더 설정'), findsNothing);
    expect(find.text('기본 이미지 사용 중'), findsNothing);
    expect(find.text('라이더 설정하기'), findsNothing);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(vehicleChoiceFinder('motorcycle'), findsNothing);
  });

  testWidgets('Settings screen hides custom avatar state when active', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final avatarFile = createTemporaryAvatarImage();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            avatarMode: AvatarImageMode.custom,
            customAvatarImagePath: avatarFile.path,
            customAvatarVehicleId: 'motorcycle',
          ),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('라이더 설정'), findsNothing);
    expect(find.text('직접 만든 라이더 사용 중'), findsNothing);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(find.byType(VehicleSelectionCard), findsNothing);
  });
}
