import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/activity_timer_preset.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/local_recent_timer_service.dart';
import 'package:timey_rider/services/local_saved_timer_preset_service.dart';

import 'support/app_test_harness.dart';
import 'support/test_preferences.dart';

void main() {
  testWidgets('Timer builder saves the latest started timer preset', (
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
      await const LocalRecentTimerService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 9),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await selectTimerBuilderActivity(tester, 'reading');
    await setTimerBuilderMinutes(tester, 18);
    await selectTimerBuilderManualMarkers(tester, ['cover', 'bookmark']);
    await startTimerBuilder(tester);

    final preset = await const LocalRecentTimerService().load();
    expect(preset, isNotNull);
    expect(preset!.activityId, 'reading');
    expect(preset.duration, const Duration(minutes: 18));
    expect(preset.markerMode, ActivityMarkerMode.manual);
    expect(preset.markerIds, ['cover', 'bookmark']);
    expect(preset.selectedMarkerIds, ['cover', 'bookmark']);
    expect(preset.updatedAt, DateTime(2026, 6, 14, 9));
  });

  testWidgets('Timer builder applies a saved recent timer preset', (
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
      await const LocalRecentTimerService().clear();
    });
    await const LocalRecentTimerService().save(
      ActivityTimerPreset(
        activityId: 'brushing',
        duration: Duration(minutes: 18),
        markerMode: ActivityMarkerMode.manual,
        markerIds: ['cover', 'bookmark'],
        selectedMarkerIds: ['cover', 'bookmark'],
        updatedAt: DateTime(2026, 6, 14, 8),
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
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderRecentPresetCard')),
      findsOneWidget,
    );
    expect(find.text('최근 설정'), findsOneWidget);
    expect(find.textContaining('양치 · 18분'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('timerBuilderRecentPresetApplyButton')),
    );
    await tester.pump();
    await startTimerBuilder(tester);

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.config.activityId, 'brushing');
    expect(timerScreen.config.duration, const Duration(minutes: 18));
    expect(timerScreen.config.markerMode, ActivityMarkerMode.manual);
    expect(timerScreen.config.markerIds, ['cover', 'bookmark']);
    expect(timerScreen.config.selectedMarkerIds, ['cover', 'bookmark']);
  });

  testWidgets('Timer builder saves a reusable timer preset', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 10),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await selectTimerBuilderActivity(tester, 'reading');
    await setTimerBuilderMinutes(tester, 18);
    await selectTimerBuilderManualMarkers(tester, ['cover', 'bookmark']);
    await saveTimerBuilderPreset(tester);

    final presets = await const LocalSavedTimerPresetService().load();
    expect(presets, hasLength(1));
    expect(presets.first.activityId, 'reading');
    expect(presets.first.duration, const Duration(minutes: 18));
    expect(presets.first.markerMode, ActivityMarkerMode.manual);
    expect(presets.first.selectedMarkerIds, ['cover', 'bookmark']);
    expect(presets.first.updatedAt, DateTime(2026, 6, 14, 10));
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCard_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCount')),
      findsOneWidget,
    );
    expect(find.text('1/5개'), findsOneWidget);
    expect(find.text('저장한 타이머'), findsOneWidget);
    expect(find.text('저장했어요.'), findsOneWidget);
  });

  testWidgets('Timer builder shows the saved timer preset limit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });

    final savedTimerPresetService = const LocalSavedTimerPresetService();
    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxSavedPresets;
      index += 1
    ) {
      await savedTimerPresetService.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: Duration(minutes: 10 + index),
          markerMode: ActivityMarkerMode.activityDefault,
          markerIds: const ['star'],
          selectedMarkerIds: const [],
          updatedAt: DateTime(2026, 6, 14, index),
          customName: '저장 $index',
        ),
      );
    }

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
          now: () => DateTime(2026, 6, 14, 12),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    expect(find.text('5/5개'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetLimitHint')),
      findsOneWidget,
    );
    expect(find.text('저장한 타이머 5/5개'), findsOneWidget);
    expect(find.text('새로 저장하면 가장 오래된 타이머가 정리돼요.'), findsOneWidget);

    await selectTimerBuilderActivity(tester, 'reading');
    await setTimerBuilderMinutes(tester, 18);
    await saveTimerBuilderPreset(tester);

    final presets = await savedTimerPresetService.load();
    expect(presets, hasLength(LocalSavedTimerPresetService.maxSavedPresets));
    expect(find.text('5/5개'), findsOneWidget);
    expect(find.text('저장했어요. 오래된 타이머는 자동으로 정리돼요.'), findsOneWidget);
  });

  testWidgets('Timer builder toggles saved timer home favorites', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });
    const savedTimerPresetService = LocalSavedTimerPresetService();
    await savedTimerPresetService.save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: const Duration(minutes: 15),
        markerMode: ActivityMarkerMode.activityDefault,
        updatedAt: DateTime(2026, 6, 14, 8),
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
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    expect(find.byTooltip('홈에 표시'), findsOneWidget);
    tester
        .widget<IconButton>(
          find.byKey(const ValueKey('timerBuilderSavedPresetFavoriteButton_0')),
        )
        .onPressed!();
    await tester.pump();

    var presets = await savedTimerPresetService.load();
    expect(presets.first.isFavorite, isTrue);
    expect(find.byTooltip('홈에서 숨기기'), findsOneWidget);

    tester
        .widget<IconButton>(
          find.byKey(const ValueKey('timerBuilderSavedPresetFavoriteButton_0')),
        )
        .onPressed!();
    await tester.pump();

    presets = await savedTimerPresetService.load();
    expect(presets.first.isFavorite, isFalse);
    expect(find.byTooltip('홈에 표시'), findsOneWidget);
  });

  testWidgets('Timer builder shows the home favorite limit message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });
    const savedTimerPresetService = LocalSavedTimerPresetService();
    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxFavoritePresets + 1;
      index += 1
    ) {
      await savedTimerPresetService.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: Duration(minutes: 10 + index),
          markerMode: ActivityMarkerMode.activityDefault,
          updatedAt: DateTime(2026, 6, 14, index),
          customName: '홈 타이머 $index',
        ),
      );
    }

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

    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxFavoritePresets;
      index += 1
    ) {
      tester
          .widget<IconButton>(
            find.byKey(
              ValueKey('timerBuilderSavedPresetFavoriteButton_$index'),
            ),
          )
          .onPressed!();
      await tester.pump();
    }

    tester
        .widget<IconButton>(
          find.byKey(
            ValueKey(
              'timerBuilderSavedPresetFavoriteButton_${LocalSavedTimerPresetService.maxFavoritePresets}',
            ),
          ),
        )
        .onPressed!();
    await tester.pump();

    final presets = await savedTimerPresetService.load();
    expect(
      presets.where((preset) => preset.isFavorite),
      hasLength(LocalSavedTimerPresetService.maxFavoritePresets),
    );
    expect(find.text('홈에는 최대 3개까지 표시할 수 있어요.'), findsOneWidget);
  });

  testWidgets('Home shows favorite saved timer presets for quick start', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
      await const LocalRecentTimerService().clear();
    });
    await const LocalSavedTimerPresetService().save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: Duration(minutes: 18),
        markerMode: ActivityMarkerMode.manual,
        markerIds: ['cover', 'bookmark'],
        selectedMarkerIds: ['cover', 'bookmark'],
        updatedAt: DateTime(2026, 6, 14, 8),
        isFavorite: true,
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
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump();

    expect(
      find.byKey(const ValueKey('homeFavoriteTimerCard_0')),
      findsOneWidget,
    );
    expect(find.text('책 읽기'), findsOneWidget);
    expect(find.text('18분'), findsOneWidget);
    final favoriteTop = tester
        .getTopLeft(find.byKey(const ValueKey('homeFavoriteTimerCard_0')))
        .dy;
    final createTimerTop = tester
        .getTopLeft(find.byKey(const ValueKey('createTimerCard')))
        .dy;
    expect(favoriteTop, lessThan(createTimerTop));
    final favoriteActionCenter = tester.getCenter(
      find.descendant(
        of: find.byKey(const ValueKey('homeFavoriteTimerCard_0')),
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    final createActionCenter = tester.getCenter(
      find.descendant(
        of: find.byKey(const ValueKey('createTimerCard')),
        matching: find.byIcon(Icons.add_rounded),
      ),
    );
    expect(createActionCenter.dx, closeTo(favoriteActionCenter.dx, 0.1));

    await tester.tap(find.byKey(const ValueKey('homeFavoriteTimerCard_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.config.activityId, 'reading');
    expect(timerScreen.config.duration, const Duration(minutes: 18));
    expect(timerScreen.config.markerMode, ActivityMarkerMode.manual);
    expect(timerScreen.config.markerIds, ['cover', 'bookmark']);
    expect(timerScreen.config.selectedMarkerIds, ['cover', 'bookmark']);
  });

  testWidgets('Timer builder saves a named custom timer preset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 11),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await selectTimerBuilderActivity(tester, 'custom');
    await setTimerBuilderMinutes(tester, 12);
    await saveTimerBuilderPreset(tester);

    expect(find.text('타이머 이름'), findsOneWidget);
    const longCustomName = '피아노연습타이머이름길게입력테스트초과';
    const limitedCustomName = '피아노연습타이머이름길게입력테스트초';
    await tester.enterText(
      find.byKey(const ValueKey('timerBuilderCustomNameField')),
      longCustomName,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('timerBuilderCustomNameField')),
          )
          .controller
          ?.text,
      limitedCustomName,
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('timerBuilderSaveCustomNameButton')),
        )
        .onPressed!();
    await tester.pump();

    final presets = await const LocalSavedTimerPresetService().load();
    expect(presets, hasLength(1));
    expect(presets.first.activityId, 'custom');
    expect(presets.first.customName, limitedCustomName);
    expect(find.textContaining('$limitedCustomName · 12분'), findsOneWidget);
  });

  testWidgets('Timer builder can save a custom timer as Other without a name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 11),
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);
    await selectTimerBuilderActivity(tester, 'custom');
    await saveTimerBuilderPreset(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('timerBuilderUseOtherNameButton')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final presets = await const LocalSavedTimerPresetService().load();
    expect(presets, hasLength(1));
    expect(presets.first.customName, isNull);
    expect(find.textContaining('기타 · 10분'), findsOneWidget);
  });

  testWidgets('Timer builder applies and deletes a saved timer preset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setInitializedEmptySavedTimerPresets();
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });
    await const LocalSavedTimerPresetService().save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: Duration(minutes: 18),
        markerMode: ActivityMarkerMode.manual,
        markerIds: ['cover', 'bookmark'],
        selectedMarkerIds: ['cover', 'bookmark'],
        updatedAt: DateTime(2026, 6, 14, 8),
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
        ),
      ),
    );
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await openTimerBuilder(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCard_0')),
      findsOneWidget,
    );
    expect(find.textContaining('책 읽기 · 18분'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('timerBuilderSavedPresetApplyButton_0')),
    );
    await tester.pump();
    await startTimerBuilder(tester);

    var timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.config.activityId, 'reading');
    expect(timerScreen.config.duration, const Duration(minutes: 18));
    expect(timerScreen.config.markerIds, ['cover', 'bookmark']);

    Navigator.of(tester.element(find.byType(TimerScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await openTimerBuilder(tester);

    tester
        .widget<IconButton>(
          find.byKey(const ValueKey('timerBuilderSavedPresetDeleteButton_0')),
        )
        .onPressed!();
    await tester.pump();

    expect(await const LocalSavedTimerPresetService().load(), isEmpty);
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCard_0')),
      findsNothing,
    );
  });
}
