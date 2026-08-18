import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/motivation_audio_service.dart';
import 'package:timey_rider/services/orientation_service.dart';
import 'package:timey_rider/services/screen_awake_service.dart';
import 'package:timey_rider/services/timer_audio_service.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';

Future<void> pumpRunningTimerAtProgress(
  WidgetTester tester, {
  required double progress,
  required FakeTimerAudioService timerAudioService,
  bool soundEnabled = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'savedActivityTimerPresetsInitialized': true,
  });
  final startedAt = DateTime(2026);
  final duration = const Duration(seconds: 100);
  final config = ActivityTimerConfig.defaults().copyWith(
    duration: duration,
    soundEnabled: soundEnabled,
  );
  final now = startedAt.add(
    Duration(milliseconds: (duration.inMilliseconds * progress).round()),
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      home: TimerScreen(
        config: config,
        restoredSession: ActiveActivityTimerSession(
          sessionId: 'finish-audio-session-$progress-$soundEnabled',
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
}

Future<void> completeTimerFromControl(WidgetTester tester) async {
  tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
  await tester.pump();
  await tester.tap(find.byType(FilledButton).last);
  await tester.pump();
}

class FakeScreenAwakeService implements ScreenAwakeService {
  final List<bool> enabledValues = [];

  @override
  Future<void> setEnabled(bool enabled) async {
    enabledValues.add(enabled);
  }
}

class FakeOrientationService implements OrientationService {
  final List<String> calls = [];

  @override
  Future<void> lockPortrait() async {
    calls.add('lockPortrait');
  }

  @override
  Future<void> allowTimerOrientations() async {
    calls.add('allowTimerOrientations');
  }
}

class FakeMotivationAudioService implements MotivationAudioService {
  final List<String> playedAssets = [];
  var stopCount = 0;
  var disposeCount = 0;

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

class FakeTimerAudioService implements TimerAudioService {
  final List<String> calls = [];

  @override
  Future<void> startOrResumeBgm() async => calls.add('startOrResumeBgm');

  @override
  Future<void> pauseBgm() async => calls.add('pauseBgm');

  @override
  Future<void> stopBgm() async => calls.add('stopBgm');

  @override
  Future<void> playMarkerSfx() async => calls.add('playMarkerSfx');

  @override
  Future<void> playCourseLoading() async => calls.add('playCourseLoading');

  @override
  Future<void> stopCourseLoading() async => calls.add('stopCourseLoading');

  @override
  Future<void> playReadyStartBeep() async => calls.add('playReadyStartBeep');

  @override
  Future<void> stopReadyStartBeep() async => calls.add('stopReadyStartBeep');

  @override
  Future<void> playFinishDriveShortSfx() async {
    calls.add('playFinishDriveShortSfx');
  }

  @override
  Future<void> playFinishDriveLongSfx() async {
    calls.add('playFinishDriveLongSfx');
  }

  @override
  Future<void> stopFinishDriveSfx() async => calls.add('stopFinishDriveSfx');

  @override
  Future<void> playFinishArrivalSfx() async =>
      calls.add('playFinishArrivalSfx');

  @override
  Future<void> stopAll() async => calls.add('stopAll');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

class DelayedClearActiveSessionStore extends ActiveActivityTimerSessionStore {
  DelayedClearActiveSessionStore(this.currentSession);

  ActiveActivityTimerSession? currentSession;
  Completer<void>? _clearCompleter;

  bool get clearStarted => _clearCompleter != null;

  @override
  Future<void> save(ActiveActivityTimerSession session) async {
    currentSession = session;
  }

  @override
  Future<ActiveActivityTimerSession?> load() async => currentSession;

  @override
  Future<void> clear() async {
    _clearCompleter ??= Completer<void>();
    await _clearCompleter!.future;
    currentSession = null;
  }

  void completeClear() {
    final completer = _clearCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
