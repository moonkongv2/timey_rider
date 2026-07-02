import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/widgets/purchase/vehicle_pack_info_sheet.dart';

void main() {
  testWidgets('vehicle pack info sheet continues with guardian flow', (
    tester,
  ) async {
    Future<bool>? sheetResult;
    await _pumpVehiclePackInfoHost(
      tester,
      onOpenSheet: (context) {
        sheetResult = showVehiclePackInfoSheet(
          context,
          vehicleId: 'fire_truck',
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('openVehiclePackInfoButton')));
    await tester.pumpAndSettle();

    expect(find.text('차량팩이 필요한 빠방이에요'), findsOneWidget);
    expect(find.text('소방차 빠방은 차량팩에 포함되어 있어요.'), findsOneWidget);
    expect(find.text('차량팩을 열면 잠긴 빠방을 모두 사용할 수 있어요.'), findsOneWidget);
    expect(find.text('보호자와 계속하기'), findsOneWidget);
    expect(find.text('구매하기'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('vehiclePackInfoContinueButton')),
    );
    await tester.pumpAndSettle();

    expect(await sheetResult, isTrue);
  });

  testWidgets('vehicle pack info sheet can be dismissed', (tester) async {
    Future<bool>? sheetResult;
    await _pumpVehiclePackInfoHost(
      tester,
      locale: const Locale('en'),
      onOpenSheet: (context) {
        sheetResult = showVehiclePackInfoSheet(context, vehicleId: 'airplane');
      },
    );

    await tester.tap(find.byKey(const ValueKey('openVehiclePackInfoButton')));
    await tester.pumpAndSettle();

    expect(find.text('This vehicle is in the vehicle pack'), findsOneWidget);
    expect(
      find.text('Airplane is included in the vehicle pack.'),
      findsOneWidget,
    );
    expect(find.text('Continue with a parent'), findsOneWidget);
    expect(find.text('Buy now'), findsNothing);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(await sheetResult, isFalse);
  });
}

Future<void> _pumpVehiclePackInfoHost(
  WidgetTester tester, {
  Locale locale = const Locale('ko'),
  required ValueChanged<BuildContext> onOpenSheet,
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
                key: const ValueKey('openVehiclePackInfoButton'),
                onPressed: () => onOpenSheet(context),
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    ),
  );
}
