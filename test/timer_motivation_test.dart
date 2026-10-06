import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

import 'support/timer_test_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Timer screen plays motivation voice after video starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final motivationAudioService = FakeMotivationAudioService();
    var now = DateTime(2026);

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
            duration: const Duration(seconds: 100),
            soundEnabled: true,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationAudioService: motivationAudioService,
          motivationMediaAvailable: true,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsOneWidget,
    );
    expect(motivationAudioService.playedAssets, isEmpty);

    await tester.pump(motivationVoiceStartDelay);

    expect(motivationAudioService.playedAssets, hasLength(1));
    expect(
      motivationAudioService.playedAssets.single,
      startsWith('assets/audio/motivation/ko_'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Timer screen uses three-minute motivation cadence for long timer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026);

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
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      now = now.add(const Duration(minutes: 2, seconds: 59));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets(
    'Timer screen custom motivation interval ignores percent milestones',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026);

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
              duration: const Duration(minutes: 15),
              soundEnabled: false,
              motivationVideoUseCustomInterval: true,
              motivationVideoInterval: const Duration(minutes: 5),
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsNothing,
      );

      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets('Timer screen closes active motivation video when disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    var now = DateTime(2026);

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
            duration: const Duration(minutes: 60),
            soundEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationMediaAvailable: true,
          now: () => now,
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_3')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('timerMotivationVideoHelpButton')),
      findsOneWidget,
    );

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        )
        .onChanged!(false);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('motivationSettingsApplyButton')),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('motivationVideoBubble_3')), findsNothing);
    expect(changedConfig?.motivationVideoEnabled, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Timer motivation settings dismiss keeps pending changes unapplied',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ActivityTimerConfig? changedConfig;
      var now = DateTime(2026);

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
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (config) => changedConfig = config,
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
          )
          .onChanged!(false);
      await tester.pump();
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('motivationSettingsCancelButton')),
          )
          .onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(changedConfig, isNull);
      expect(
        find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets(
    'Timer screen restarts custom motivation interval from change time',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026);

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
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            motivationMediaAvailable: true,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
          )
          .onChanged!(true);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('motivationSettingsApplyButton')),
      );
      await tester.pump();

      now = now.add(const Duration(minutes: 2, seconds: 59));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsNothing,
      );

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets('Timer screen skips motivation videos when disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2026);

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
            duration: const Duration(minutes: 60),
            soundEnabled: false,
            motivationVideoEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationMediaAvailable: true,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('motivationVideoBubble_3')), findsNothing);
    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Timer screen hides portrait motivation entry point when unavailable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(
        find.byKey(const ValueKey('motivationSettingsButton')),
        findsNothing,
      );
      expect(find.byIcon(Icons.video_settings_rounded), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets(
    'Timer screen hides landscape motivation entry point when unavailable',
    (tester) async {
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
          locale: const Locale('en'),
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey('timerSoundToggleButton')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey('motivationSettingsButton')),
        findsNothing,
      );
      expect(find.byIcon(Icons.video_settings_rounded), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets(
    'Timer screen hides compact landscape motivation entry point when unavailable',
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
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(
        find.byKey(const ValueKey('compactLandscapeControls')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('timerSoundToggleButton')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey('motivationSettingsButton')),
        findsNothing,
      );
      expect(find.byIcon(Icons.video_settings_rounded), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets('Timer screen blocks motivation cue and audio when unavailable', (
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
    final motivationAudioService = FakeMotivationAudioService();
    final store = ActiveActivityTimerSessionStore();
    var now = DateTime(2026);

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
            duration: const Duration(seconds: 100),
            soundEnabled: true,
            motivationVideoEnabled: true,
          ),
          activityProgressService: LocalActivityProgressService(),
          motivationAudioService: motivationAudioService,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(motivationVoiceStartDelay);

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsNothing,
    );
    expect(motivationAudioService.playedAssets, isEmpty);
    final session = await store.load();
    expect(session, isNotNull);
    expect(session!.config.motivationVideoEnabled, isTrue);
    expect(session.shownMotivationMilestones, isEmpty);
    expect(session.lastMotivationVideoShownAt, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Timer screen blocks restored motivation-enabled session when unavailable',
    (tester) async {
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
      final motivationAudioService = FakeMotivationAudioService();
      final store = ActiveActivityTimerSessionStore();
      final startedAt = DateTime(2026);
      final now = startedAt.add(const Duration(seconds: 10));
      final session = ActiveActivityTimerSession(
        sessionId: 'motivation-enabled-session',
        startedAt: startedAt,
        config: ActivityTimerConfig.defaults().copyWith(
          duration: const Duration(seconds: 100),
          soundEnabled: true,
          motivationVideoEnabled: true,
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
            motivationAudioService: motivationAudioService,
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pump(motivationVoiceStartDelay);

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );
      expect(motivationAudioService.playedAssets, isEmpty);
      final savedSession = await store.load();
      expect(savedSession, isNotNull);
      expect(savedSession!.config.motivationVideoEnabled, isTrue);
      expect(savedSession.shownMotivationMilestones, isEmpty);
      expect(savedSession.lastMotivationVideoShownAt, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );
}
