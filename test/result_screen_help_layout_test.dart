import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/reward_item.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:video_player/video_player.dart';

import 'support/activity_result_test_data.dart';
import 'support/result_test_fakes.dart';

void main() {
  testWidgets('Success result screen uses portrait background after intro', (
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
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('오늘 활동을 기록했어!'), findsOneWidget);
    expect(
      _assetImage('assets/images/result_success_bg_portrait.png'),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(
          ValueKey(
            'resultRewardImage_${RewardCatalog.vehicleStickerIdForVehicle(VehicleCatalog.motorcycle.id)}',
          ),
        ),
      ),
      const Size.square(132),
    );
  });

  testWidgets('Completed result help explains sticker reward', (tester) async {
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
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('부모님 응원 팁'), findsOneWidget);
    expect(find.text('아이에게 이렇게 말해보세요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('completedResultGuardianTipCard')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('completedResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.text('아이에게 이렇게 말해보세요'), findsWidgets);
    expect(find.text('오늘 활동을 같이 해본 게 좋았어.'), findsOneWidget);
    expect(find.text('빨리 해서 잘했어.'), findsOneWidget);
    expect(find.textContaining('차량 스티커 1장'), findsOneWidget);
  });

  testWidgets('Incomplete result help explains record without sticker', (
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
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('부모님 응원 팁'), findsOneWidget);
    expect(find.text('다음 도전을 부드럽게 응원해요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('incompleteResultGuardianTipCard')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('incompleteResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.text('아이에게 이렇게 말해보세요'), findsOneWidget);
    expect(find.textContaining('오늘은 시간이 조금 더 필요했네'), findsOneWidget);
    expect(find.textContaining('미완료는 벌이 아니라 다음 조절을 위한 기록'), findsOneWidget);
    expect(find.text('실패했네.'), findsOneWidget);
  });

  testWidgets('English completed result help shows coaching sections', (
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
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parent tips'), findsOneWidget);
    expect(find.text('Try saying this'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('completedResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(
      find.textContaining(
        "What you check together is saved in today's activity record.",
      ),
      findsOneWidget,
    );
    expect(find.text('Try saying this'), findsWidgets);
    expect(find.text('Try to avoid'), findsOneWidget);
  });

  testWidgets('English incomplete result help frames incomplete as guidance', (
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
          result: activityResult(activityCompleted: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parent tips'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('incompleteResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.textContaining('not a punishment'), findsWidgets);
  });

  testWidgets('Failed result screen uses selected rider image in landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
          config: ActivityTimerConfig.defaults().copyWith(vehicleId: 'bus'),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('compactLandscapeResultCard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('incompleteResultGuardianTipButton')),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '다시 출발'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '홈으로'), findsOneWidget);
    expect(find.text('이번 활동에는 시간이 조금 더 필요했어.'), findsOneWidget);
    expect(
      _assetImage('assets/images/result_failed_bg_landscape.png'),
      findsOneWidget,
    );
    expect(
      _assetImage(failureRiderAssetPathForVehicle(vehicleId: 'bus')),
      findsOneWidget,
    );
  });

  testWidgets('Success result keeps actions visible in compact landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('compactLandscapeResultCard')),
    );
    final restartButton = find.widgetWithText(FilledButton, '다시 출발');
    final homeButton = find.widgetWithText(OutlinedButton, '홈으로');
    final guardianTipButton = find.byKey(
      const ValueKey('completedResultGuardianTipButton'),
    );
    final rewardBox = find.byKey(const ValueKey('compactLandscapeRewardBox'));
    final messageBox = find.byKey(const ValueKey('compactLandscapeMessageBox'));

    expect(find.text('오늘 활동을 기록했어!'), findsOneWidget);
    expect(guardianTipButton, findsOneWidget);
    expect(rewardBox, findsOneWidget);
    expect(messageBox, findsOneWidget);
    expect(
      _assetImage('assets/images/result_success_bg_landscape.png'),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(
          ValueKey(
            'resultRewardImage_${RewardCatalog.vehicleStickerIdForVehicle(VehicleCatalog.motorcycle.id)}',
          ),
        ),
      ),
      const Size.square(160),
    );
    expect(restartButton, findsOneWidget);
    expect(homeButton, findsOneWidget);
    final rewardRect = tester.getRect(rewardBox);
    final messageRect = tester.getRect(messageBox);
    final restartRect = tester.getRect(restartButton);
    final homeRect = tester.getRect(homeButton);
    final tipRect = tester.getRect(guardianTipButton);

    expect(restartRect.left, closeTo(rewardRect.left, 0.1));
    expect(homeRect.right, closeTo(messageRect.right, 0.1));
    expect(
      tester.getSize(restartButton).width,
      closeTo(tester.getSize(homeButton).width, 0.1),
    );
    expect(tipRect.left, closeTo(messageRect.left, 0.1));
    expect(tipRect.right, closeTo(messageRect.right, 0.1));
    expect(cardRect.contains(tester.getCenter(restartButton)), isTrue);
    expect(cardRect.contains(tester.getCenter(homeButton)), isTrue);
    expect(
      tester.getRect(restartButton).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );
    expect(
      tester.getRect(homeButton).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );
  });

  testWidgets('Result screen allows landscape until disposed', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final orientationService = TestOrientationService();

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
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: TestResultAudioService(),
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

  test('Result intro video contains in landscape and covers in portrait', () {
    expect(resultIntroMediaFitForSize(const Size(844, 390)), BoxFit.contain);
    expect(resultIntroMediaFitForSize(const Size(390, 844)), BoxFit.cover);
  });
}

Finder _assetImage(String assetName) {
  return find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName;
  });
}
