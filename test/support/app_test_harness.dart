import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/main.dart' as app;
import 'package:timey_rider/models/activity_progress_snapshot.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/app/app_bouncy_button.dart';

Future<void> startTestApp(
  WidgetTester tester,
  Locale locale, {
  bool completeOnboarding = true,
  bool completeChildNameSetup = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  tester.binding.platformDispatcher.localeTestValue = locale;
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await app.main();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
  if (completeOnboarding &&
      find
          .byKey(const ValueKey('onboardingSkipButton'))
          .evaluate()
          .isNotEmpty) {
    await tester.tap(find.byKey(const ValueKey('onboardingSkipButton')));
    await tester.pumpAndSettle();
  }
  if (!completeChildNameSetup || find.byType(TextField).evaluate().isEmpty) {
    return;
  }

  await tester.enterText(find.byType(TextField), '지율');
  await tester.pump();
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

Future<void> openTimerBuilder(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('createTimerButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> startTimerBuilder(WidgetTester tester) async {
  tester
      .widget<AppBouncyButton>(
        find.byKey(const ValueKey('timerBuilderStartButton')),
      )
      .onPressed!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class CountingActivityProgressService extends LocalActivityProgressService {
  int loadSnapshotCallCount = 0;

  @override
  Future<ActivityProgressSnapshot> loadSnapshot() {
    loadSnapshotCallCount += 1;
    return super.loadSnapshot();
  }
}

Future<void> selectTimerBuilderActivity(
  WidgetTester tester,
  String activityId,
) async {
  tester
      .widget<ChoiceChip>(
        find.byKey(ValueKey('timerBuilderActivity_$activityId')),
      )
      .onSelected!(true);
  await tester.pump();
}

Future<void> selectTimerBuilderManualMode(WidgetTester tester) async {
  tester
      .widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('timerBuilderMarkerManual')),
          matching: find.byType(OutlinedButton),
        ),
      )
      .onPressed!();
  await tester.pump();
}

Future<void> selectTimerBuilderManualMarkers(
  WidgetTester tester,
  List<String> markerIds,
) async {
  await selectTimerBuilderManualMode(tester);

  for (final markerId in markerIds) {
    tester
        .widget<ChoiceChip>(
          find.byKey(ValueKey('timerBuilderMarker_$markerId')),
        )
        .onSelected!(true);
    await tester.pump();
  }
}

Future<void> setTimerBuilderMinutes(WidgetTester tester, int minutes) async {
  tester
      .widget<Slider>(find.byKey(const ValueKey('timerBuilderMinuteSlider')))
      .onChanged!(minutes.toDouble());
  await tester.pump();
}

Future<void> saveTimerBuilderPreset(WidgetTester tester) async {
  tester
      .widget<OutlinedButton>(
        find.byKey(const ValueKey('timerBuilderSavePresetButton')),
      )
      .onPressed!();
  await tester.pump();
}
