import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/app.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/local_settings_service.dart';

void main() {
  testWidgets('unseen onboarding starts on OnboardingScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpApp(tester, initialHasSeenOnboarding: false);

    expect(find.byKey(const ValueKey('onboardingScreen')), findsOneWidget);
  });

  testWidgets('completing onboarding routes to child name setup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpApp(tester, initialHasSeenOnboarding: false);
    await _completeOnboardingWithCta(tester);

    expect(find.text('누가 Timey Rider를 탈까?'), findsOneWidget);
  });

  testWidgets('seen onboarding with default config skips to child name setup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpApp(tester, initialHasSeenOnboarding: true);

    expect(find.byKey(const ValueKey('onboardingScreen')), findsNothing);
    expect(find.text('누가 Timey Rider를 탈까?'), findsOneWidget);
  });

  testWidgets('seen onboarding with child name skips to home', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpApp(
      tester,
      initialHasSeenOnboarding: true,
      initialConfig: ActivityTimerConfig.defaults().copyWith(childName: '하루'),
    );

    expect(find.byKey(const ValueKey('onboardingScreen')), findsNothing);
    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required bool initialHasSeenOnboarding,
  ActivityTimerConfig? initialConfig,
}) async {
  tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
  tester.binding.platformDispatcher.localesTestValue = const [Locale('ko')];
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    TimeyRiderApp(
      settingsService: LocalSettingsService(),
      activityProgressService: LocalActivityProgressService(),
      initialConfig: initialConfig ?? ActivityTimerConfig.defaults(),
      initialHasSeenOnboarding: initialHasSeenOnboarding,
      showSplashOnStart: false,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _completeOnboardingWithCta(WidgetTester tester) async {
  for (var index = 0; index < 5; index += 1) {
    await tester.tap(find.byKey(const ValueKey('onboardingNextButton')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }
}
