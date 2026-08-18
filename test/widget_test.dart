import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/catalogs/activity_marker_catalog.dart';
import 'package:timey_rider/catalogs/avatar_prompt_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/main.dart' as app;
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_progress_snapshot.dart';
import 'package:timey_rider/models/activity_session_result.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/purchase_entitlement.dart';
import 'package:timey_rider/models/reward_item.dart';
import 'package:timey_rider/models/vehicle.dart';
import 'package:timey_rider/models/vehicle_avatar_presentation.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/activity_history_screen.dart';
import 'package:timey_rider/screens/reward_goal_screen.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/screens/settings_screen.dart';
import 'package:timey_rider/screens/sticker_collection_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/screens/user_guide_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/iap_purchase_client.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/local_purchase_entitlement_store.dart';
import 'package:timey_rider/services/motivation_audio_service.dart';
import 'package:timey_rider/services/orientation_service.dart';
import 'package:timey_rider/services/screen_awake_service.dart';
import 'package:timey_rider/services/timer_audio_service.dart';
import 'package:timey_rider/services/vehicle_pack_purchase_controller.dart';
import 'package:timey_rider/theme/app_colors.dart';
import 'package:timey_rider/theme/app_theme.dart';
import 'package:timey_rider/widgets/app/app_bouncy_button.dart';
import 'package:timey_rider/widgets/avatar/avatar_composite_preview.dart';
import 'package:timey_rider/widgets/goal_star_pulse.dart';
import 'package:timey_rider/widgets/road_painter.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/reward_sticker_image.dart';
import 'package:timey_rider/widgets/result_sticker_album_sheet.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';
import 'package:timey_rider/widgets/vehicle_selection_card.dart';
import 'package:timey_rider/widgets/vehicle_widget.dart';

