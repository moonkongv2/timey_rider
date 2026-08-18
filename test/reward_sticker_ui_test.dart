import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/avatar_prompt_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/reward_item.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/screens/sticker_collection_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/theme/app_colors.dart';
import 'package:timey_rider/theme/app_theme.dart';
import 'package:timey_rider/widgets/reward_sticker_image.dart';
import 'package:timey_rider/widgets/result_sticker_album_sheet.dart';

import 'support/activity_result_test_data.dart';

void main() {
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

    await pumpOpenResultStickerAlbumSheet(tester);

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

    await pumpOpenResultStickerAlbumSheet(tester);

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

    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final service = LocalActivityProgressService();
    await recordActivityResult(
      service,
      activityResult(),
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
}

Future<void> pumpOpenResultStickerAlbumSheet(WidgetTester tester) async {
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
