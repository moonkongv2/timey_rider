import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/pending_activity_result.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';
import 'package:timey_rider/widgets/road_painter.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/vehicle_widget.dart';

import 'support/timer_test_harness.dart';

class _DelayedResultStore extends ActiveActivityTimerSessionStore {
  final saved = Completer<void>();
  int attempts = 0;
  bool fail = false;

  @override
  Future<void> savePendingResult(PendingActivityResult result) async {
    attempts++;
    await saved.future;
    if (fail) throw StateError('Test save failure');
  }
}

class _TimerHarness {
  _TimerHarness({
    FakeMotivationAudioService? motivation,
    FakeTimerAudioService? audio,
  }) : motivation = motivation ?? FakeMotivationAudioService(),
       audio = audio ?? FakeTimerAudioService();

  final startedAt = DateTime(2026, 10, 30);
  late DateTime now = startedAt;
  final FakeTimerAudioService audio;
  final FakeMotivationAudioService motivation;
  final store = _DelayedResultStore();
  ActivityTimerConfig config = ActivityTimerConfig.defaults().copyWith(
    duration: const Duration(seconds: 100),
  );

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(600, 900),
    Locale locale = const Locale('ko'),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('ko'), Locale('en')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: TimerScreen(
          config: config,
          restoredSession: ActiveActivityTimerSession(
            sessionId: 'alarm-test',
            config: config,
            startedAt: startedAt,
            state: ActiveActivityTimerSessionState.running,
          ),
          activeSessionStore: store,
          activityProgressService: LocalActivityProgressService(),
          timerAudioService: audio,
          motivationAudioService: motivation,
          motivationMediaAvailable: true,
          screenAwakeService: FakeScreenAwakeService(),
          orientationService: FakeOrientationService(),
          now: () => now,
          onConfigChanged: (value) => config = value,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> expire(WidgetTester tester) async {
    now = startedAt.add(const Duration(seconds: 101));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    if (!store.saved.isCompleted) store.saved.complete();
    await tester.pump();
  }
}

class _DelayedMotivationAudio extends FakeMotivationAudioService {
  final started = Completer<void>();

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
    await started.future;
  }
}

class _DelayedAlarmStop extends FakeTimerAudioService {
  final stopped = Completer<void>();