void main() {
  setUpAll(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(390, 844);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });


  test('Reward catalog uses vehicle stickers', () {
    final ids = RewardCatalog.all.map((reward) => reward.id).toList();
    final expectedIds = VehicleCatalog.all.map((vehicle) {
      return RewardCatalog.vehicleStickerIdForVehicle(vehicle.id);
    }).toList();
    final motorcycleSticker = RewardCatalog.findVehicleStickerByVehicleId(
      VehicleCatalog.motorcycle.id,
    );

    expect(RewardCatalog.all, hasLength(VehicleCatalog.all.length));
    expect(VehicleCatalog.all.take(2).map((vehicle) => vehicle.id), [
      VehicleCatalog.motorcycle.id,
      VehicleCatalog.supercar.id,
    ]);
    expect(ids, expectedIds);
    expect(RewardCatalog.successStickers, same(RewardCatalog.all));
    expect(motorcycleSticker, isNotNull);
    expect(motorcycleSticker!.id, 'sticker_vehicle_motorcycle');
    expect(
      RewardCatalog.findById(motorcycleSticker.id),
      same(motorcycleSticker),
    );
    expect(motorcycleSticker.type, RewardType.sticker);
    expect(motorcycleSticker.emoji, VehicleCatalog.motorcycle.emoji);
    expect(
      motorcycleSticker.imageAssetPath,
      VehicleCatalog.motorcycle.assetPath,
    );
    expect(
      motorcycleSticker.labelForLanguage('ko'),
      '${VehicleCatalog.motorcycle.labelKo} 스티커',
    );
    expect(
      motorcycleSticker.labelForLanguage('en'),
      '${VehicleCatalog.motorcycle.labelEn} Sticker',
    );
    expect(
      motorcycleSticker.labelForLanguage('ja'),
      '${VehicleCatalog.motorcycle.labelJa}ステッカー',
    );
    expect(
      motorcycleSticker.labelForLanguage('es'),
      'Pegatina de ${VehicleCatalog.motorcycle.labelEs}',
    );
    expect(
      motorcycleSticker.labelForLanguage('pt'),
      'Adesivo de ${VehicleCatalog.motorcycle.labelPtBr}',
    );
    expect(motorcycleSticker.vehicleId, VehicleCatalog.motorcycle.id);

    for (final vehicle in VehicleCatalog.all) {
      final sticker = RewardCatalog.findVehicleStickerByVehicleId(vehicle.id);

      expect(sticker, isNotNull);
      expect(sticker!.id, 'sticker_vehicle_${vehicle.id}');
      expect(sticker.imageAssetPath, vehicle.assetPath);
      expect(sticker.vehicleId, vehicle.id);
      expect(RewardCatalog.findById(sticker.id), same(sticker));
    }

    expect(
      RewardCatalog.findVehicleStickerByVehicleId('unknown_vehicle'),
      isNull,
    );
  });

  testWidgets('Reward sticker image falls back for missing assets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const missingAssetReward = RewardDefinition(
      id: 'missing_reward_asset',
      type: RewardType.sticker,
      emoji: '?',
      imageAssetPath: 'assets/images/missing_reward_asset.png',
      labelKo: '없는 스티커',
      labelEn: 'Missing Sticker',
      labelJa: 'ないステッカー',
      labelEs: 'Pegatina faltante',
      labelPtBr: 'Adesivo ausente',
    );

    await tester.pumpWidget(
      const MaterialApp(home: RewardStickerImage(reward: missingAssetReward)),
    );
    await tester.pumpAndSettle();

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('Reward sticker image keeps framed outer sizes', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const missingAssetReward = RewardDefinition(
      id: 'missing_reward_asset',
      type: RewardType.sticker,
      emoji: '?',
      imageAssetPath: 'assets/images/missing_reward_asset.png',
      labelKo: '없는 스티커',
      labelEn: 'Missing Sticker',
      labelJa: 'ないステッカー',
      labelEs: 'Pegatina faltante',
      labelPtBr: 'Adesivo ausente',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            RewardStickerImage(
              key: ValueKey('rewardSticker78'),
              reward: missingAssetReward,
              size: 78,
            ),
            RewardStickerImage(
              key: ValueKey('rewardSticker48'),
              reward: missingAssetReward,
              size: 48,
            ),
            RewardStickerImage(
              key: ValueKey('rewardSticker28'),
              reward: missingAssetReward,
              size: 28,
            ),
            RewardStickerImage(
              key: ValueKey('rewardSticker24Locked'),
              reward: missingAssetReward,
              size: 24,
              locked: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('rewardSticker78'))),
      const Size.square(78),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('rewardSticker48'))),
      const Size.square(48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('rewardSticker28'))),
      const Size.square(28),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('rewardSticker24Locked'))),
      const Size.square(24),
    );
  });

  testWidgets('Locked reward sticker image renders as a silhouette', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reward = RewardCatalog.findVehicleStickerByVehicleId(
      VehicleCatalog.fireTruck.id,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            RewardStickerImage(
              key: const ValueKey('unlockedVehicleSticker'),
              reward: reward,
            ),
            RewardStickerImage(
              key: const ValueKey('lockedVehicleSticker'),
              reward: reward,
              locked: true,
            ),
          ],
        ),
      ),
    );

    final unlockedImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('unlockedVehicleSticker')),
        matching: find.byType(Image),
      ),
    );
    final lockedImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('lockedVehicleSticker')),
        matching: find.byType(Image),
      ),
    );

    expect(unlockedImage.color, isNull);
    expect(unlockedImage.colorBlendMode, isNull);
    expect(lockedImage.color, AppColors.textMuted.withValues(alpha: 0.82));
    expect(lockedImage.colorBlendMode, BlendMode.srcIn);
  });

  testWidgets('Result sticker album uses bounded three-column landscape grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpOpenResultStickerAlbumSheet(tester);

    expect(find.text('차량 스티커 보관함'), findsOneWidget);
    expect(find.text('오토바이 스티커'), findsOneWidget);

    final firstCard = tester.getRect(find.byType(Card).at(0));
    final secondCard = tester.getRect(find.byType(Card).at(1));
    final thirdCard = tester.getRect(find.byType(Card).at(2));
    final stickerSizes = tester
        .widgetList<RewardStickerImage>(find.byType(RewardStickerImage))
        .map((widget) => widget.size);

    expect((firstCard.top - secondCard.top).abs(), lessThan(0.1));
    expect((firstCard.top - thirdCard.top).abs(), lessThan(0.1));
    expect(firstCard.left, greaterThan(70));
    expect(thirdCard.right, lessThan(780));
    expect(firstCard.width, lessThan(240));
    expect(stickerSizes.every((size) => size <= 96), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Result sticker album keeps two-column portrait grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpOpenResultStickerAlbumSheet(tester);

    expect(find.text('차량 스티커 보관함'), findsOneWidget);
    expect(find.text('오토바이 스티커'), findsOneWidget);

    final firstCard = tester.getRect(find.byType(Card).at(0));
    final secondCard = tester.getRect(find.byType(Card).at(1));
    final thirdCard = tester.getRect(find.byType(Card).at(2));
    final firstSticker = tester.widget<RewardStickerImage>(
      find.byType(RewardStickerImage).first,
    );

    expect((firstCard.top - secondCard.top).abs(), lessThan(0.1));
    expect(thirdCard.top, greaterThan(firstCard.bottom));
    expect(firstCard.width, lessThan(180));
    expect(firstSticker.size, 85);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sticker collection shows localized vehicle sticker names', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    await _recordActivityResult(
      service,
      _activityResult(),
      vehicleId: VehicleCatalog.fireTruck.id,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: StickerCollectionScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fire truck Sticker'), findsOneWidget);
  });




  test('Result outcome helpers separate positive and rewardable statuses', () {
    expect(
      isPositiveResult(ActivityCompletionStatus.completedBeforeEnd),
      isTrue,
    );
    expect(isPositiveResult(ActivityCompletionStatus.timeEnded), isTrue);
    expect(isPositiveResult(ActivityCompletionStatus.needsMoreTime), isFalse);

    expect(isRewardableResult(ActivityCompletionStatus.completedAtEnd), isTrue);
    expect(isRewardableResult(ActivityCompletionStatus.timeEnded), isFalse);
    expect(isRewardableResult(ActivityCompletionStatus.canceled), isFalse);
  });

  test('Arrival dialog copy uses the selected vehicle label', () {
    final timerTexts = AppTexts.ko.timer;

    expect(timerTexts.arrivalDialogMessage('경찰차', '양치'), '경찰차가 도착했어. 미션을 마쳤어?');
    expect(
      timerTexts.arrivalDialogMessage('포크레인', '정리'),
      '포크레인이 도착했어. 미션을 마쳤어?',
    );
  });

  test('Timer arrival dialog copy uses the configured vehicle', () {
    expect(
      timerArrivalDialogMessage(
        texts: AppTexts.ko.timer,
        vehicleId: 'excavator',
        languageCode: 'ko',
        activityLabel: '양치',
      ),
      '포크레인이 도착했어. 미션을 마쳤어?',
    );
    expect(
      timerArrivalDialogMessage(
        texts: AppTexts.en.timer,
        vehicleId: 'police_car',
        languageCode: 'en',
        activityLabel: 'Brush Teeth',
      ),
      'The police car arrived. Did you finish the mission?',
    );
  });

  test('Avatar prompt catalog returns prompts for every vehicle', () {
    for (final vehicle in VehicleCatalog.all) {
      final prompt = AvatarPromptCatalog.promptForVehicle(vehicle, 'ko');

      expect(prompt.trim(), isNotEmpty, reason: vehicle.id);
      expect(prompt, contains('Timey Rider에 사용할 라이더 이미지'));
      expect(prompt, contains('아이의 실제 얼굴 특징을 최대한 유지'));
      expect(prompt, contains('새로운 캐릭터처럼 바꾸지'));
      expect(prompt, contains('배경은 반드시 투명 배경'));
      expect(prompt, contains('텍스트, 로고, 워터마크 금지'));
    }
  });

  test('Avatar prompt catalog includes vehicle-specific Korean guidance', () {
    final motorcyclePrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.motorcycle,
      'ko',
    );
    final fireTruckPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.fireTruck,
      'ko',
    );
    final policeCarPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.policeCar,
      'ko',
    );
    final excavatorPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.excavator,
      'ko',
    );
    final airplanePrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.airplane,
      'ko',
    );
    final busPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.bus,
      'ko',
    );
    final supercarPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.supercar,
      'ko',
    );
    final trainPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.train,
      'ko',
    );
    final brachioPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.brachio,
      'ko',
    );
    final pteranodonPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.pteranodon,
      'ko',
    );

    expect(
      motorcyclePrompt.contains('오토바이') || motorcyclePrompt.contains('라이더'),
      isTrue,
    );
    expect(fireTruckPrompt, contains('소방관'));
    expect(policeCarPrompt, contains('경찰'));
    expect(
      excavatorPrompt.contains('안전모') || excavatorPrompt.contains('포크레인'),
      isTrue,
    );
    expect(airplanePrompt, contains('파일럿'));
    expect(busPrompt, contains('운전기사'));
    expect(supercarPrompt, contains('레이서'));
    expect(trainPrompt, contains('기관사'));
    expect(brachioPrompt, contains('브라키오'));
    expect(pteranodonPrompt, contains('프테라노돈'));
  });




  testWidgets('Remaining time setting can be turned off', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'durationMinutes': 25,
      'markerMode': 'off',
    });

    await _startApp(tester, const Locale('ko'));

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

    await _openTimerBuilder(tester);
    await _startTimerBuilder(tester);

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
    expect(find.text('활동 미션, 응원 영상, 차량 스티커 규칙을 확인해요.'), findsOneWidget);

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
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: _FakeIapPurchaseClient(),
      entitlementStore: _FakePurchaseEntitlementStore(),
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
    final purchaseClient = _FakeIapPurchaseClient();
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: purchaseClient,
      entitlementStore: _FakePurchaseEntitlementStore(),
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

    await tester.tap(
      find.byKey(const ValueKey('restorePurchaseSettingsTile')),
    );
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

  testWidgets('Settings screen shows link failure message', (
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
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: _FakeIapPurchaseClient(),
      entitlementStore: _FakePurchaseEntitlementStore(
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
        'Review activity missions, motivation videos, and sticker rules.',
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

    expect(find.byKey(const ValueKey('motivationVideoHelpButton')), findsNothing);
    expect(find.byKey(const ValueKey('motivationVideoEnabledSwitch')), findsNothing);
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

    expect(find.byKey(const ValueKey('motivationVideoHelpButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('motivationVideoEnabledSwitch')), findsOneWidget);
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
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
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

    await _openTimerBuilder(tester);
    await _startTimerBuilder(tester);

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
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('라이더 설정'), findsNothing);
    expect(find.text('기본 이미지 사용 중'), findsNothing);
    expect(find.text('라이더 설정하기'), findsNothing);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(_vehicleChoiceFinder('motorcycle'), findsNothing);
  });

  testWidgets('Settings screen hides custom avatar state when active', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final avatarFile = _createTemporaryAvatarImage();

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

  testWidgets('Home screen shows vehicle summary above timer builder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await _startApp(tester, const Locale('ko'));

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
        _assetImage(vehicle.selectionImagePath),
        vehicle.id == 'motorcycle' ? findsOneWidget : findsNothing,
      );
    }
    expect(
      find.byKey(const ValueKey('selectedVehiclePreview')),
      findsOneWidget,
    );
    expect(_vehicleChoiceFinder('motorcycle'), findsNothing);

    final vehicleTitleTop = tester.getTopLeft(find.text('오늘의 빠방')).dy;
    final timerBuilderTop = tester
        .getTopLeft(find.byKey(const ValueKey('createTimerCard')))
        .dy;
    expect(timerBuilderTop, greaterThan(vehicleTitleTop));

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();

    expect(find.text('빠방 고르기'), findsOneWidget);
    expect(_vehicleChoiceFinder('motorcycle'), findsOneWidget);
    expect(
      tester.getSize(_vehicleChoiceFinder('motorcycle')).width,
      tester.getSize(_vehicleChoiceFinder('fire_truck')).width,
    );
  });

  testWidgets(
    'Vehicle selection card renders custom avatars on saved choices',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final busAvatarFile = _createTemporaryAvatarImage();
      final fireTruckAvatarFile = _createTemporaryAvatarImage();
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
      final avatarFile = _createTemporaryAvatarImage();

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

      await tester.tap(_vehicleChoiceFinder('fire_truck'));
      await tester.pump();

      expect(selectedVehicleId, isNull);
      expect(lockedVehicleId, 'fire_truck');

      await tester.tap(_vehicleChoiceFinder('supercar'));
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
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(_vehicleChoiceFinder('supercar'), find.byType(Scrollable).last, const Offset(0, -100)); await tester.pumpAndSettle(); await tester.tap(_vehicleChoiceFinder('supercar'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('vehicleId'), 'supercar');
    expect(
      _assetImage(VehicleCatalog.supercar.selectionAssetPath!),
      findsOneWidget,
    );
    expect(
      _assetImage(VehicleCatalog.motorcycle.selectionImagePath),
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
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    ActivityTimerConfig? changedConfig;
    final infoSheetVehicleIds = <String>[];
    var parentGateCallCount = 0;
    final purchaseSheetVehicleIds = <String>[];
    final purchaseClient = _FakeIapPurchaseClient();
    final purchaseController = VehiclePackPurchaseController(
      purchaseClient: purchaseClient,
      entitlementStore: _FakePurchaseEntitlementStore(),
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
                await _pumpPurchaseControllerUnlock(controller);
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

    await tester.tap(_vehicleChoiceFinder('fire_truck'));
    await tester.pumpAndSettle();

    expect(changedConfig?.vehicleId, 'fire_truck');
    expect(infoSheetVehicleIds, ['fire_truck']);
    expect(parentGateCallCount, 1);
    expect(purchaseSheetVehicleIds, ['fire_truck']);
    expect(_vehicleChoiceFinder('fire_truck'), findsNothing);
  });

  testWidgets('Vehicle selection updates even without parent rebuild', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
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

    final selectedColor = _vehicleChoiceMaterial(tester, 'fire_truck').color;
    final unselectedColor = _vehicleChoiceMaterial(tester, 'police_car').color;
    expect(selectedColor, isNot(unselectedColor));

    await tester.dragUntilVisible(_vehicleChoiceFinder('police_car'), find.byType(Scrollable).last, const Offset(0, -100)); await tester.pumpAndSettle(); await tester.tap(_vehicleChoiceFinder('police_car'));
    await tester.pumpAndSettle();

    expect(changedConfig?.vehicleId, 'police_car');
    expect(_vehicleChoiceFinder('fire_truck'), findsNothing);
    expect(_vehicleChoiceFinder('police_car'), findsNothing);
    expect(
      _assetImage(VehicleCatalog.policeCar.selectionImagePath),
      findsOneWidget,
    );
  });

  testWidgets('Child name can be changed in settings', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await _startApp(tester, const Locale('ko'));

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
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await _startApp(tester, const Locale('ko'));

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
    final avatarFile = _createTemporaryAvatarImage();

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
    final avatarFile = _createTemporaryAvatarImage();

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

  testWidgets('TimerScreen passes marker ids to road markers', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            markerIds: const ['top_teeth', 'bottom_teeth'],
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
    expect(
      roadView.markers,
      hasLength(
        ActivityMarkerCatalog.courseSlotCountForDuration(
          ActivityTimerConfig.defaults().duration,
        ),
      ),
    );
    expect(roadView.markers.map((marker) => marker.id).toSet(), {
      'top_teeth',
      'bottom_teeth',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerScreen hides road markers when marker mode is off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            markerMode: ActivityMarkerMode.off,
            markerIds: const [],
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
    expect(roadView.markers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerScreen passes configured duration to the road course', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
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
    expect(roadView.courseDuration, const Duration(minutes: 60));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerScreen cancels preview safely when disposed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerScreen saves an active session when started', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final store = ActiveActivityTimerSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 35),
            childName: '지율',
            vehicleId: 'bus',
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => startedAt,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final session = await store.load();
    expect(session, isNotNull);
    expect(session!.startedAt, startedAt);
    expect(session.duration, const Duration(minutes: 35));
    expect(session.config.childName, '지율');
    expect(session.config.vehicleId, 'bus');
    expect(session.state, ActiveActivityTimerSessionState.running);
    expect(session.totalPausedDuration, Duration.zero);
    expect(session.pausedAt, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('TimerScreen disables controls until the timer starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    var controls = tester.widget<TimerControlBar>(find.byType(TimerControlBar));
    expect(controls.onPauseResume, isNull);
    expect(controls.onComplete, isNull);

    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    controls = tester.widget<TimerControlBar>(find.byType(TimerControlBar));
    expect(controls.onPauseResume, isNotNull);
    expect(controls.onComplete, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('TimerScreen starts timer BGM after preview finishes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(timerAudioService.calls, ['playCourseLoading']);

    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(timerAudioService.calls, [
      'playCourseLoading',
      'stopCourseLoading',
      'playReadyStartBeep',
      'stopReadyStartBeep',
      'startOrResumeBgm',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen does not start timer BGM when sound is disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
            soundEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(timerAudioService.calls, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen does not repeatedly start BGM while running', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 48; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(
      timerAudioService.calls.where((call) => call == 'startOrResumeBgm'),
      ['startOrResumeBgm'],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'TimerScreen short startup skips course loading but plays ready beep',
    (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 5),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(timerAudioService.calls, [
      'playReadyStartBeep',
      'stopReadyStartBeep',
      'startOrResumeBgm',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen sound toggle stops course loading during startup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(timerAudioService.calls, ['playCourseLoading']);

    await tester.tap(find.byKey(const ValueKey('timerSoundToggleButton')));
    await tester.pump();

    expect(timerAudioService.calls, [
      'playCourseLoading',
      'stopCourseLoading',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'TimerScreen lifecycle pauses and resumes course loading preview',
    (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(timerAudioService.calls, ['playCourseLoading']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(timerAudioService.calls, [
      'playCourseLoading',
      'stopCourseLoading',
      'playCourseLoading',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen lifecycle does not replay ready beep', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 23; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(
      timerAudioService.calls.where((call) => call == 'playReadyStartBeep'),
      ['playReadyStartBeep'],
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(
      timerAudioService.calls.where((call) => call == 'playReadyStartBeep'),
      ['playReadyStartBeep'],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen pauses and resumes timer BGM with controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(timerAudioService.calls.last, 'startOrResumeBgm');
    timerAudioService.calls.clear();

    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();
    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();

    expect(timerAudioService.calls, [
      'pauseBgm',
      'startOrResumeBgm',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen syncs timer BGM with app lifecycle', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(timerAudioService.calls.last, 'startOrResumeBgm');
    timerAudioService.calls.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(timerAudioService.calls, [
      'pauseBgm',
      'startOrResumeBgm',
    ]);

    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(timerAudioService.calls, [
      'pauseBgm',
      'startOrResumeBgm',
      'pauseBgm',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen toggles sound and syncs timer BGM', (tester) async {
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
    final timerAudioService = _FakeTimerAudioService();
    final changedConfigs = <ActivityTimerConfig>[];
    final store = ActiveActivityTimerSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: changedConfigs.add,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(timerAudioService.calls.last, 'startOrResumeBgm');
    timerAudioService.calls.clear();

    await tester.tap(find.byKey(const ValueKey('timerSoundToggleButton')));
    await tester.pump();

    expect(changedConfigs.last.soundEnabled, isFalse);
    expect(timerAudioService.calls, ['stopBgm']);
    var session = await store.load();
    expect(session, isNotNull);
    expect(session!.config.soundEnabled, isFalse);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('timerSoundToggleButton')));
    await tester.pump();

    expect(changedConfigs.last.soundEnabled, isTrue);
    expect(timerAudioService.calls, [
      'stopBgm',
      'startOrResumeBgm',
    ]);
    session = await store.load();
    expect(session, isNotNull);
    expect(session!.config.soundEnabled, isTrue);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen restored sessions sync timer BGM by state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final startedAt = DateTime(2026, 6, 10, 8);

    Future<List<String>> pumpRestored(
      ActiveActivityTimerSessionState state,
    ) async {
      final timerAudioService = _FakeTimerAudioService();
      final config = ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(minutes: 10),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            restoredSession: ActiveActivityTimerSession(
              sessionId: 'restored-${state.name}',
              startedAt: startedAt,
              config: config,
              state: state,
              pausedAt: state == ActiveActivityTimerSessionState.paused
                  ? startedAt.add(const Duration(minutes: 2))
                  : null,
            ),
            activityProgressService: LocalActivityProgressService(),
            timerAudioService: timerAudioService,
            now: () => startedAt.add(const Duration(minutes: 3)),
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      return timerAudioService.calls;
    }

    expect(
      await pumpRestored(ActiveActivityTimerSessionState.running),
      ['startOrResumeBgm', 'stopBgm', 'stopAll'],
    );
    expect(
      await pumpRestored(ActiveActivityTimerSessionState.paused),
      ['pauseBgm', 'stopBgm', 'stopAll'],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen stops injected timer audio service on dispose', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
            soundEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(timerAudioService.calls, ['stopAll']);
  });

  testWidgets('TimerScreen stops timer BGM when timer arrives', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2026, 6, 10, 8);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 1),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(timerAudioService.calls.last, 'startOrResumeBgm');
    timerAudioService.calls.clear();

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(timerAudioService.calls, ['stopBgm']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen stops timer BGM on manual completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = _FakeTimerAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(timerAudioService.calls.last, 'startOrResumeBgm');
    timerAudioService.calls.clear();

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(timerAudioService.calls.first, 'stopBgm');
    expect(timerAudioService.calls, contains('playFinishDriveLongSfx'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen plays marker SFX when a course marker is passed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final startedAt = DateTime(2026, 6, 10, 8);
    var now = startedAt;
    final timerAudioService = _FakeTimerAudioService();
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 10),
      markerIds: const ['top_teeth', 'bottom_teeth'],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: config,
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'marker-sfx-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(timerAudioService.calls, ['startOrResumeBgm']);

    now = startedAt.add(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(timerAudioService.calls, contains('playMarkerSfx'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen does not play marker SFX when sound is disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final startedAt = DateTime(2026, 6, 10, 8);
    var now = startedAt;
    final timerAudioService = _FakeTimerAudioService();
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 10),
      markerIds: const ['top_teeth', 'bottom_teeth'],
      soundEnabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: config,
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'marker-sfx-muted-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    now = startedAt.add(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(timerAudioService.calls, isNot(contains('playMarkerSfx')));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen updates active session when paused and resumed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    var now = DateTime(2026, 6, 10, 8);
    final store = ActiveActivityTimerSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 35),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 250));
    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final pausedSession = await store.load();
    expect(pausedSession, isNotNull);
    expect(pausedSession!.state, ActiveActivityTimerSessionState.paused);
    expect(pausedSession.pausedAt, now);
    expect(pausedSession.totalPausedDuration, Duration.zero);

    now = now.add(const Duration(minutes: 3));
    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final resumedSession = await store.load();
    expect(resumedSession, isNotNull);
    expect(resumedSession!.state, ActiveActivityTimerSessionState.running);
    expect(resumedSession.pausedAt, isNull);
    expect(resumedSession.totalPausedDuration, const Duration(minutes: 3));

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('TimerScreen clears active session after completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final store = ActiveActivityTimerSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(await store.load(), isNotNull);

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump(const Duration(milliseconds: 100));

    expect(await store.load(), isNull);

    await tester.pumpAndSettle();

    expect(await store.load(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('TimerScreen restores progress from an active session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 20));
    final session = ActiveActivityTimerSession(
      sessionId: 'active-session',
      startedAt: startedAt,
      config: ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(minutes: 60),
        vehicleId: 'bus',
      ),
      state: ActiveActivityTimerSessionState.running,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: session,
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.courseDuration, const Duration(minutes: 60));
    expect(roadView.vehicle.id, 'bus');
    expect(roadView.progress, closeTo(1 / 3, 0.01));
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).restoredSession,
      session,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('TimerScreen course overview scrolls back to vehicle progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );
    final session = ActiveActivityTimerSession(
      sessionId: 'course-overview-scroll-session',
      startedAt: startedAt,
      config: config,
      state: ActiveActivityTimerSessionState.running,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: session,
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    var roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(1 / 3, 0.01));
    expect(roadView.vehicleProgress, closeTo(1 / 3, 0.01));

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));

    roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(1, 0.01));
    expect(roadView.vehicleProgress, closeTo(1 / 3, 0.01));

    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 400));

    roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, lessThan(1));
    expect(roadView.cameraProgress, greaterThan(roadView.vehicleProgress));
    expect(roadView.vehicleProgress, closeTo(1 / 3, 0.01));

    await tester.pump(const Duration(milliseconds: 401));

    roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(roadView.vehicleProgress, 0.01));
    expect(roadView.vehicleProgress, closeTo(1 / 3, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview button follows duration threshold', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    Future<void> pumpRestoredTimer(Duration duration) async {
      final startedAt = DateTime(2026, 6, 10, 8);
      final config = ActivityTimerConfig.defaults().copyWith(
        duration: duration,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            restoredSession: ActiveActivityTimerSession(
              sessionId: 'course-overview-${duration.inMilliseconds}',
              startedAt: startedAt,
              config: config,
              state: ActiveActivityTimerSessionState.running,
            ),
            activityProgressService: LocalActivityProgressService(),
            now: () => startedAt.add(const Duration(minutes: 1)),
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
    }

    await pumpRestoredTimer(const Duration(minutes: 5, seconds: 30));
    expect(find.byKey(const ValueKey('courseOverviewButton')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpRestoredTimer(const Duration(minutes: 5));
    expect(find.byKey(const ValueKey('courseOverviewButton')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen hides course overview during startup preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('courseOverviewButton')), findsNothing);
    final controls = tester.widget<TimerControlBar>(find.byType(TimerControlBar));
    expect(controls.onPauseResume, isNull);
    expect(controls.onComplete, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview cancels on pause', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-pause-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      tester.widget<RoadView>(find.byType(RoadView)).cameraProgress,
      greaterThan(tester.widget<RoadView>(find.byType(RoadView)).vehicleProgress),
    );

    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(roadView.vehicleProgress, 0.01));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview cancels before complete dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-complete-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(roadView.vehicleProgress, 0.01));
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview cancels on arrival', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    var now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-arrival-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    now = startedAt.add(const Duration(minutes: 31));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 1100));

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(roadView.vehicleProgress, 0.01));
    expect(roadView.vehicleProgress, 1);
    expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview keeps BGM playing', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final timerAudioService = _FakeTimerAudioService();
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-bgm-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: timerAudioService,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(timerAudioService.calls, ['startOrResumeBgm']);
    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(timerAudioService.calls, ['startOrResumeBgm']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview fits compact landscape controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-compact-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationMediaAvailable: true,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final controlsRect = tester.getRect(
      find.byKey(const ValueKey('compactLandscapeControls')),
    );
    final courseButtonRect = tester.getRect(
      find.byKey(const ValueKey('courseOverviewButton')),
    );

    expect(find.byType(TimerControlBar), findsNothing);
    expect(find.byIcon(Icons.map_rounded), findsOneWidget);
    expect(controlsRect.contains(courseButtonRect.center), isTrue);
    expect(controlsRect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
    expect(controlsRect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview can run again after finishing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-repeat-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 801));

    var roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(roadView.vehicleProgress, 0.01));
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
          .onPressed,
      isNotNull,
    );

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, greaterThan(roadView.vehicleProgress));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview cancels when exit is canceled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('ko'),
        home: const Scaffold(body: Center(child: Text('타이머 열기'))),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-exit-cancel-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    var roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(roadView.vehicleProgress, 0.01));
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byType(TextButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen course overview exit waits for session clear', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final store = _DelayedClearActiveSessionStore(
      ActiveActivityTimerSession(
        sessionId: 'course-overview-exit-confirm-session',
        startedAt: startedAt,
        config: ActivityTimerConfig.defaults().copyWith(
          duration: const Duration(minutes: 30),
          soundEnabled: false,
        ),
        state: ActiveActivityTimerSessionState.running,
      ),
    );
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('ko'),
        home: const Scaffold(body: Center(child: Text('타이머 열기'))),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: store.currentSession,
          activityProgressService: LocalActivityProgressService(),
          activeSessionStore: store,
          now: () => startedAt.add(const Duration(minutes: 10)),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(store.clearStarted, isTrue);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(store.currentSession, isNotNull);

    store.completeClear();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TimerScreen), findsNothing);
    expect(find.text('타이머 열기'), findsOneWidget);
    expect(store.currentSession, isNull);
  });

  testWidgets('TimerScreen course overview complete reaches result screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'course-overview-complete-result-session',
            startedAt: startedAt,
            config: config,
            state: ActiveActivityTimerSessionState.running,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    tester
        .widget<IconButton>(find.byKey(const ValueKey('courseOverviewButton')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();

    var roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.cameraProgress, closeTo(roadView.vehicleProgress, 0.01));

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(
      tester
          .widget<ResultScreen>(find.byType(ResultScreen))
          .result
          .completionStatus,
      ActivityCompletionStatus.completedBeforeEnd,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'TimerScreen restores arrived sessions at the finish until acknowledged',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
      addTearDown(() async {
        await const ActiveActivityTimerSessionStore().clear();
      });
      final startedAt = DateTime(2026, 6, 10, 8);
      final now = startedAt.add(const Duration(minutes: 30));
      final session = ActiveActivityTimerSession(
        sessionId: 'arrived-session',
        startedAt: startedAt,
        config: ActivityTimerConfig.defaults().copyWith(
          duration: const Duration(minutes: 25),
        ),
        state: ActiveActivityTimerSessionState.running,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            restoredSession: session,
            activityProgressService: LocalActivityProgressService(),
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      await tester.pump(const Duration(milliseconds: 1100));

      expect(tester.widget<RoadView>(find.byType(RoadView)).vehicleProgress, 1);
      expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('arrivalActionPanel')),
          matching: find.text('도착했어요!'),
        ),
        findsOneWidget,
      );
      expect(find.text('오토바이가 도착했어. 미션을 마쳤어?'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ResultScreen), findsNothing);

      await tester.tap(find.byKey(const ValueKey('arrivalPrimaryButton')));
      await tester.pump();
      await tester.pump();

      final resultScreen = tester.widget<ResultScreen>(
        find.byType(ResultScreen),
      );
      expect(resultScreen.result.actualDuration, const Duration(minutes: 25));
      expect(
        resultScreen.result.endedAt,
        startedAt.add(const Duration(minutes: 25)),
      );
      expect(
        resultScreen.result.completionStatus,
        ActivityCompletionStatus.completedAtEnd,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

    },
  );

  testWidgets('TimerScreen resumes ticking from a restored paused session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    var now = DateTime(2026, 6, 10, 8, 30);
    final session = ActiveActivityTimerSession(
      sessionId: 'paused-session',
      startedAt: DateTime(2026, 6, 10, 8),
      config: ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(minutes: 30),
      ),
      state: ActiveActivityTimerSessionState.paused,
      pausedAt: DateTime(2026, 6, 10, 8, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: session,
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      closeTo(1 / 3, 0.01),
    );

    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();

    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 40));

    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      closeTo(0.4, 0.01),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('TimerScreen refreshes elapsed time when app resumes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    var now = DateTime(2026, 6, 10, 8);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 25),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(tester.widget<RoadView>(find.byType(RoadView)).progress, 0);

    now = now.add(const Duration(minutes: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      closeTo(0.4, 0.01),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Activity done before arrival does not immediately push result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
    expect(
      tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete,
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Fast finish drive animates display progress to finish', (
    tester,
  ) async {
    await _pumpRunningTimerAtProgress(
      tester,
      progress: 0.5,
      timerAudioService: _FakeTimerAudioService(),
    );
    await _completeTimerFromControl(tester);

    final driveDuration = finishDriveDurationForProgress(0.5);
    await tester.pump(driveDuration - const Duration(milliseconds: 1));

    expect(find.byType(ResultScreen), findsNothing);
    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      greaterThan(0.99),
    );

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    expect(find.byType(ResultScreen), findsNothing);
    expect(tester.widget<RoadView>(find.byType(RoadView)).progress, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen skips finish-drive SFX under threshold', (
    tester,
  ) async {
    final timerAudioService = _FakeTimerAudioService();

    await _pumpRunningTimerAtProgress(
      tester,
      progress: 0.9,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await _completeTimerFromControl(tester);

    expect(timerAudioService.calls, isNot(contains('playFinishDriveShortSfx')));
    expect(timerAudioService.calls, isNot(contains('playFinishDriveLongSfx')));

    await tester.pump(finishDriveDurationForProgress(0.9));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(timerAudioService.calls, [
      'stopBgm',
      'stopFinishDriveSfx',
      'playFinishArrivalSfx',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen plays short finish-drive SFX by threshold', (
    tester,
  ) async {
    final timerAudioService = _FakeTimerAudioService();

    await _pumpRunningTimerAtProgress(
      tester,
      progress: 0.6,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await _completeTimerFromControl(tester);

    expect(timerAudioService.calls, [
      'stopBgm',
      'playFinishDriveShortSfx',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen plays long finish-drive SFX by threshold', (
    tester,
  ) async {
    final timerAudioService = _FakeTimerAudioService();

    await _pumpRunningTimerAtProgress(
      tester,
      progress: 0.1,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await _completeTimerFromControl(tester);

    expect(timerAudioService.calls, [
      'stopBgm',
      'playFinishDriveLongSfx',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen suppresses finish audio when sound is disabled', (
    tester,
  ) async {
    final timerAudioService = _FakeTimerAudioService();

    await _pumpRunningTimerAtProgress(
      tester,
      progress: 0.1,
      timerAudioService: timerAudioService,
      soundEnabled: false,
    );
    timerAudioService.calls.clear();
    await _completeTimerFromControl(tester);

    expect(timerAudioService.calls, isEmpty);
    await tester.pump(finishDriveDurationForProgress(0.1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(timerAudioService.calls, ['stopFinishDriveSfx']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen stops finish-drive SFX on lifecycle pause', (
    tester,
  ) async {
    final timerAudioService = _FakeTimerAudioService();

    await _pumpRunningTimerAtProgress(
      tester,
      progress: 0.1,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await _completeTimerFromControl(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(timerAudioService.calls, [
      'stopBgm',
      'playFinishDriveLongSfx',
      'stopFinishDriveSfx',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Controls are disabled during fast finish drive', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    final controls = tester.widget<TimerControlBar>(
      find.byType(TimerControlBar),
    );
    expect(controls.onPauseResume, isNull);
    expect(controls.onComplete, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Completing after arrival opens result without fast finish', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final startedAt = DateTime(2026);
    final now = startedAt.add(const Duration(seconds: 2));
    final session = ActiveActivityTimerSession(
      sessionId: 'arrived-completion-session',
      startedAt: startedAt,
      config: ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(seconds: 1),
      ),
      state: ActiveActivityTimerSessionState.running,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 1),
          ),
          restoredSession: session,
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('arrivalPrimaryButton')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Live arrival waits for route acknowledgement before completion dialog',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final startedAt = DateTime(2026);
      var now = startedAt;
      final session = ActiveActivityTimerSession(
        sessionId: 'running-session',
        startedAt: startedAt,
        config: ActivityTimerConfig.defaults().copyWith(
          duration: const Duration(seconds: 1),
        ),
        state: ActiveActivityTimerSessionState.running,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(seconds: 1),
            ),
            restoredSession: session,
            activityProgressService: LocalActivityProgressService(),
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);
      expect(find.text('오토바이가 도착했어. 미션을 마쳤어?'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ResultScreen), findsNothing);
      expect(find.byType(TimerControlBar), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

    },
  );

  testWidgets(
    'Time-ended activity opens result after arrival acknowledgement',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

      final startedAt = DateTime(2026);
      final now = startedAt.add(const Duration(seconds: 2));
      final service = LocalActivityProgressService();
      final session = ActiveActivityTimerSession(
        sessionId: 'play-session',
        startedAt: startedAt,
        config: ActivityTimerConfig.defaults().copyWith(
          activityId: ActivityCatalog.play.id,
          duration: const Duration(seconds: 1),
        ),
        state: ActiveActivityTimerSessionState.running,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              activityId: ActivityCatalog.play.id,
              duration: const Duration(seconds: 1),
            ),
            restoredSession: session,
            activityProgressService: service,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();

      expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);
      expect(find.text('오토바이가 도착했어.'), findsOneWidget);
      expect(find.byType(ResultScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byKey(const ValueKey('arrivalPrimaryButton')));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester
            .widget<ResultScreen>(find.byType(ResultScreen))
            .result
            .completionStatus,
        ActivityCompletionStatus.timeEnded,
      );
      expect(
        tester
            .widget<ResultScreen>(find.byType(ResultScreen))
            .result
            .actualDuration,
        const Duration(seconds: 1),
      );
      expect(
        find.byKey(const ValueKey('resultSkipStickerButton')),
        findsOneWidget,
      );
      expect((await service.loadSnapshot()).history, isEmpty);

      await tester.tap(find.byKey(const ValueKey('resultSkipStickerButton')));
      await tester.pumpAndSettle();

      final snapshot = await service.loadSnapshot();
      expect(
        snapshot.history.single.completionStatus,
        ActivityCompletionStatus.timeEnded,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

    },
  );

  testWidgets('Timer records directly selected markers on completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    final startedAt = DateTime(2026);
    final now = startedAt.add(const Duration(seconds: 2));
    final service = LocalActivityProgressService();
    final config = ActivityTimerConfig.defaults().copyWith(
      duration: const Duration(seconds: 1),
      markerMode: ActivityMarkerMode.manual,
      markerIds: const ['top_teeth', 'bottom_teeth'],
      selectedMarkerIds: const ['top_teeth', 'bottom_teeth'],
    );
    final session = ActiveActivityTimerSession(
      sessionId: 'marker-session',
      startedAt: startedAt,
      config: config,
      state: ActiveActivityTimerSessionState.running,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: config,
          restoredSession: session,
          activityProgressService: service,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('arrivalPrimaryButton')));
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widget<ResultScreen>(find.byType(ResultScreen))
          .result
          .selectedMarkerIds,
      ['top_teeth', 'bottom_teeth'],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Timer hands orientation control to result screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2026);
    final orientationService = _FakeOrientationService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 1),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
          orientationService: orientationService,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(orientationService.calls, [
      'allowTimerOrientations',
      'allowTimerOrientations',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(orientationService.calls, [
      'allowTimerOrientations',
      'allowTimerOrientations',
      'lockPortrait',
    ]);
  });

  testWidgets('Timer screen plays motivation voice after video starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final motivationAudioService = _FakeMotivationAudioService();
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 100),
            soundEnabled: true,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationAudioService: motivationAudioService,
          motivationMediaAvailable: true,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsOneWidget,
    );
    expect(motivationAudioService.playedAssets, isEmpty);

    await tester.pump(motivationVoiceStartDelay);

    expect(motivationAudioService.playedAssets, hasLength(1));
    expect(
      motivationAudioService.playedAssets.single,
      startsWith('assets/audio/motivation/ko_'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Timer screen uses three-minute motivation cadence for long timer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }


      now = now.add(const Duration(minutes: 2, seconds: 59));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

    },
  );

  testWidgets(
    'Timer screen custom motivation interval ignores percent milestones',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 15),
              soundEnabled: false,
              motivationVideoUseCustomInterval: true,
              motivationVideoInterval: const Duration(minutes: 5),
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }


      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsNothing,
      );

      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

    },
  );

  testWidgets('Timer screen closes active motivation video when disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
            soundEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationMediaAvailable: true,
          now: () => now,
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_3')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('timerMotivationVideoHelpButton')),
      findsOneWidget,
    );

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        )
        .onChanged!(false);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('motivationSettingsApplyButton')),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('motivationVideoBubble_3')), findsNothing);
    expect(changedConfig?.motivationVideoEnabled, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Timer motivation settings dismiss keeps pending changes unapplied',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ActivityTimerConfig? changedConfig;
      var now = DateTime(2026);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (config) => changedConfig = config,
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }


      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
          )
          .onChanged!(false);
      await tester.pump();
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('motivationSettingsCancelButton')),
          )
          .onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(changedConfig, isNull);
      expect(
        find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

    },
  );

  testWidgets(
    'Timer screen restarts custom motivation interval from change time',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }


      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
          )
          .onChanged!(true);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('motivationSettingsApplyButton')),
      );
      await tester.pump();

      now = now.add(const Duration(minutes: 2, seconds: 59));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsNothing,
      );

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

    },
  );

  testWidgets('Timer screen skips motivation videos when disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
            soundEnabled: false,
            motivationVideoEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationMediaAvailable: true,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('motivationVideoBubble_3')), findsNothing);
    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Timer screen hides portrait motivation entry point when unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byKey(const ValueKey('motivationSettingsButton')), findsNothing);
    expect(find.byIcon(Icons.video_settings_rounded), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Timer screen hides landscape motivation entry point when unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('timerSoundToggleButton')), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('motivationSettingsButton')), findsNothing);
    expect(find.byIcon(Icons.video_settings_rounded), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Timer screen hides compact landscape motivation entry point when unavailable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(852, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.byKey(const ValueKey('compactLandscapeControls')), findsOneWidget);
      expect(find.byKey(const ValueKey('timerSoundToggleButton')), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byKey(const ValueKey('motivationSettingsButton')), findsNothing);
      expect(find.byIcon(Icons.video_settings_rounded), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets(
    'Timer screen blocks motivation cue and audio when unavailable',
    (tester) async {
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
      final motivationAudioService = _FakeMotivationAudioService();
      final store = ActiveActivityTimerSessionStore();
      var now = DateTime(2026);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(seconds: 100),
              soundEnabled: true,
              motivationVideoEnabled: true,
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationAudioService: motivationAudioService,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      now = now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(motivationVoiceStartDelay);

      expect(find.byKey(const ValueKey('motivationVideoBubble_10')), findsNothing);
      expect(motivationAudioService.playedAssets, isEmpty);
      final session = await store.load();
      expect(session, isNotNull);
      expect(session!.config.motivationVideoEnabled, isTrue);
      expect(session.shownMotivationMilestones, isEmpty);
      expect(session.lastMotivationVideoShownAt, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets(
    'Timer screen blocks restored motivation-enabled session when unavailable',
    (tester) async {
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
      final motivationAudioService = _FakeMotivationAudioService();
      final store = ActiveActivityTimerSessionStore();
      final startedAt = DateTime(2026);
      final now = startedAt.add(const Duration(seconds: 10));
      final session = ActiveActivityTimerSession(
        sessionId: 'motivation-enabled-session',
        startedAt: startedAt,
        config: ActivityTimerConfig.defaults().copyWith(
          duration: const Duration(seconds: 100),
          soundEnabled: true,
          motivationVideoEnabled: true,
        ),
        state: ActiveActivityTimerSessionState.running,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            restoredSession: session,
            activityProgressService: LocalActivityProgressService(),
            motivationAudioService: motivationAudioService,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pump(motivationVoiceStartDelay);

      expect(find.byKey(const ValueKey('motivationVideoBubble_10')), findsNothing);
      expect(motivationAudioService.playedAssets, isEmpty);
      final savedSession = await store.load();
      expect(savedSession, isNotNull);
      expect(savedSession!.config.motivationVideoEnabled, isTrue);
      expect(savedSession.shownMotivationMilestones, isEmpty);
      expect(savedSession.lastMotivationVideoShownAt, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets('Timer screen keeps vehicle fixed when paused', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    now = now.add(const Duration(minutes: 20));
    await tester.pump(const Duration(milliseconds: 250));

    Offset vehicleCenterInRoad() {
      final roadRect = tester.getRect(find.byType(RoadView));
      final vehicleCenter = tester.getCenter(find.byType(VehicleWidget));
      return vehicleCenter - roadRect.topLeft;
    }

    final centerBeforePause = vehicleCenterInRoad();
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    final centerAfterPause = vehicleCenterInRoad();

    now = now.add(const Duration(minutes: 10));
    await tester.pump(const Duration(seconds: 1));
    final centerAfterPausedTime = vehicleCenterInRoad();

    expect(centerAfterPause.dx, closeTo(centerBeforePause.dx, 0.1));
    expect(centerAfterPause.dy, closeTo(centerBeforePause.dy, 0.1));
    expect(centerAfterPausedTime.dx, closeTo(centerBeforePause.dx, 0.1));
    expect(centerAfterPausedTime.dy, closeTo(centerBeforePause.dy, 0.1));

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Timer screen gives the route primary space in landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 5),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final roadSize = tester.getSize(find.byType(RoadView));
    expect(roadSize, const Size(1200, 520));
    expect(roadSize.width, greaterThan(760));
    expect(roadSize.height, greaterThan(460));
    expect(roadSize.height, lessThanOrEqualTo(560));
    final roadRect = tester.getRect(find.byType(RoadView));
    expect(
      roadRect.contains(tester.getCenter(find.byIcon(Icons.home_rounded))),
      isTrue,
    );
    expect(
      roadRect.contains(tester.getCenter(find.byType(GoalStarPulse))),
      isTrue,
    );
    expect(
      roadRect.contains(tester.getCenter(find.byType(VehicleWidget))),
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byType(RoadView),
        matching: find.byType(VehicleWidget),
      ),
      findsNothing,
    );
    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('remainingTimeBadge'))).width,
      360,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('remainingTimeBadge'))).height,
      lessThanOrEqualTo(
        tester
            .getSize(find.byKey(const ValueKey('timerProgressMessageCard')))
            .height,
      ),
    );
    final roadBounds = createRoadBounds(const Size(1200, 520));
    final expectedRoadRight =
        roadRect.left + (roadRect.width * roadBounds.right / 1200);
    final expectedRoadLeft =
        roadRect.left + (roadRect.width * roadBounds.left / 1200);
    expect(
      tester.getRect(find.byKey(const ValueKey('remainingTimeBadge'))).right,
      closeTo(expectedRoadRight, 1),
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('timerProgressMessageCard')))
          .left,
      greaterThanOrEqualTo(expectedRoadLeft),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('timerProgressIndicator')))
          .width,
      greaterThan(250),
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('timerProgressMessageCard')))
          .right,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const ValueKey('remainingTimeBadge'))).left,
      ),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('timerSoundToggleButton')), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(
      tester.widget<TimerControlBar>(find.byType(TimerControlBar)).isVertical,
      isFalse,
    );

    tester.view.physicalSize = const Size(900, 500);
    await tester.pump();

    expect(tester.getSize(find.byType(RoadView)), roadSize);
  });

  testWidgets('Timer screen keeps long landscape course viewport fixed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(tester.getSize(find.byType(RoadView)), const Size(1200, 520));
    expect(
      tester.widget<RoadView>(find.byType(RoadView)).courseDuration,
      const Duration(minutes: 60),
    );
    expect(
      tester
          .widget<RoadVehicleLayer>(find.byType(RoadVehicleLayer))
          .courseDuration,
      const Duration(minutes: 60),
    );
    expect(
      tester
          .getRect(find.byType(RoadView))
          .contains(tester.getCenter(find.byType(VehicleWidget))),
      isTrue,
    );
  });

  testWidgets(
    'Timer screen places controls inside compact landscape course action slot',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(852, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            onConfigChanged: (_) {},
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }


      final roadRect = tester.getRect(find.byType(RoadView));
      final controlsRect = tester.getRect(
        find.byKey(const ValueKey('compactLandscapeControls')),
      );
      final soundRect = tester.getRect(
        find.byKey(const ValueKey('timerSoundToggleButton')),
      );
      final settingsRect = tester.getRect(
        find.byKey(const ValueKey('motivationSettingsButton')),
      );
      final pauseRect = tester.getRect(find.byIcon(Icons.pause_rounded));
      final roadBounds = createRoadBounds(const Size(1200, 520));
      final expectedRoadRight =
          roadRect.left + (roadRect.width * roadBounds.right / 1200);

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(TimerControlBar), findsNothing);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.video_settings_rounded), findsOneWidget);
      expect(roadRect.width, greaterThan(760));
      expect(roadRect.height, greaterThan(320));
      expect(controlsRect.left, greaterThanOrEqualTo(expectedRoadRight));
      expect(controlsRect.right, lessThanOrEqualTo(roadRect.right));
      expect(controlsRect.width, lessThanOrEqualTo(72));
      expect(controlsRect.height, lessThanOrEqualTo(280));
      expect(controlsRect.contains(soundRect.center), isTrue);
      expect(controlsRect.contains(settingsRect.center), isTrue);
      expect(controlsRect.contains(pauseRect.center), isTrue);
      expect(soundRect.bottom, lessThanOrEqualTo(settingsRect.top));
      expect(settingsRect.bottom, lessThanOrEqualTo(pauseRect.top));
      expect(
        controlsRect.right,
        lessThanOrEqualTo(tester.view.physicalSize.width),
      );
      expect(
        controlsRect.bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
    },
  );

  testWidgets('Timer motivation settings sheet scrolls in compact landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            motivationVideoUseCustomInterval: true,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationMediaAvailable: true,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motivationSettingsApplyButton')),
      findsOneWidget,
    );
  });

  testWidgets('Timer screen allows landscape only while mounted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final orientationService = _FakeOrientationService();

    await tester.pumpWidget(
      MaterialApp(
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          orientationService: orientationService,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(orientationService.calls, ['allowTimerOrientations']);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(orientationService.calls, [
      'allowTimerOrientations',
      'lockPortrait',
    ]);
  });

  testWidgets('Timer screen keeps screen awake only when setting is enabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final screenAwakeService = _FakeScreenAwakeService();

    await tester.pumpWidget(
      MaterialApp(
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            keepScreenAwake: true,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          screenAwakeService: screenAwakeService,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(screenAwakeService.enabledValues, [true]);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(screenAwakeService.enabledValues, [true, false]);
  });

  testWidgets(
    'Timer screen leaves wakelock untouched when setting is disabled',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final screenAwakeService = _FakeScreenAwakeService();

      await tester.pumpWidget(
        MaterialApp(
          home: TimerScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              keepScreenAwake: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
            screenAwakeService: screenAwakeService,
          ),
        ),
      );
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }


      expect(screenAwakeService.enabledValues, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }


      expect(screenAwakeService.enabledValues, isEmpty);
    },
  );

  testWidgets('Timer screen asks before leaving with the back button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const Scaffold(body: Center(child: Text('타이머 열기'))),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('오늘의 미션'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('코스를 그만할까요?'), findsOneWidget);
    expect(find.text('지금 나가면 진행 중인 미션이 저장되지 않아요.'), findsOneWidget);

    await tester.tap(find.text('계속하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('코스를 그만할까요?'), findsNothing);
    expect(find.text('오늘의 미션'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.tap(find.text('그만하기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('타이머 열기'), findsOneWidget);
    expect(find.text('오늘의 미션'), findsNothing);
  });

  testWidgets('Timer exit waits for active session clear before returning home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final startedAt = DateTime(2026, 6, 10, 8);
    final store = _DelayedClearActiveSessionStore(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: startedAt,
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 35),
          soundEnabled: false,
        ),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          activeSessionStore: store,
          onConfigChanged: (_) {},
          now: () => startedAt,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);

    await tester.tap(find.text('이어가기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TimerScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.tap(find.text('그만하기'));
    await tester.pump();

    expect(store.clearStarted, isTrue);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(store.currentSession, isNotNull);

    store.completeClear();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TimerScreen), findsNothing);
    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsNothing);
    expect(store.currentSession, isNull);
  });

  testWidgets('English locale shows English home copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await _startApp(tester, const Locale('en'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.text("Today's vehicle"), findsOneWidget);
    expect(find.text('Create Timer'), findsWidgets);
    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);

    await _openTimerBuilder(tester);

    expect(find.text('Brush Teeth'), findsWidgets);
    expect(find.text('Reading'), findsWidgets);
    expect(find.text('Cleanup'), findsOneWidget);
    expect(find.text('Play Time'), findsWidgets);
    expect(find.text('Meal'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('2 min'), findsOneWidget);

    await _selectTimerBuilderActivity(tester, 'reading');

    expect(find.text('15 min'), findsOneWidget);
  });

  testWidgets('English locale shows English timer progress copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.text("We're off!"), findsOneWidget);
    expect(find.text('Time left'), findsOneWidget);
    expect(find.text('출발했어요!'), findsNothing);
  });

  testWidgets('Paused timer shows paused status copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.ensureVisible(find.text('Pause'));
    await tester.pump();
    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Taking a little break'), findsOneWidget);
    expect(find.text('Taking a break'), findsOneWidget);
  });

  testWidgets('Unsupported locale falls back to English', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await _startApp(tester, const Locale('fr'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.textContaining('Create Timer'), findsWidgets);
  });


  testWidgets('Home screen shows reward goal CTA', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(childName: 'Jiyul'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Create Reward Goal'), findsOneWidget);
  });

  testWidgets('Home activity history summary opens activity history screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    await _recordActivityResult(
      service,
      _activityResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(childName: 'Jiyul'),
          activityProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Recent activity 20:00 · Completed'), findsOneWidget);

    await tester.tap(find.text("Jiyul's activity history"));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityHistoryScreen), findsOneWidget);
    expect(find.text('Activity Records'), findsOneWidget);
  });

  testWidgets('Home activity history summary shows incomplete status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    await _recordActivityResult(
      service,
      _activityResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        activityCompleted: false,
        completionStatus: ActivityCompletionStatus.needsMoreTime,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(childName: '강우'),
          activityProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(
      find.text('최근 기록 20:00 · 조금 더 필요 · 차량 스티커 받지 않음 · 초과 +05:00'),
      findsOneWidget,
    );
  });

  testWidgets('Reward goal creation form saves a goal', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: RewardGoalScreen(activityProgressService: service),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await tester.tap(find.widgetWithText(ChoiceChip, '7'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ice cream');
    await tester.pump();
    await tester.tap(find.text('Save Goal'));
    await tester.pumpAndSettle();

    final snapshot = await service.loadSnapshot();
    expect(snapshot.activeRewardGoals.single.rewardText, 'ice cream');
    expect(snapshot.activeRewardGoals.single.requiredStickerCount, 7);
  });

  testWidgets('Earned reward use flow asks for confirmation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 1,
      rewardText: 'ice cream',
    );
    await _recordActivityResult(service, _activityResult());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: RewardGoalScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mark Used'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Used'));
    await tester.pumpAndSettle();
    expect(find.text('Mark this reward as used?'), findsOneWidget);

    await tester.tap(find.text('Keep Goal'));
    await tester.pumpAndSettle();
    expect((await service.loadSnapshot()).earnedRewardGoals, hasLength(1));

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mark Used'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Used'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Used').last);
    await tester.pumpAndSettle();

    final snapshot = await service.loadSnapshot();
    expect(snapshot.earnedRewardGoals, isEmpty);
    expect(snapshot.usedRewardGoals, hasLength(1));
  });

  testWidgets('Activity history screen shows empty state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(
          activityProgressService: LocalActivityProgressService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('활동 기록'), findsOneWidget);
    expect(find.text('아직 저장된 활동 기록이 없어.'), findsOneWidget);
    expect(find.text('미션 타이머를 마치면 기록이 여기에 쌓여요.'), findsOneWidget);
  });

  testWidgets('Activity history screen lists saved activity records', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    await _recordActivityResult(
      service,
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeEnd: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('양치'), findsOneWidget);
    expect(find.text('🪥'), findsOneWidget);
    expect(find.textContaining('12:25'), findsOneWidget);
    expect(find.text('목표'), findsOneWidget);
    expect(find.text('20:00'), findsNWidgets(2));
    expect(find.text('실제'), findsOneWidget);
    expect(find.text('25:00'), findsNothing);
    expect(find.text('초과 +05:00'), findsNothing);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('받은 차량 스티커'), findsOneWidget);
    expect(find.text('고른 마커'), findsNothing);
  });

  testWidgets('Activity history screen deletes a record after confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('12:25'), findsOneWidget);

    await tester.tap(
      find.byKey(
        ValueKey('deleteActivityHistoryEntry-${recordedSession.entry.id}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이 활동 기록을 삭제할까요?'), findsOneWidget);
    expect(find.text('기록만 삭제되고 받은 차량 스티커는 유지돼요.'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('활동 기록을 삭제했어요.'), findsOneWidget);
    expect(find.textContaining('12:25'), findsNothing);
    expect(find.text('아직 저장된 활동 기록이 없어.'), findsOneWidget);
    expect((await service.loadSnapshot()).history, isEmpty);
  });

  testWidgets('Activity history delete dialog can be canceled', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey('deleteActivityHistoryEntry-${recordedSession.entry.id}'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.textContaining('12:25'), findsOneWidget);
    expect((await service.loadSnapshot()).history, hasLength(1));
  });

  testWidgets('Activity history screen shows directly selected markers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    await _recordActivityResult(
      service,
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 20),
        selectedMarkerIds: const ['top_teeth', 'bottom_teeth'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('activityHistoryHelpCard')),
      findsOneWidget,
    );
    expect(find.text('활동 기록 안내'), findsOneWidget);
    expect(find.text('고른 마커'), findsOneWidget);
    expect(find.text('위쪽 반짝'), findsNothing);
    expect(find.text('아래쪽 반짝'), findsNothing);
    expect(find.text('😁'), findsOneWidget);
    expect(find.text('🫧'), findsOneWidget);
  });

  testWidgets('Activity history screen shows needs-more-time records', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'savedActivityTimerPresetsInitialized': true});
    final service = LocalActivityProgressService();
    await _recordActivityResult(
      service,
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        activityCompleted: false,
        completionStatus: ActivityCompletionStatus.needsMoreTime,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('조금 더 필요'), findsOneWidget);
    expect(find.text('차량 스티커 받지 않음'), findsOneWidget);
    expect(find.text('초과 +05:00'), findsOneWidget);
  });
}

