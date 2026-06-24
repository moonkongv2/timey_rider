import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/screens/onboarding_screen.dart';

void main() {
  testWidgets('Korean onboarding first card shows localized copy', (
    tester,
  ) async {
    await _pumpOnboardingScreen(tester, locale: const Locale('ko'));

    expect(find.text('아이들에게 시간은\n아직 눈에 잘 보이지 않아요'), findsOneWidget);
    expect(find.textContaining('매일의 일상이 씨름처럼 느껴질 때가 있죠.'), findsOneWidget);
    expect(find.text('괜찮아요, 같이 시작해요'), findsOneWidget);
  });

  testWidgets('Next button advances to the second onboarding card', (
    tester,
  ) async {
    await _pumpOnboardingScreen(tester, locale: const Locale('ko'));

    await tester.tap(find.byKey(const ValueKey('onboardingNextButton')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 루틴을\n신나는 라이딩으로 바꿔요'), findsOneWidget);
  });

  testWidgets('Final onboarding CTA calls onFinished once', (tester) async {
    var finishedCount = 0;
    await _pumpOnboardingScreen(
      tester,
      locale: const Locale('ko'),
      onFinished: () async => finishedCount += 1,
    );

    for (var index = 0; index < 4; index += 1) {
      await tester.tap(find.byKey(const ValueKey('onboardingNextButton')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('onboardingNextButton')));
    await tester.pumpAndSettle();

    expect(finishedCount, 1);
  });

  testWidgets('Skip button calls onFinished once', (tester) async {
    var finishedCount = 0;
    await _pumpOnboardingScreen(
      tester,
      locale: const Locale('ko'),
      onFinished: () async => finishedCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey('onboardingSkipButton')));
    await tester.pumpAndSettle();

    expect(finishedCount, 1);
  });

  testWidgets('English onboarding first card shows localized copy', (
    tester,
  ) async {
    await _pumpOnboardingScreen(tester, locale: const Locale('en'));

    expect(find.text("Kids can't see time yet"), findsOneWidget);
    expect(find.text('Start together'), findsOneWidget);
  });
}

Future<void> _pumpOnboardingScreen(
  WidgetTester tester, {
  required Locale locale,
  Future<void> Function()? onFinished,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppTexts.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: OnboardingScreen(onFinished: onFinished ?? () async {}),
    ),
  );
  await tester.pumpAndSettle();
}
