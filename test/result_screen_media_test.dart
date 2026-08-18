import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/navigation/app_route_observer.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

import 'support/activity_result_test_data.dart';
import 'package:video_player/video_player.dart';

import 'support/result_test_fakes.dart';

void main() {
  testWidgets('Completed-before-arrival result shows intro video screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.pump();

    expect(introVideoPaths, [
      resultVideoAssetPathForVehicle(vehicleId: 'motorcycle'),
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('ResultScreen plays cheering only after success intro starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final videoPlatform = installTestVideoPlayerPlatform();
    final resultAudioService = TestResultAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        navigatorObservers: [appRouteObserver],
        home: ResultScreen(
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: resultAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(videoPlatform.calls, contains('play'));
    expect(resultAudioService.calls, ['playCrowdCheering']);

    videoPlatform.complete(0);
    await tester.pump();

    expect(resultAudioService.calls, ['playCrowdCheering', 'stop']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ResultScreen suppresses cheering when sound is disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final videoPlatform = installTestVideoPlayerPlatform();
    final resultAudioService = TestResultAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        navigatorObservers: [appRouteObserver],
        home: ResultScreen(
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults().copyWith(soundEnabled: false),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: resultAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(videoPlatform.calls, contains('play'));
    expect(resultAudioService.calls, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ResultScreen stops cheering on app lifecycle pause', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    installTestVideoPlayerPlatform();
    final resultAudioService = TestResultAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        navigatorObservers: [appRouteObserver],
        home: ResultScreen(
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: resultAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(resultAudioService.calls, ['playCrowdCheering', 'stop']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ResultScreen plays sticker collect when awarded sticker lands', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final videoPlatform = installTestVideoPlayerPlatform();
    final resultAudioService = TestResultAudioService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        navigatorObservers: [appRouteObserver],
        home: ResultScreen(
          result: activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          resultAudioService: resultAudioService,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    videoPlatform.complete(0);
    await tester.pumpAndSettle();

    expect(resultAudioService.calls, contains('playStickerCollect'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Completed-after-arrival result also shows intro video screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
          result: activityResult(completedBeforeEnd: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.pump();

    expect(introVideoPaths, [
      resultVideoAssetPathForVehicle(vehicleId: 'motorcycle'),
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });
}
