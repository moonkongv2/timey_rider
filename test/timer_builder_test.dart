import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/catalogs/activity_marker_catalog.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('Timer builder shows all manual marker choices', (tester) async {
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await selectTimerBuilderManualMode(tester);
    expect(tester.takeException(), isNull);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timerBuilderSelectedMarkerCount')),
      findsOneWidget,
    );
    expect(find.text('0/5개 선택'), findsOneWidget);
    expect(find.text('마커를 1~5개 선택해요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_top_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_bottom_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_cover')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_blocks')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_star')),
      findsOneWidget,
    );
    expect(find.text('안쪽 꼼꼼'), findsNothing);
    expect(find.text('마무리 헹굼'), findsNothing);

    for (final markerId in [
      'top_teeth',
      'bottom_teeth',
      'molars',
      'tongue',
      'star',
    ]) {
      tester
          .widget<ChoiceChip>(
            find.byKey(ValueKey('timerBuilderMarker_$markerId')),
          )
          .onSelected!(true);
      await tester.pump();
    }

    expect(find.text('5/5개 선택'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('timerBuilderMarker_cover')),
          )
          .onSelected,
      isNull,
    );
    expect(find.byType(TimerScreen), findsNothing);
  });

  testWidgets('Timer builder can switch to manual marker mode', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsOneWidget);
    expect(find.text('2. 마커'), findsOneWidget);

    await selectTimerBuilderManualMode(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderMarker_top_teeth')),
      findsOneWidget,
    );
  });

  testWidgets('Timer builder opens course marker help sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderMarkerHelpButton')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('timerBuilderMarkerHelpButton')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.textContaining('직접 고른 그림 마커'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('appHelpSheet')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Timer builder auto marker starts timer without manual choices', (
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.off,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_top_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_bottom_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_star')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_flag')),
      findsNothing,
    );
    await startTimerBuilder(tester);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsNothing);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
      hasLength(
        ActivityMarkerCatalog.autoSelectionIdsForActivity('brushing').length,
      ),
    );
    expect(
      tester
          .widget<TimerScreen>(find.byType(TimerScreen))
          .config
          .selectedMarkerIds,
      isEmpty,
    );
  });

  testWidgets('Timer builder automatic marker starts timer', (tester) async {
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.activityDefault,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await startTimerBuilder(tester);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsNothing);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
      hasLength(
        ActivityMarkerCatalog.autoSelectionIdsForActivity('brushing').length,
      ),
    );
    expect(
      tester
          .widget<TimerScreen>(find.byType(TimerScreen))
          .config
          .selectedMarkerIds,
      isEmpty,
    );
  });

  testWidgets('Starting timer builder opens timer screen', (tester) async {
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await startTimerBuilder(tester);

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
      const Duration(minutes: 2),
    );
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
      hasLength(4),
    );
  });

  testWidgets(
    'Selecting timer builder markers opens timer with selected markers',
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
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      await openTimerBuilder(tester);
      await selectTimerBuilderManualMarkers(tester, [
        'top_teeth',
        'bottom_teeth',
      ]);
      await startTimerBuilder(tester);

      expect(
        tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
        ['top_teeth', 'bottom_teeth'],
      );
      expect(
        tester
            .widget<TimerScreen>(find.byType(TimerScreen))
            .config
            .selectedMarkerIds,
        ['top_teeth', 'bottom_teeth'],
      );
    },
  );
  testWidgets('Dismissing the timer builder does not open timer screen', (
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
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsNothing);
    expect(find.byType(TimerScreen), findsNothing);
  });

  testWidgets('Timer builder shows MVP activities and default durations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
            duration: const Duration(minutes: 15),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);
    await openTimerBuilder(tester);

    expect(find.text('양치'), findsWidgets);
    expect(find.text('책 읽기'), findsWidgets);
    expect(find.text('정리'), findsOneWidget);
    expect(find.text('놀이'), findsWidgets);
    expect(find.text('식사'), findsOneWidget);
    expect(find.text('기타'), findsOneWidget);
    expect(find.text('2분'), findsOneWidget);

    await selectTimerBuilderActivity(tester, 'reading');

    expect(find.text('15분'), findsOneWidget);
  });

  testWidgets('Timer builder does not overwrite default duration', (
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
    ActivityTimerConfig? changedConfig;

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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await selectTimerBuilderActivity(tester, 'reading');

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsOneWidget);
    expect(find.byType(TimerScreen), findsNothing);

    await startTimerBuilder(tester);

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
      const Duration(minutes: 15),
    );
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.activityId,
      'reading',
    );
    expect(changedConfig, isNull);
  });

  testWidgets(
    'Timer motivation settings do not overwrite default activity duration',
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
      ActivityTimerConfig? changedConfig;

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
              duration: const Duration(minutes: 35),
              markerMode: ActivityMarkerMode.manual,
            ),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (config) => changedConfig = config,
            motivationMediaAvailable: true,
          ),
        ),
      );

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      await openTimerBuilder(tester);
      await selectTimerBuilderActivity(tester, 'reading');
      await startTimerBuilder(tester);

      expect(find.byType(TimerScreen), findsOneWidget);
      expect(
        tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
        const Duration(minutes: 15),
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
      await tester.tap(
        find.byKey(const ValueKey('motivationSettingsApplyButton')),
      );
      await tester.pump();

      expect(changedConfig?.duration, const Duration(minutes: 35));
      expect(changedConfig?.motivationVideoEnabled, isFalse);
      expect(
        changedConfig?.markerIds,
        ActivityCatalog.defaultActivity.markerIds,
      );
    },
  );
}