  @override
  Future<void> stopTimerEndAlarm() async {
    calls.add('stopTimerEndAlarm');
    await stopped.future;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final language in ['en', 'ko']) {
    for (final textScale in [1.0, 1.3]) {
      for (final button in ['arrivalPrimaryButton', 'arrivalSecondaryButton']) {
        testWidgets(
          'Small phone arrival stays visible: $language scale $textScale $button',
          (tester) async {
            final h = _TimerHarness();
            h.config = h.config.copyWith(activityId: 'brushing');
            await h.mount(
              tester,
              size: const Size(390, 844),
              locale: Locale(language),
              textScale: textScale,
            );
            final road = find.byType(RoadView);
            final runningHeight = tester.getSize(road).height;
            await h.expire(tester);
            expect(
              find.byKey(const ValueKey('arrivalActionPanel')),
              findsNothing,
            );
            await tester.pump(const Duration(milliseconds: 900));
            expect(
              find.byKey(const ValueKey('arrivalActionPanel')),
              findsOneWidget,
            );
            expect(tester.getSize(road).height, lessThan(runningHeight));
            expect(find.byType(VehicleWidget), findsOneWidget);
            expect(
              tester
                  .widgetList<CustomPaint>(find.byType(CustomPaint))
                  .map((widget) => widget.painter)
                  .whereType<RoadPainter>(),
              hasLength(1),
            );
            expect(find.byType(ErrorWidget), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pump(const Duration(seconds: 30));
            expect(
              h.audio.calls.where((v) => v == 'startTimerEndAlarm'),
              hasLength(1),
            );
            await tester.tap(find.byKey(ValueKey(button)));
            await tester.pump();
            expect(h.audio.calls.last, 'stopTimerEndAlarm');
            expect(h.store.attempts, 1);
            expect(tester.takeException(), isNull);
            await h.close(tester);
          },
        );
      }
    }
  }

  testWidgets('Alarm starts at zero before panel, without repeated starts', (
    tester,
  ) async {
    final h = _TimerHarness();
    await h.mount(tester);
    await h.expire(tester);
    expect(
      h.audio.calls,
      containsAllInOrder(['stopBgm', 'startTimerEndAlarm']),
    );
    expect(find.byKey(const ValueKey('arrivalActionPanel')), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);
    await h.mount(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(h.audio.calls.where((v) => v == 'startTimerEndAlarm'), hasLength(1));
    expect(h.motivation.playedAssets, isEmpty);
    await h.close(tester);
    expect(h.audio.calls.last, 'stopAll');
  });

  for (final activity in ['brushing', 'play']) {
    for (final button in ['arrivalPrimaryButton', 'arrivalSecondaryButton']) {
      if (activity == 'play' && button == 'arrivalSecondaryButton') continue;
      testWidgets('$activity $button stops alarm before saving completes', (
        tester,
      ) async {
        final h = _TimerHarness();
        h.config = h.config.copyWith(activityId: activity);
        await h.mount(tester);
        await h.expire(tester);
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byKey(ValueKey(button)));
        await tester.pump();
        expect(h.store.attempts, 1);
        expect(h.store.saved.isCompleted, isFalse);
        expect(h.audio.calls.last, 'stopTimerEndAlarm');
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(
          h.audio.calls.where((v) => v == 'startTimerEndAlarm'),
          hasLength(1),
        );
        await h.close(tester);
      });
    }
  }

  testWidgets('Save failure and retry do not restart acknowledged alarm', (
    tester,
  ) async {
    final h = _TimerHarness();
    h.store.fail = true;
    await h.mount(tester);
    await h.expire(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('arrivalPrimaryButton')));
    await tester.pump();
    h.store.saved.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    final retry = tester.widget<SnackBar>(find.byType(SnackBar)).action!;
    retry.onPressed();
    await tester.pump();
    expect(h.store.attempts, 2);
    expect(h.audio.calls.where((v) => v == 'startTimerEndAlarm'), hasLength(1));
    await h.close(tester);
  });

