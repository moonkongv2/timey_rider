import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/vehicle.dart';
import 'package:timey_rider/models/vehicle_avatar_presentation.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';
import 'package:timey_rider/theme/app_theme.dart';
import 'package:timey_rider/widgets/avatar/avatar_composite_preview.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/vehicle_selection_card.dart';
import 'package:timey_rider/widgets/vehicle_widget.dart';

import 'support/app_test_harness.dart';
import 'support/avatar_test_harness.dart';

void main() {
  testWidgets('Home screen shows vehicle summary above timer builder', (
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

    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.byKey(const ValueKey('createTimerCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(find.text('변경'), findsOneWidget);
    expect(find.text('오토바이'), findsNothing);
    expect(find.text('소방차'), findsNothing);
    expect(find.text('경찰차'), findsNothing);
    expect(find.text('포크레인'), findsNothing);

    for (final vehicle in VehicleCatalog.all) {
      expect(
        assetImage(vehicle.selectionImagePath),
        vehicle.id == 'motorcycle' ? findsOneWidget : findsNothing,
      );
    }
    expect(
      find.byKey(const ValueKey('selectedVehiclePreview')),
      findsOneWidget,
    );
    expect(vehicleChoiceFinder('motorcycle'), findsNothing);

    final vehicleTitleTop = tester.getTopLeft(find.text('오늘의 빠방')).dy;
    final timerBuilderTop = tester
        .getTopLeft(find.byKey(const ValueKey('createTimerCard')))
        .dy;
    expect(timerBuilderTop, greaterThan(vehicleTitleTop));

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();

    expect(find.text('빠방 고르기'), findsOneWidget);
    expect(vehicleChoiceFinder('motorcycle'), findsOneWidget);
    expect(
      tester.getSize(vehicleChoiceFinder('motorcycle')).width,
      tester.getSize(vehicleChoiceFinder('fire_truck')).width,
    );
  });

  testWidgets(
    'Vehicle selection card renders custom avatars on saved choices',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final busAvatarFile = createTemporaryAvatarImage();
      final fireTruckAvatarFile = createTemporaryAvatarImage();
      final avatarConfigs = {
        'bus': VehicleAvatarConfig(
          imagePath: busAvatarFile.path,
          scale: 1.2,
          offsetX: 0.08,
          offsetY: -0.04,
          rotationDegrees: 4.0,
        ),
        'fire_truck': VehicleAvatarConfig(
          imagePath: fireTruckAvatarFile.path,
          scale: 1.35,
          offsetX: -0.06,
          offsetY: 0.03,
          rotationDegrees: -8.0,
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: VehicleSelectionCard(
                title: '차량 선택',
                selectedVehicleId: 'motorcycle',
                onVehicleSelected: (_) {},
                lockedVehicleLabel: '잠김',
                avatarForVehicle: (vehicleId) {
                  final avatarConfig = avatarConfigs[vehicleId];
                  if (avatarConfig == null) {
                    return null;
                  }

                  return VehicleAvatarPresentation(
                    mode: AvatarImageMode.custom,
                    imagePath: avatarConfig.imagePath,
                    scale: avatarConfig.scale,
                    offsetX: avatarConfig.offsetX,
                    offsetY: avatarConfig.offsetY,
                    rotationDegrees: avatarConfig.rotationDegrees,
                  );
                },
                avatarImageBuilder: (context, imagePath) {
                  return ColoredBox(
                    key: ValueKey('customAvatar.$imagePath'),
                    color: Colors.pink,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(ValueKey('customAvatar.${busAvatarFile.path}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('customAvatar.${fireTruckAvatarFile.path}')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Vehicle selection card limits custom avatar size in selected preview',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final avatarFile = createTemporaryAvatarImage();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: VehicleSelectionCard(
                title: '차량 선택',
                selectedVehicleId: 'fire_truck',
                onVehicleSelected: (_) {},
                lockedVehicleLabel: '잠김',
                showSelectedPreview: true,
                showChoices: false,
                avatar: VehicleAvatarPresentation(
                  mode: AvatarImageMode.custom,
                  imagePath: avatarFile.path,
                  scale: 1.25,
                  offsetX: 0.07,
                  offsetY: -0.03,
                  rotationDegrees: 5.0,
                ),
                avatarImageBuilder: (context, imagePath) {
                  return const ColoredBox(
                    key: ValueKey('avatarCompositeOverlayImage'),
                    color: Colors.pink,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('selectedVehiclePreview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('avatarCompositeOverlayImage')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) {
          return widget is AvatarCompositePreview &&
              widget.vehicle.id == 'fire_truck' &&
              widget.size == 96.0 &&
              widget.avatarScale == 1.25 &&
              widget.avatarOffsetX == 0.07 &&
              widget.avatarOffsetY == -0.03 &&
              widget.avatarRotationDegrees == 5.0;
        }),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets('Vehicle selection card shows locked choices', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: VehicleSelectionCard(
              title: 'Choose vehicle',
              selectedVehicleId: 'motorcycle',
              onVehicleSelected: (_) {},
              isVehicleLocked: (vehicleId) => vehicleId == 'fire_truck',
              lockedVehicleLabel: 'Pack',
              onLockedVehiclePressed: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pack'), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets(
    'Vehicle selection card sends locked taps to locked callback only',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? selectedVehicleId;
      String? lockedVehicleId;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: VehicleSelectionCard(
                title: 'Choose vehicle',
                selectedVehicleId: 'motorcycle',
                onVehicleSelected: (vehicleId) {
                  selectedVehicleId = vehicleId;
                },
                isVehicleLocked: (vehicleId) => vehicleId == 'fire_truck',
                lockedVehicleLabel: 'Pack',
                onLockedVehiclePressed: (vehicleId) {
                  lockedVehicleId = vehicleId;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(vehicleChoiceFinder('fire_truck'));
      await tester.pump();

      expect(selectedVehicleId, isNull);
      expect(lockedVehicleId, 'fire_truck');

      await tester.tap(vehicleChoiceFinder('supercar'));
      await tester.pump();

      expect(selectedVehicleId, 'supercar');
    },
  );

  testWidgets('Selected vehicle on home is saved to preferences', (
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

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      vehicleChoiceFinder('supercar'),
      find.byType(Scrollable).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(vehicleChoiceFinder('supercar'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('vehicleId'), 'supercar');
    expect(
      assetImage(VehicleCatalog.supercar.selectionAssetPath!),
      findsOneWidget,
    );
    expect(
      assetImage(VehicleCatalog.motorcycle.selectionImagePath),
      findsNothing,
    );
  });

  testWidgets('Home vehicle picker does not select locked premium vehicles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppTexts.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(childName: 'Haru'),
          activityProgressService: LocalActivityProgressService(),
          purchaseController: purchaseController,
          purchaseState: const VehiclePackPurchaseState.initial(),
          vehiclePackInfoPresenter: (_, {required vehicleId}) async {
            infoSheetVehicleIds.add(vehicleId);
            return true;
          },
          parentGatePresenter: (_) async {
            parentGateCallCount += 1;
            return true;
          },
          vehiclePackPurchasePresenter:
              (_, {required controller, required vehicleId}) async {
                purchaseSheetVehicleIds.add(vehicleId);
                purchaseClient.emitPurchase(
                  const IapPurchaseUpdate(
                    productId: 'vehicle_pack',
                    status: IapPurchaseStatus.purchased,
                    purchaseId: 'home-purchase',
                  ),
                );
                await pumpPurchaseControllerUnlock(controller);
              },
          onConfigChanged: (config) {
            changedConfig = config;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_rounded), findsWidgets);

    await tester.tap(vehicleChoiceFinder('fire_truck'));
    await tester.pumpAndSettle();

    expect(changedConfig?.vehicleId, 'fire_truck');
    expect(infoSheetVehicleIds, ['fire_truck']);
    expect(parentGateCallCount, 1);
    expect(purchaseSheetVehicleIds, ['fire_truck']);
    expect(vehicleChoiceFinder('fire_truck'), findsNothing);
  });

  testWidgets('Vehicle selection updates even without parent rebuild', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    ActivityTimerConfig? changedConfig;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            childName: '지율',
            vehicleId: 'fire_truck',
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();

    final selectedColor = vehicleChoiceMaterial(tester, 'fire_truck').color;
    final unselectedColor = vehicleChoiceMaterial(tester, 'police_car').color;
    expect(selectedColor, isNot(unselectedColor));

    await tester.dragUntilVisible(
      vehicleChoiceFinder('police_car'),
      find.byType(Scrollable).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(vehicleChoiceFinder('police_car'));
    await tester.pumpAndSettle();

    expect(changedConfig?.vehicleId, 'police_car');
    expect(vehicleChoiceFinder('fire_truck'), findsNothing);
    expect(vehicleChoiceFinder('police_car'), findsNothing);
    expect(
      assetImage(VehicleCatalog.policeCar.selectionImagePath),
      findsOneWidget,
    );
  });

  testWidgets('Child name can be changed in settings', (tester) async {
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

    expect(find.text('아이 이름'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '서아');
    await tester.tap(find.text('이름 저장'));
    await tester.pump();

    expect(find.text('이름을 저장했어요.'), findsOneWidget);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '서아');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('서아의 활동 기록'), findsOneWidget);
  });

  testWidgets('Empty child name in settings shows validation message', (
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

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('이름 저장'));
    await tester.pump();

    expect(find.text('아이 이름을 입력해 주세요.'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '지율');
  });

  testWidgets('Vehicle widget falls back to emoji for missing assets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleWidget(
            vehicle: VehicleDefinition(
              id: 'missing_vehicle',
              labelKo: '없는 차',
              labelEn: 'Missing vehicle',
              labelJa: 'ないのりもの',
              labelEs: 'Vehículo faltante',
              labelPtBr: 'Veículo ausente',
              emoji: '🚒',
              assetPath: 'assets/images/missing_vehicle.png',
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('🚒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Timer screen does not apply avatar saved for another vehicle', (
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
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            vehicleId: 'excavator',
            avatarMode: AvatarImageMode.custom,
            customAvatarImagePath: avatarFile.path,
            customAvatarVehicleId: 'police_car',
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byType(RoadView), findsOneWidget);
    expect(
      tester.widget<RoadView>(find.byType(RoadView)).avatar.mode,
      AvatarImageMode.defaultImage,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Timer screen applies avatar config for selected vehicle', (
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
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            vehicleId: 'fire_truck',
            avatarMode: AvatarImageMode.custom,
            customAvatarsByVehicle: {
              'fire_truck': VehicleAvatarConfig(
                imagePath: avatarFile.path,
                scale: 1.4,
                offsetX: 0.11,
                offsetY: -0.07,
                rotationDegrees: 9.0,
              ),
            },
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.avatar.mode, AvatarImageMode.custom);
    expect(roadView.avatar.imagePath, avatarFile.path);
    expect(roadView.avatar.scale, 1.4);
    expect(roadView.avatar.offsetX, 0.11);
    expect(roadView.avatar.offsetY, -0.07);
    expect(roadView.avatar.rotationDegrees, 9.0);
  });
}
