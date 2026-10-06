import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/goal_star_pulse.dart';
import 'package:timey_rider/widgets/road_painter.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';
import 'package:timey_rider/widgets/vehicle_widget.dart';

import 'support/timer_test_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
    expect(
      find.byKey(const ValueKey('timerSoundToggleButton')),
      findsOneWidget,
    );
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
    final orientationService = FakeOrientationService();

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
    final screenAwakeService = FakeScreenAwakeService();

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
      final screenAwakeService = FakeScreenAwakeService();

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
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
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
    await tester.pumpAndSettle();

    expect(find.text('타이머 열기'), findsOneWidget);
    expect(find.text('오늘의 미션'), findsNothing);
  });

  testWidgets(
    'Timer exit waits for active session clear before returning home',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });
      final startedAt = DateTime(2026, 6, 10, 8);
      final store = DelayedClearActiveSessionStore(
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

      expect(
        find.byKey(const ValueKey('activeTimerResumeCard')),
        findsOneWidget,
      );

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
    },
  );
}
