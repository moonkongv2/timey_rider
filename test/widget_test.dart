import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jy_yamyam/catalogs/vehicle_catalog.dart';
import 'package:jy_yamyam/main.dart' as app;
import 'package:jy_yamyam/models/meal_session_result.dart';
import 'package:jy_yamyam/models/reward_item.dart';
import 'package:jy_yamyam/services/local_meal_progress_service.dart';
import 'package:jy_yamyam/widgets/vehicle_widget.dart';

void main() {
  testWidgets('Home screen shows meal timer actions', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    expect(find.text('냠냠 라이더'), findsOneWidget);
    expect(find.text('15분 아침 코스'), findsOneWidget);
    expect(find.text('25분 보통 코스'), findsOneWidget);
    expect(find.text('35분 천천히 코스'), findsOneWidget);
    expect(find.text('직접 설정으로 출발'), findsOneWidget);
  });

  testWidgets('Remaining time setting can be turned off', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.text('남은 시간 보여주기'), findsOneWidget);
    await tester.tap(find.text('남은 시간 보여주기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('25분 보통 코스'));
    await tester.pump();

    expect(find.textContaining('남은 시간'), findsNothing);
  });

  testWidgets('Home screen shows vehicle choices above courses', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    expect(find.text('빠방 고르기'), findsOneWidget);
    expect(find.text('🏍️'), findsOneWidget);
    expect(find.text('오토바이'), findsOneWidget);
    expect(find.text('🚒'), findsOneWidget);
    expect(find.text('소방차'), findsOneWidget);
    expect(find.text('🚓'), findsOneWidget);
    expect(find.text('경찰차'), findsOneWidget);
    expect(find.text('🚜'), findsOneWidget);
    expect(find.text('포크레인'), findsOneWidget);

    final vehicleTitleTop = tester.getTopLeft(find.text('빠방 고르기')).dy;
    final firstCourseTop = tester.getTopLeft(find.text('15분 아침 코스')).dy;
    expect(vehicleTitleTop, lessThan(firstCourseTop));
  });

  testWidgets('Selected vehicle on home is saved to preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(
      find.ancestor(of: find.text('경찰차'), matching: find.byType(ChoiceChip)),
    );
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('motorcycleId'), 'police_car');
  });

  testWidgets('Vehicle widget falls back to emoji for missing assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: VehicleWidget(vehicle: VehicleCatalog.fireTruck)),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('🚒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English locale shows English home copy', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('en'));

    expect(find.text('Yamyam Rider'), findsOneWidget);
    expect(find.text('15-min Morning Ride'), findsOneWidget);
    expect(find.text('25-min Regular Ride'), findsOneWidget);
    expect(find.text('35-min Easy Ride'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Start Custom Ride'), findsOneWidget);
  });

  testWidgets('Unsupported locale falls back to English', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ja'));

    expect(find.text('Yamyam Rider'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Start Custom Ride'), findsOneWidget);
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

  test('Completed overtime meal awards a random sticker', () async {
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

    expect(recordedSession.awardedRewards, hasLength(1));
  });

  test('Incomplete meal does not award stickers', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    final recordedSession = await service.recordMealResult(
      MealSessionResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 25),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeArrival: false,
        mealCompleted: false,
      ),
    );

    expect(recordedSession.awardedRewards, isEmpty);
  });
}

Future<void> _startApp(WidgetTester tester, Locale locale) async {
  tester.binding.platformDispatcher.localeTestValue = locale;
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await app.main();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
}