ActivitySessionResult _activityResult({
  String activityId = 'brushing',
  DateTime? startedAt,
  DateTime? endedAt,
  Duration targetDuration = const Duration(minutes: 20),
  Duration actualDuration = const Duration(minutes: 25),
  bool completedBeforeEnd = false,
  bool activityCompleted = true,
  ActivityCompletionStatus? completionStatus,
  List<String> selectedMarkerIds = const [],
  bool includeStickerDecision = true,
  bool? receiveSticker,
}) {
  final resolvedStartedAt = startedAt ?? DateTime(2026, 5, 4, 12);
  final resolvedEndedAt = endedAt ?? resolvedStartedAt.add(actualDuration);
  final resolvedCompletionStatus =
      completionStatus ??
      (activityCompleted
          ? (completedBeforeEnd
                ? ActivityCompletionStatus.completedBeforeEnd
                : ActivityCompletionStatus.completedAfterEnd)
          : ActivityCompletionStatus.needsMoreTime);

  return ActivitySessionResult(
    activityId: activityId,
    startedAt: resolvedStartedAt,
    endedAt: resolvedEndedAt,
    targetDuration: targetDuration,
    actualDuration: actualDuration,
    completedBeforeEnd: completedBeforeEnd,
    completionStatus: resolvedCompletionStatus,
    selectedMarkerIds: selectedMarkerIds,
    receiveSticker: includeStickerDecision
        ? receiveSticker ??
              (ActivityCatalog.findById(activityId).rewardEnabledByDefault &&
                  activityCompletionStatusCanReceiveSticker(
                    resolvedCompletionStatus,
                  ))
        : null,
  );
}

