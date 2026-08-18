import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/catalogs/avatar_prompt_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/main.dart' as app;
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_progress_snapshot.dart';
import 'package:timey_rider/models/activity_session_result.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/reward_item.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/activity_history_screen.dart';
import 'package:timey_rider/screens/reward_goal_screen.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/screens/sticker_collection_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/orientation_service.dart';
import 'package:timey_rider/services/screen_awake_service.dart';
import 'package:timey_rider/theme/app_colors.dart';
import 'package:timey_rider/theme/app_theme.dart';
import 'package:timey_rider/widgets/goal_star_pulse.dart';
import 'package:timey_rider/widgets/road_painter.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/reward_sticker_image.dart';
import 'package:timey_rider/widgets/result_sticker_album_sheet.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';
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
