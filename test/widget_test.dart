import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jy_yamyam/catalogs/vehicle_catalog.dart';
import 'package:jy_yamyam/main.dart' as app;
import 'package:jy_yamyam/models/meal_session_result.dart';
import 'package:jy_yamyam/models/meal_timer_config.dart';
import 'package:jy_yamyam/models/reward_item.dart';
import 'package:jy_yamyam/models/vehicle.dart';
import 'package:jy_yamyam/screens/home_screen.dart';
import 'package:jy_yamyam/screens/timer_screen.dart';
import 'package:jy_yamyam/services/local_meal_progress_service.dart';
import 'package:jy_yamyam/widgets/road_painter.dart';
import 'package:jy_yamyam/widgets/road_view.dart';
import 'package:jy_yamyam/widgets/vehicle_widget.dart';

void main() {
  testWidgets('First launch asks for child name before home', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'), completeChildNameSetup: false);

    expect(find.text('누가 냠냠 라이더를 탈까?'), findsOneWidget);
    expect(find.text('이름 저장'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '민준');
    await tester.pump();
    await tester.tap(find.text('이름 저장'));
    await tester.pumpAndSettle();

    expect(find.text('냠냠 라이더'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '민준');
  });

  testWidgets('Home screen shows meal timer actions', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    expect(find.text('냠냠 라이더'), findsOneWidget);
    expect(find.text('15분 아침 코스'), findsOneWidget);
    expect(find.text('25분 보통 코스'), findsOneWidget);
    expect(find.text('35분 천천히 코스'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
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
    expect(find.text('도착까지'), findsNothing);
  });

  testWidgets('Home screen shows vehicle choices above courses', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    expect(find.text('빠방 고르기'), findsOneWidget);
    expect(find.text('오토바이'), findsNothing);
    expect(find.text('소방차'), findsNothing);
    expect(find.text('경찰차'), findsNothing);
    expect(find.text('포크레인'), findsNothing);
    expect(
      _assetImage('assets/images/vehicle_motorcycle_chip.png'),
      findsOneWidget,
    );
    expect(
      _assetImage('assets/images/vehicle_fire_truck_chip.png'),
      findsOneWidget,
    );
    expect(
      _assetImage('assets/images/vehicle_police_car_chip.png'),
      findsOneWidget,
    );
    expect(
      _assetImage('assets/images/vehicle_excavator_chip.png'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('motorcycle')).dy,
      tester.getTopLeft(_vehicleChoiceFinder('fire_truck')).dy,
    );
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('police_car')).dy,
      tester.getTopLeft(_vehicleChoiceFinder('motorcycle')).dy,
    );
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('excavator')).dy,
      tester.getTopLeft(_vehicleChoiceFinder('motorcycle')).dy,
    );
    expect(
      tester.getSize(_vehicleChoiceFinder('motorcycle')).width,
      tester.getSize(_vehicleChoiceFinder('fire_truck')).width,
    );

    final vehicleTitleTop = tester.getTopLeft(find.text('빠방 고르기')).dy;
    final firstCourseTop = tester.getTopLeft(find.text('15분 아침 코스')).dy;
    expect(vehicleTitleTop, lessThan(firstCourseTop));
  });

  testWidgets('Selected vehicle on home is saved to preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(_vehicleChoiceFinder('police_car'));
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('motorcycleId'), 'police_car');
  });

  testWidgets('Vehicle selection updates even without parent rebuild', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    MealTimerConfig? changedConfig;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          config: MealTimerConfig.defaults().copyWith(
            childName: '지율',
            motorcycleId: 'fire_truck',
          ),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );

    final selectedColor = _vehicleChoiceMaterial(tester, 'fire_truck').color;
    final unselectedColor = _vehicleChoiceMaterial(tester, 'police_car').color;
    expect(selectedColor, isNot(unselectedColor));

    await tester.tap(_vehicleChoiceFinder('police_car'));
    await tester.pump();

    expect(changedConfig?.motorcycleId, 'police_car');
    expect(_vehicleChoiceMaterial(tester, 'fire_truck').color, unselectedColor);
    expect(_vehicleChoiceMaterial(tester, 'police_car').color, selectedColor);
  });

  testWidgets('Child name can be changed in settings', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.text('아이 이름'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '서아');
    await tester.tap(find.text('이름 저장'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '서아');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('서아의 냠냠 기록'), findsOneWidget);
  });

  testWidgets('Vehicle widget falls back to emoji for missing assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleWidget(
            vehicle: VehicleDefinition(
              id: 'missing_vehicle',
              labelKo: '없는 차',
              labelEn: 'Missing vehicle',
              emoji: '🚒',
              assetPath: 'assets/images/missing_vehicle.png',
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('🚒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Road view shows winding route markers and vehicle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(progress: 0.5, vehicle: VehicleCatalog.fireTruck),
          ),
        ),
      ),
    );

    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(tester.widget<VehicleWidget>(find.byType(VehicleWidget)).angle, 0);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.restaurant_rounded), findsNothing);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);

    const roadSize = Size(420, 640);
    final roadBounds = createRoadBounds(roadSize);
    final roadSides = [
      for (var index = 0; index <= 20; index += 1)
        roadPointForProgress(roadSize, index / 20).dx < roadBounds.center.dx,
    ];
    var sideChanges = 0;
    for (var index = 1; index < roadSides.length; index += 1) {
      if (roadSides[index] != roadSides[index - 1]) {
        sideChanges += 1;
      }
    }
    expect(sideChanges, greaterThanOrEqualTo(7));
    expect(
      roadPointForProgress(roadSize, 1).dx,
      greaterThan(roadBounds.center.dx),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(progress: 0.2, vehicle: VehicleCatalog.fireTruck),
          ),
        ),
      ),
    );
    expect(
      tester.widget<VehicleWidget>(find.byType(VehicleWidget)).isFacingLeft,
      isTrue,
    );
  });

  testWidgets('English locale shows English home copy', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('en'));

    expect(find.text('Yamyam Rider'), findsOneWidget);
    expect(find.text("Today's Yamyam Mission"), findsOneWidget);
    expect(
      find.text('Your rider is waiting for a tasty finish'),
      findsOneWidget,
    );
    expect(find.text("Today's vehicle"), findsOneWidget);
    expect(find.text('15-min Morning Ride'), findsOneWidget);
    expect(find.text('A light warm-up'), findsOneWidget);
    expect(find.text('25-min Regular Ride'), findsOneWidget);
    expect(find.text('A steady mealtime mission'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('35-min Easy Ride'), findsOneWidget);
    expect(find.text('Cruise to the finish'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Start Custom Ride'), findsOneWidget);
  });

  testWidgets('English locale shows English timer progress copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: MealTimerConfig.defaults(),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Today's Yamyam Ride"), findsOneWidget);
    expect(find.text("We're off!"), findsOneWidget);
    expect(find.text('Until arrival'), findsOneWidget);
    expect(find.text('출발했어요!'), findsNothing);
  });

  testWidgets('Paused timer shows paused status copy', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: MealTimerConfig.defaults(),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Taking a little break'), findsOneWidget);
    expect(find.text('Taking a break'), findsOneWidget);
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

Future<void> _startApp(
  WidgetTester tester,
  Locale locale, {
  bool completeChildNameSetup = true,
}) async {
  tester.binding.platformDispatcher.localeTestValue = locale;
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await app.main();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
  if (!completeChildNameSetup || find.byType(TextField).evaluate().isEmpty) {
    return;
  }

  await tester.enterText(find.byType(TextField), '지율');
  await tester.pump();
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

Material _vehicleChoiceMaterial(WidgetTester tester, String vehicleId) {
  return tester.widget<Material>(_vehicleChoiceFinder(vehicleId));
}

Finder _vehicleChoiceFinder(String vehicleId) {
  return find.byKey(ValueKey('vehicleChoice.$vehicleId'));
}

Finder _assetImage(String assetName) {
  return find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName;
  });
}