Future<RecordedActivitySession> _recordActivityResult(
  LocalActivityProgressService service,
  ActivitySessionResult result, {
  String vehicleId = 'motorcycle',
}) {
  return service.recordActivityResult(result, vehicleId: vehicleId);
}

Future<void> _pumpOpenResultStickerAlbumSheet(WidgetTester tester) async {
  final inventory = [
    RewardInventoryItem(
      rewardId: RewardCatalog.vehicleStickerIdForVehicle('motorcycle'),
      acquiredAt: DateTime(2026),
      count: 2,
    ),
  ];

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: AppTexts.supportedLocales,
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () {
              showResultStickerAlbumSheet(context, inventory: inventory);
            },
            child: const Text('openAlbum'),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('openAlbum'));
  await tester.pumpAndSettle();
}


Future<void> _startApp(
  WidgetTester tester,
  Locale locale, {
  bool completeOnboarding = true,
  bool completeChildNameSetup = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  tester.binding.platformDispatcher.localeTestValue = locale;
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await app.main();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
  if (completeOnboarding &&
      find
          .byKey(const ValueKey('onboardingSkipButton'))
          .evaluate()
          .isNotEmpty) {
    await tester.tap(find.byKey(const ValueKey('onboardingSkipButton')));
    await tester.pumpAndSettle();
  }
  if (!completeChildNameSetup || find.byType(TextField).evaluate().isEmpty) {
    return;
  }

  await tester.enterText(find.byType(TextField), '지율');
  await tester.pump();
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

Future<void> _openTimerBuilder(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('createTimerButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _selectTimerBuilderActivity(
  WidgetTester tester,
  String activityId,
) async {
  tester
      .widget<ChoiceChip>(
        find.byKey(ValueKey('timerBuilderActivity_$activityId')),
      )
      .onSelected!(true);
  await tester.pump();
}

Future<void> _startTimerBuilder(WidgetTester tester) async {
  tester
      .widget<AppBouncyButton>(
        find.byKey(const ValueKey('timerBuilderStartButton')),
      )
      .onPressed!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpPurchaseControllerUnlock(
  VehiclePackPurchaseController controller,
) async {
  if (controller.state.vehiclePackUnlocked) {
    return;
  }

  final completer = Completer<void>();
  void listener() {
    if (controller.state.vehiclePackUnlocked && !completer.isCompleted) {
      completer.complete();
    }
  }

  controller.addListener(listener);
  try {
    await completer.future.timeout(const Duration(seconds: 1));
  } finally {
    controller.removeListener(listener);
  }
}

Future<void> _pumpRunningTimerAtProgress(
  WidgetTester tester, {
  required double progress,
  required _FakeTimerAudioService timerAudioService,
  bool soundEnabled = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'savedActivityTimerPresetsInitialized': true,
  });
  final startedAt = DateTime(2026);
  final duration = const Duration(seconds: 100);
  final config = ActivityTimerConfig.defaults().copyWith(
    duration: duration,
    soundEnabled: soundEnabled,
  );
  final now = startedAt.add(
    Duration(milliseconds: (duration.inMilliseconds * progress).round()),
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      home: TimerScreen(
        config: config,
        restoredSession: ActiveActivityTimerSession(
          sessionId: 'finish-audio-session-$progress-$soundEnabled',
          startedAt: startedAt,
          config: config,
          state: ActiveActivityTimerSessionState.running,
        ),
        activityProgressService: LocalActivityProgressService(),
        timerAudioService: timerAudioService,
        now: () => now,
        onConfigChanged: (_) {},
      ),
    ),
  );
  await tester.pump();
}

Future<void> _completeTimerFromControl(WidgetTester tester) async {
  tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
  await tester.pump();
  await tester.tap(find.byType(FilledButton).last);
  await tester.pump();
}

File _createTemporaryAvatarImage() {
  final temporaryDirectory = Directory.systemTemp.createTempSync(
    'road_avatar_test_',
  );
  final avatarFile = File('${temporaryDirectory.path}/avatar.png');
  avatarFile.writeAsBytesSync(_transparentPngBytes);
  addTearDown(() {
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });
  return avatarFile;
}

final _transparentPngBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Material _vehicleChoiceMaterial(WidgetTester tester, String vehicleId) {
  return tester.widget<Material>(_vehicleChoiceFinder(vehicleId));
}

Finder _vehicleChoiceFinder(String vehicleId) {
  return find.byKey(ValueKey('vehicleChoice.$vehicleId'));
}

Finder _assetImage(String assetName) {
  return find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName;
  });
}


