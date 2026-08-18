import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/road_view.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('Home screen opens a saved active timer session', (tester) async {
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
    final now = startedAt.add(const Duration(minutes: 10));
    final session = ActiveActivityTimerSession(
      sessionId: 'active-session',
      startedAt: startedAt,
      config: ActivityTimerConfig.defaults().copyWith(
        childName: '지율',
        duration: const Duration(minutes: 35),
        vehicleId: 'bus',
      ),
      state: ActiveActivityTimerSessionState.running,
    );
    await const ActiveActivityTimerSessionStore().save(session);

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
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);
    expect(find.text('진행 중인 활동 타이머'), findsOneWidget);

    await tester.tap(find.text('이어가기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.restoredSession?.sessionId, 'active-session');
    expect(timerScreen.config.duration, const Duration(minutes: 35));
  });

  testWidgets('Home screen can cancel a saved active timer session', (
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
    final now = DateTime(2026, 6, 10, 8, 10);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: DateTime(2026, 6, 10, 8),
        config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
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
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('activeTimerCancelButton')));
    await tester.pump();

    expect(find.text('진행 중인 타이머를 취소할까요?'), findsOneWidget);

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(await const ActiveActivityTimerSessionStore().load(), isNull);
    await tester.pump();
    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsNothing);
  });

  testWidgets('Home active timer remaining time updates every second', (
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
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: now.subtract(Duration(minutes: 24, seconds: 50)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
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
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final activeTimerCard = find.byKey(const ValueKey('activeTimerResumeCard'));
    String remainingText() {
      return tester
          .widget<Text>(
            find.descendant(
              of: activeTimerCard,
              matching: find.textContaining('남은 시간'),
            ),
          )
          .data!;
    }

    final initialRemainingText = remainingText();
    expect(initialRemainingText, startsWith('남은 시간 00:'));

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(remainingText(), isNot(initialRemainingText));
  });

  testWidgets('Home active timer tick does not reload progress snapshot', (
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
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: now.subtract(const Duration(minutes: 5)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
        ),
        state: ActiveActivityTimerSessionState.running,
      ),
    );
    final progressService = CountingActivityProgressService();

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
          activityProgressService: progressService,
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(progressService.loadSnapshotCallCount, 1);

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);
    expect(progressService.loadSnapshotCallCount, 1);
  });

  testWidgets('Home paused active timer resume card does not tick', (
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
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'paused-session',
        startedAt: now.subtract(const Duration(minutes: 10)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
        ),
        state: ActiveActivityTimerSessionState.paused,
        pausedAt: now.subtract(const Duration(minutes: 2)),
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
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final activeTimerCard = find.byKey(const ValueKey('activeTimerResumeCard'));
    String remainingText() {
      return tester
          .widget<Text>(
            find.descendant(
              of: activeTimerCard,
              matching: find.textContaining('남은 시간'),
            ),
          )
          .data!;
    }

    final initialRemainingText = remainingText();

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(remainingText(), initialRemainingText);
  });

  testWidgets('Home screen shows finished copy for arrived active sessions', (
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
    final now = DateTime(2026, 6, 10, 8);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: now.subtract(const Duration(minutes: 30)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
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
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);
    expect(find.text('활동 시간이 끝났어요'), findsOneWidget);
    expect(find.textContaining('남은 시간'), findsNothing);
  });

  testWidgets('Home screen clears stale active timer sessions', (tester) async {
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
    final now = DateTime(2026, 6, 10, 8);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'stale-session',
        startedAt: now.subtract(const Duration(hours: 25)),
        config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
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
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(await const ActiveActivityTimerSessionStore().load(), isNull);
    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsNothing);
  });

  testWidgets('Home screen resumes finished active sessions at the finish', (
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
    final now = DateTime(2026, 6, 10, 8);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'finished-session',
        startedAt: now.subtract(const Duration(minutes: 30)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
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
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await tester.tap(find.text('이어가기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.widget<RoadView>(find.byType(RoadView)).progress, 1);
  });

  testWidgets('Starting a new timer with an active session asks first', (
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
    final now = DateTime(2026, 6, 10, 8, 10);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: DateTime(2026, 6, 10, 8),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 35),
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
          config: ActivityTimerConfig.defaults().copyWith(
            childName: '지율',
            duration: const Duration(minutes: 25),
            markerMode: ActivityMarkerMode.off,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await startTimerBuilder(tester);

    expect(find.text('진행 중인 타이머가 있어요'), findsOneWidget);
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).actions,
      hasLength(2),
    );
    expect(find.byType(TimerScreen), findsNothing);

    await tester.tap(find.text('새로 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.restoredSession, isNull);
    expect(timerScreen.config.duration, const Duration(minutes: 2));
  });
}
