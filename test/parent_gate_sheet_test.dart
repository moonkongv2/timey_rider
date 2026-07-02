import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/widgets/purchase/parent_gate_sheet.dart';

void main() {
  testWidgets('parent gate shows an error before accepting the answer', (
    tester,
  ) async {
    Future<bool>? gateResult;
    await _pumpParentGateHost(
      tester,
      onOpenGate: (context) {
        gateResult = showParentGateSheet(
          context,
          challenge: const ParentGateChallenge(left: 9, right: 6),
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('openParentGateButton')));
    await tester.pumpAndSettle();

    expect(find.text('보호자 확인'), findsOneWidget);
    expect(find.text('9 + 6 = ?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('parentGateAnswerField')),
      '14',
    );
    await tester.tap(find.byKey(const ValueKey('parentGateContinueButton')));
    await tester.pumpAndSettle();

    expect(find.text('정답을 다시 확인해 주세요.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('parentGateAnswerField')),
      '15',
    );
    await tester.tap(find.byKey(const ValueKey('parentGateContinueButton')));
    await tester.pumpAndSettle();

    expect(await gateResult, isTrue);
  });

  testWidgets('parent gate cancel returns false', (tester) async {
    Future<bool>? gateResult;
    await _pumpParentGateHost(
      tester,
      locale: const Locale('en'),
      onOpenGate: (context) {
        gateResult = showParentGateSheet(
          context,
          challenge: const ParentGateChallenge(left: 10, right: 4),
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('openParentGateButton')));
    await tester.pumpAndSettle();

    expect(find.text('Parent check'), findsOneWidget);
    expect(find.text('What is 10 + 4?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await gateResult, isFalse);
  });
}

Future<void> _pumpParentGateHost(
  WidgetTester tester, {
  Locale locale = const Locale('ko'),
  required ValueChanged<BuildContext> onOpenGate,
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
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('openParentGateButton'),
                onPressed: () => onOpenGate(context),
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    ),
  );
}
