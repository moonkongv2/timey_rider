import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/reward_item.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/reward_sticker_image.dart';
import 'package:video_player/video_player.dart';

import 'support/activity_result_test_data.dart';
import 'support/result_test_fakes.dart';

void main() {
  testWidgets('Needs-more-time result screen skips the intro video', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final service = LocalActivityProgressService();
    final introVideoPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          result: activityResult(activityCompleted: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: service,
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();

    expect(introVideoPaths, isEmpty);
    expect(find.byKey(const ValueKey('resultIntroScreen')), findsNothing);
    expect(find.text('조금 더 시간이 필요했어'), findsOneWidget);
    expect(find.text('이번 활동에는 시간이 조금 더 필요했어.'), findsOneWidget);
    expect(
      _assetImage('assets/images/result_failed_bg_portrait.webp'),
      findsOneWidget,
    );
    expect(
      _assetImage(failureRiderAssetPathForVehicle(vehicleId: 'motorcycle')),
      findsOneWidget,
    );

    final snapshot = await service.loadSnapshot();
    expect(snapshot.history, hasLength(1));
    expect(snapshot.history.single.activityCompleted, isFalse);
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.needsMoreTime,
    );
  });

  testWidgets('Time-ended result skips reward intro and sticker copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final introVideoPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          result: activityResult(
            completionStatus: ActivityCompletionStatus.timeEnded,
          ),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(introVideoPaths, isEmpty);
    expect(find.text('The planned time is over'), findsOneWidget);
    expect(find.text('The timer reached the finish.'), findsOneWidget);
    expect(find.byType(RewardStickerImage), findsNothing);
    expect(find.textContaining('sticker'), findsNothing);
  });

  testWidgets('Result screen records after the sticker choice', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final service = LocalActivityProgressService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          result: activityResult(includeStickerDecision: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: service,
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.text('이번 활동을 확인했나요?'), findsOneWidget);
    expect(find.text('차량 스티커 받기'), findsOneWidget);
    expect(find.text('이번엔 차량 스티커 받지 않기'), findsOneWidget);
    expect((await service.loadSnapshot()).history, isEmpty);

    await tester.tap(find.byKey(const ValueKey('resultSkipStickerButton')));
    await tester.pumpAndSettle();

    expect(find.text('오늘 활동을 기록했어!'), findsOneWidget);
    expect(find.byType(RewardStickerImage), findsNothing);
    final snapshot = await service.loadSnapshot();
    expect(snapshot.history, hasLength(1));
    expect(snapshot.history.single.activityCompleted, isTrue);
    expect(snapshot.history.single.rewardIds, isEmpty);
    expect(snapshot.inventory, isEmpty);
  });

  testWidgets('Result screen records selected vehicle sticker', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final service = LocalActivityProgressService();
    final expectedStickerId = RewardCatalog.vehicleStickerIdForVehicle(
      VehicleCatalog.fireTruck.id,
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
        home: ResultScreen(
          result: activityResult(includeStickerDecision: false),
          config: ActivityTimerConfig.defaults().copyWith(
            vehicleId: VehicleCatalog.fireTruck.id,
          ),
          activityProgressService: service,
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await tester.tap(find.byKey(const ValueKey('resultGetStickerButton')));
    await tester.pump();

    final snapshot = await service.loadSnapshot();
    expect(snapshot.history.single.rewardIds, [expectedStickerId]);
    expect(snapshot.inventory.single.rewardId, expectedStickerId);
    expect(snapshot.inventory.single.count, 1);
  });
}

Finder _assetImage(String assetName) {
  return find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName;
  });
}
