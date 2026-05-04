import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jy_yamyam/main.dart' as app;

void main() {
  testWidgets('Home screen shows meal timer actions', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await app.main();
    await tester.pumpAndSettle();

    expect(find.text('냠냠 라이더'), findsOneWidget);
    expect(find.text('15분 아침 코스'), findsOneWidget);
    expect(find.text('25분 보통 코스'), findsOneWidget);
    expect(find.text('35분 천천히 코스'), findsOneWidget);
    expect(find.text('직접 설정으로 출발'), findsOneWidget);
  });

  testWidgets('Remaining time setting can be turned off', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.text('남은 시간 보여주기'), findsOneWidget);
    await tester.tap(find.text('남은 시간 보여주기'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('25분 보통 코스'));
    await tester.pump();

    expect(find.textContaining('남은 시간'), findsNothing);
  });
}
