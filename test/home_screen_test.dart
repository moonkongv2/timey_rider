import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/activity_catalog.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('Home screen shows activity timer actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    await startTestApp(tester, const Locale('ko'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.text('기본 얼굴 사용 중'), findsOneWidget);
    expect(find.text('만들기'), findsOneWidget);
    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.text('타이머 만들기'), findsWidgets);
    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);
    expect(find.textContaining('미션, 마커, 시간을'), findsOneWidget);
    expect(find.text('양치'), findsNothing);
    expect(find.text('식사'), findsNothing);
    expect(find.text('기타'), findsNothing);

    await openTimerBuilder(tester);

    expect(find.text('양치'), findsWidgets);
    expect(find.text('책 읽기'), findsWidgets);
    expect(find.text('정리'), findsOneWidget);
    expect(find.text('놀이'), findsWidgets);
    expect(find.text('식사'), findsOneWidget);
    expect(find.text('기타'), findsOneWidget);
    for (final activity in ActivityCatalog.all) {
      expect(
        find.byKey(ValueKey('timerBuilderActivity_${activity.id}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('Initial app UI does not show legacy domain copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const legacyCopyTerms = [
      'Ya'
          'myam',
      'ya'
          'myam',
      '냠'
          '냠',
      '식'
          '사',
      '식재'
          '료',
      'me'
          'al',
      'ingred'
          'ient',
      'fo'
          'od',
      'eat'
          'ing',
      'tas'
          'ty',
    ];

    for (final locale in const [Locale('ko'), Locale('en')]) {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });
      await startTestApp(tester, locale);
      await tester.pumpAndSettle();

      final visibleCopy = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
          .where((text) => text.isNotEmpty)
          .join('\n');

      expect(
        legacyCopyTerms.any(
          (term) => visibleCopy.toLowerCase().contains(term.toLowerCase()),
        ),
        isFalse,
        reason: 'Legacy copy appeared for ${locale.languageCode}: $visibleCopy',
      );
    }
  });
}
