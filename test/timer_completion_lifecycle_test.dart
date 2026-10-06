import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';

import 'support/timer_test_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    final pending = await const ActiveActivityTimerSessionStore()
        .loadPendingResult();
    expect(pending, isNotNull);
    expect(pending!.result.receiveSticker, isNull);
    expect(await const ActiveActivityTimerSessionStore().load(), isNull);
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
    await pumpRunningTimerAtProgress(
      tester,
      progress: 0.5,
      timerAudioService: FakeTimerAudioService(),
    );
    await completeTimerFromControl(tester);

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
    final timerAudioService = FakeTimerAudioService();

    await pumpRunningTimerAtProgress(
      tester,
      progress: 0.9,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await completeTimerFromControl(tester);

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
    final timerAudioService = FakeTimerAudioService();

    await pumpRunningTimerAtProgress(
      tester,
      progress: 0.6,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await completeTimerFromControl(tester);

    expect(timerAudioService.calls, ['stopBgm', 'playFinishDriveShortSfx']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen plays long finish-drive SFX by threshold', (
    tester,
  ) async {
    final timerAudioService = FakeTimerAudioService();

    await pumpRunningTimerAtProgress(
      tester,
      progress: 0.1,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await completeTimerFromControl(tester);

    expect(timerAudioService.calls, ['stopBgm', 'playFinishDriveLongSfx']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen suppresses finish audio when sound is disabled', (
    tester,
  ) async {
    final timerAudioService = FakeTimerAudioService();

    await pumpRunningTimerAtProgress(
      tester,
      progress: 0.1,
      timerAudioService: timerAudioService,
      soundEnabled: false,
    );
    timerAudioService.calls.clear();
    await completeTimerFromControl(tester);

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
    final timerAudioService = FakeTimerAudioService();

    await pumpRunningTimerAtProgress(
      tester,
      progress: 0.1,
      timerAudioService: timerAudioService,
    );
    timerAudioService.calls.clear();
    await completeTimerFromControl(tester);

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
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

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
    final orientationService = FakeOrientationService();

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
}
