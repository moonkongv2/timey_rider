import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/activity_marker_catalog.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';

import 'support/timer_test_harness.dart';

void main() {
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

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
    final timerAudioService = FakeTimerAudioService();

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
    final timerAudioService = FakeTimerAudioService();

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
    final timerAudioService = FakeTimerAudioService();

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
      final timerAudioService = FakeTimerAudioService();

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
    },
  );

  testWidgets('TimerScreen sound toggle stops course loading during startup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = FakeTimerAudioService();

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

    expect(timerAudioService.calls, ['playCourseLoading', 'stopCourseLoading']);

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
      final timerAudioService = FakeTimerAudioService();

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
    },
  );

  testWidgets('TimerScreen lifecycle does not replay ready beep', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerAudioService = FakeTimerAudioService();

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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final timerAudioService = FakeTimerAudioService();

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

    expect(timerAudioService.calls, ['pauseBgm', 'startOrResumeBgm']);

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
    final timerAudioService = FakeTimerAudioService();

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

    expect(timerAudioService.calls, ['pauseBgm', 'startOrResumeBgm']);

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
    final timerAudioService = FakeTimerAudioService();
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
    expect(timerAudioService.calls, ['stopBgm', 'startOrResumeBgm']);
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
      final timerAudioService = FakeTimerAudioService();
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

    expect(await pumpRestored(ActiveActivityTimerSessionState.running), [
      'startOrResumeBgm',
      'stopBgm',
      'stopAll',
    ]);
    expect(await pumpRestored(ActiveActivityTimerSessionState.paused), [
      'pauseBgm',
      'stopBgm',
      'stopAll',
    ]);

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
    final timerAudioService = FakeTimerAudioService();

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
    final timerAudioService = FakeTimerAudioService();

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
    final timerAudioService = FakeTimerAudioService();

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
    final timerAudioService = FakeTimerAudioService();
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
    final timerAudioService = FakeTimerAudioService();
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
}