  testWidgets('Completion waits for alarm stop before saving and navigation', (
    tester,
  ) async {
    final audio = _DelayedAlarmStop();
    final h = _TimerHarness(audio: audio);
    await h.mount(tester);
    await h.expire(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('arrivalPrimaryButton')));
    await tester.pump();
    expect(audio.calls.last, 'stopTimerEndAlarm');
    expect(h.store.attempts, 0);
    audio.stopped.complete();
    await tester.pump();
    expect(h.store.attempts, 1);
    await h.close(tester);
  });

  testWidgets('Lifecycle stops alarm and resumes only while unconfirmed', (
    tester,
  ) async {
    final h = _TimerHarness();
    await h.mount(tester);
    await h.expire(tester);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
      expect(h.audio.calls.last, 'stopTimerEndAlarm');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.audio.calls.last, 'startTimerEndAlarm');
    }
    await h.close(tester);
  });

  testWidgets('Timer expiring in background rings on return only', (
    tester,
  ) async {
    final h = _TimerHarness();
    await h.mount(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await h.expire(tester);
    expect(h.audio.calls, isNot(contains('startTimerEndAlarm')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(h.audio.calls.last, 'startTimerEndAlarm');
    await h.close(tester);
  });

  testWidgets('Initially inactive screen does not start an expired alarm', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final h = _TimerHarness();
    await h.mount(tester);
    await h.expire(tester);
    expect(h.audio.calls, isNot(contains('startTimerEndAlarm')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(h.audio.calls.last, 'startTimerEndAlarm');
    await h.close(tester);
  });

  testWidgets(
    'Exit cancellation resumes alarm and exit confirmation stops it',
    (tester) async {
      final h = _TimerHarness();
      await h.mount(tester);
      await h.expire(tester);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(h.audio.calls, contains('stopTimerEndAlarm'));
      expect(
        h.audio.calls.where((v) => v == 'startTimerEndAlarm'),
        hasLength(1),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pump();
      expect(h.audio.calls.last, 'startTimerEndAlarm');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        h.audio.calls.where((v) => v == 'startTimerEndAlarm'),
        hasLength(2),
      );
      await h.close(tester);
    },
  );

  testWidgets('Arrival removes motivation video and cancels delayed voice', (
    tester,
  ) async {
    final h = _TimerHarness();
    await h.mount(tester);
    h.now = h.startedAt.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsOneWidget,
    );
    await h.expire(tester);
    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(h.motivation.playedAssets, isEmpty);
    expect(h.motivation.stopCount, greaterThan(0));
    expect(h.audio.calls.last, 'startTimerEndAlarm');
    await h.close(tester);
  });

  testWidgets('Confirm while voice is loading prevents late alarm start', (
    tester,
  ) async {
    final motivation = _DelayedMotivationAudio();
    final h = _TimerHarness(motivation: motivation);
    await h.mount(tester);
    h.now = h.startedAt.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(motivationVoiceStartDelay);
    expect(motivation.playedAssets, hasLength(1));
    await h.expire(tester);
    expect(h.audio.calls, isNot(contains('startTimerEndAlarm')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('arrivalPrimaryButton')));
    await tester.pump();
    motivation.started.complete();
    await tester.pump();
    expect(motivation.stopCount, greaterThan(0));
    expect(h.audio.calls, isNot(contains('startTimerEndAlarm')));
    await h.close(tester);
  });

  testWidgets('Restored already expired timer stays silent after return', (
    tester,
  ) async {
    final h = _TimerHarness();
    h.now = h.startedAt.add(const Duration(minutes: 3));
    await h.mount(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const ValueKey('arrivalActionPanel')), findsOneWidget);
    expect(h.audio.calls, isNot(contains('startTimerEndAlarm')));
    await h.close(tester);
  });

  testWidgets('Sound toggle and parent config both synchronize pending alarm', (
    tester,
  ) async {
    final h = _TimerHarness();
    h.config = h.config.copyWith(soundEnabled: false);
    await h.mount(tester);
    await h.expire(tester);
    expect(h.audio.calls, isNot(contains('startTimerEndAlarm')));
    await tester.tap(find.byKey(const ValueKey('timerSoundToggleButton')));
    await tester.pump();
    expect(h.audio.calls.last, 'startTimerEndAlarm');
    h.config = h.config.copyWith(soundEnabled: false);
    await h.mount(tester);
    expect(h.audio.calls.last, 'stopTimerEndAlarm');
    h.config = h.config.copyWith(soundEnabled: true);
    await h.mount(tester);
    expect(h.audio.calls.last, 'startTimerEndAlarm');
    await h.close(tester);
  });

  for (final confirmed in [true, false]) {
    testWidgets(
      'Early completion dialog expires then explicit $confirmed stops alarm',
      (tester) async {
        final h = _TimerHarness();
        await h.mount(tester);
        tester
            .widget<TimerControlBar>(find.byType(TimerControlBar))
            .onComplete!();
        await tester.pump();
        await h.expire(tester);
        expect(h.audio.calls.last, 'startTimerEndAlarm');
        if (confirmed) {
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(FilledButton),
            ),
          );
        } else {
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextButton),
            ),
          );
        }
        await tester.pump();
        expect(h.audio.calls.last, 'stopTimerEndAlarm');
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(
          h.audio.calls.where((v) => v == 'startTimerEndAlarm'),
          hasLength(1),
        );
        await h.close(tester);
      },
    );
  }
}
