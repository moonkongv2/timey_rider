import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jy_yamyam/main.dart' as app;
import 'package:jy_yamyam/models/meal_session_result.dart';
import 'package:jy_yamyam/models/reward_item.dart';
import 'package:jy_yamyam/services/local_meal_progress_service.dart';

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

  test('Fast meal awards a special sticker with a random sticker', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    final recordedSession = await service.recordMealResult(
      MealSessionResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 10),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 13),
        completedBeforeArrival: true,
      ),
    );

    expect(recordedSession.awardedRewards, hasLength(2));
    expect(
      recordedSession.awardedRewards.map((reward) => reward.id),
      contains(RewardCatalog.lightningYumSticker.id),
    );
  });

  test('Overtime meal does not award stickers', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    final recordedSession = await service.recordMealResult(
      MealSessionResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 25),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeArrival: false,
      ),
    );

    expect(recordedSession.awardedRewards, isEmpty);
  });
}