class _FakeScreenAwakeService implements ScreenAwakeService {
  final List<bool> enabledValues = [];

  @override
  Future<void> setEnabled(bool enabled) async {
    enabledValues.add(enabled);
  }
}

class _FakeOrientationService implements OrientationService {
  final List<String> calls = [];

  @override
  Future<void> lockPortrait() async {
    calls.add('lockPortrait');
  }

  @override
  Future<void> allowTimerOrientations() async {
    calls.add('allowTimerOrientations');
  }
}

class _FakeMotivationAudioService implements MotivationAudioService {
  final List<String> playedAssets = [];
  var stopCount = 0;
  var disposeCount = 0;

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

class _FakeTimerAudioService implements TimerAudioService {
  final List<String> calls = [];

  @override
  Future<void> startOrResumeBgm() async {
    calls.add('startOrResumeBgm');
  }

  @override
  Future<void> pauseBgm() async {
    calls.add('pauseBgm');
  }

  @override
  Future<void> stopBgm() async {
    calls.add('stopBgm');
  }

  @override
  Future<void> playMarkerSfx() async {
    calls.add('playMarkerSfx');
  }

  @override
  Future<void> playCourseLoading() async {
    calls.add('playCourseLoading');
  }

  @override
  Future<void> stopCourseLoading() async {
    calls.add('stopCourseLoading');
  }

