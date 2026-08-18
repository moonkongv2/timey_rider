import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/catalogs/avatar_prompt_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/main.dart' as app;
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
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/theme/app_colors.dart';
import 'package:timey_rider/theme/app_theme.dart';
import 'package:timey_rider/widgets/reward_sticker_image.dart';
import 'package:timey_rider/widgets/result_sticker_album_sheet.dart';

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
