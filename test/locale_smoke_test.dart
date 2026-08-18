import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('English locale shows English home copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    await startTestApp(tester, const Locale('en'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.text("Today's vehicle"), findsOneWidget);
    expect(find.text('Create Timer'), findsWidgets);
    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);

    await openTimerBuilder(tester);

    expect(find.text('Brush Teeth'), findsWidgets);
    expect(find.text('Reading'), findsWidgets);
    expect(find.text('Cleanup'), findsOneWidget);
    expect(find.text('Play Time'), findsWidgets);
    expect(find.text('Meal'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('2 min'), findsOneWidget);

    await selectTimerBuilderActivity(tester, 'reading');

    expect(find.text('15 min'), findsOneWidget);
  });

  testWidgets('English locale shows English timer progress copy', (
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
    await tester.pump(const Duration(seconds: 2));

    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.text("We're off!"), findsOneWidget);
    expect(find.text('Time left'), findsOneWidget);
    expect(find.text('출발했어요!'), findsNothing);
  });

  testWidgets('Paused timer shows paused status copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
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
    await tester.pump(const Duration(seconds: 2));

    await tester.ensureVisible(find.text('Pause'));
    await tester.pump();
    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Taking a little break'), findsOneWidget);
    expect(find.text('Taking a break'), findsOneWidget);
  });

  testWidgets('Unsupported locale falls back to English', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    await startTestApp(tester, const Locale('fr'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.textContaining('Create Timer'), findsWidgets);
  });
}