  @override
  Future<void> playReadyStartBeep() async {
    calls.add('playReadyStartBeep');
  }

  @override
  Future<void> stopReadyStartBeep() async {
    calls.add('stopReadyStartBeep');
  }

  @override
  Future<void> playFinishDriveShortSfx() async {
    calls.add('playFinishDriveShortSfx');
  }

  @override
  Future<void> playFinishDriveLongSfx() async {
    calls.add('playFinishDriveLongSfx');
  }

  @override
  Future<void> stopFinishDriveSfx() async {
    calls.add('stopFinishDriveSfx');
  }

  @override
  Future<void> playFinishArrivalSfx() async {
    calls.add('playFinishArrivalSfx');
  }

  @override
  Future<void> stopAll() async {
    calls.add('stopAll');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }
}


class _DelayedClearActiveSessionStore extends ActiveActivityTimerSessionStore {
  _DelayedClearActiveSessionStore(this.currentSession);

  ActiveActivityTimerSession? currentSession;
  Completer<void>? _clearCompleter;

  bool get clearStarted => _clearCompleter != null;

  @override
  Future<void> save(ActiveActivityTimerSession session) async {
    currentSession = session;
  }

  @override
  Future<ActiveActivityTimerSession?> load() async {
    return currentSession;
  }

  @override
  Future<void> clear() async {
    _clearCompleter ??= Completer<void>();
    await _clearCompleter!.future;
    currentSession = null;
  }

