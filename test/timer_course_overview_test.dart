import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  testWidgets('TimerScreen course overview scrolls back to vehicle progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

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

    expect(find.byKey(const ValueKey('courseOverviewButton')), findsNothing);
    final controls = tester.widget<TimerControlBar>(
      find.byType(TimerControlBar),
    );
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
      greaterThan(
        tester.widget<RoadView>(find.byType(RoadView)).vehicleProgress,
      ),
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final timerAudioService = FakeTimerAudioService();
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    expect(
      controlsRect.right,
      lessThanOrEqualTo(tester.view.physicalSize.width),
    );
    expect(
      controlsRect.bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );

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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
          .widget<IconButton>(
            find.byKey(const ValueKey('courseOverviewButton')),
          )
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final startedAt = DateTime(2026, 6, 10, 8);
    final store = DelayedClearActiveSessionStore(
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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
}