  void completeClear() {
    final completer = _clearCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}

class _FakePurchaseEntitlementStore implements PurchaseEntitlementStore {
  _FakePurchaseEntitlementStore([
    this.entitlement = const PurchaseEntitlement.locked(),
  ]);

  PurchaseEntitlement entitlement;

  @override
  Future<PurchaseEntitlement> load() async {
    return entitlement;
  }

  @override
  Future<void> save(PurchaseEntitlement entitlement) async {
    this.entitlement = entitlement;
  }
}

class _FakeIapPurchaseClient implements IapPurchaseClient {
  final _purchaseStreamController =
      StreamController<List<IapPurchaseUpdate>>.broadcast();
  var restoreCallCount = 0;

  @override
  Stream<List<IapPurchaseUpdate>> get purchaseStream {
    return _purchaseStreamController.stream;
  }

  @override
  Future<bool> buyNonConsumable(IapProductDetails product) async {
    return true;
  }

  @override
  Future<void> completePurchase(IapPurchaseUpdate purchase) async {}

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<IapProductQueryResult> queryProducts(Set<String> productIds) async {
    return const IapProductQueryResult(products: []);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCallCount += 1;
  }

  void emitPurchase(IapPurchaseUpdate purchase) {
    _purchaseStreamController.add([purchase]);
  }
}
