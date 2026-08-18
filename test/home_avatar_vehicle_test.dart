import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/widgets/avatar/avatar_composite_preview.dart';

import 'support/app_test_harness.dart';
import 'support/avatar_test_harness.dart';

void main() {
  testWidgets('Home screen vehicle sections render confirmed custom avatar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final avatarFile = createTemporaryAvatarImage();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            childName: '지율',
            avatarMode: AvatarImageMode.custom,
            customAvatarsByVehicle: {
              'motorcycle': VehicleAvatarConfig(
                imagePath: avatarFile.path,
                scale: 1.25,
                offsetX: 0.07,
                offsetY: -0.03,
                rotationDegrees: 5.0,
              ),
            },
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          avatarImageBuilder: (context, imagePath) {
            return const ColoredBox(
              key: ValueKey('avatarCompositeOverlayImage'),
              color: Colors.pink,
            );
          },
        ),
      ),
    );
    await pumpHomeAvatarFileCheck(tester);

    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.text('오늘의 빠방'), findsOneWidget);
    expect(find.text('아이 얼굴 탑승 중'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsOneWidget,
    );
    final customAvatarPreview = find.byWidgetPredicate((widget) {
      return widget is AvatarCompositePreview &&
          widget.avatarScale == 1.25 &&
          widget.avatarOffsetX == 0.07 &&
          widget.avatarOffsetY == -0.03 &&
          widget.avatarRotationDegrees == 5.0;
    });
    expect(customAvatarPreview, findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets(
    'Home screen falls back to default avatar state when file is missing',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: HomeScreen(
            config: ActivityTimerConfig.defaults().copyWith(
              childName: '지율',
              avatarMode: AvatarImageMode.custom,
              customAvatarImagePath: '/missing/avatar.png',
              customAvatarVehicleId: 'motorcycle',
            ),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
          ),
        ),
      );
      await pumpHomeAvatarFileCheck(tester);

      expect(find.text('기본 얼굴 사용 중'), findsOneWidget);
      expect(find.text('만들기'), findsOneWidget);
      expect(find.text('아이 얼굴 탑승 중'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());

      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets('Home screen shows saved avatar only on its vehicle choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });
    final avatarFile = createTemporaryAvatarImage();
    ActivityTimerConfig? changedConfig;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            childName: '지율',
            vehicleId: 'excavator',
            avatarMode: AvatarImageMode.custom,
            customAvatarImagePath: avatarFile.path,
            customAvatarVehicleId: 'police_car',
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (config) => changedConfig = config,
          avatarImageBuilder: (context, imagePath) {
            return const ColoredBox(
              key: ValueKey('avatarCompositeOverlayImage'),
              color: Colors.pink,
            );
          },
        ),
      ),
    );
    await pumpHomeAvatarFileCheck(tester);

    expect(find.text('기본 얼굴 사용 중'), findsOneWidget);
    expect(find.text('아이 얼굴 탑승 중'), findsNothing);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate((widget) {
        return widget is AvatarCompositePreview &&
            widget.vehicle.id == 'excavator' &&
            widget.avatarMode == AvatarImageMode.custom;
      }),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();

    expect(find.text('빠방 고르기'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsOneWidget,
    );

    await tester.dragUntilVisible(
      vehicleChoiceFinder('police_car'),
      find.byType(Scrollable).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(vehicleChoiceFinder('police_car'));
    await tester.pumpAndSettle();
    await pumpHomeAvatarFileCheck(tester);

    expect(changedConfig?.vehicleId, 'police_car');
    expect(find.text('아이 얼굴 탑승 중'), findsOneWidget);
    expect(find.text('기본 얼굴 사용 중'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });

  testWidgets('Home avatar CTA opens avatar setup screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    await startTestApp(tester, const Locale('ko'));

    await tester.ensureVisible(find.text('만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    await dismissAvatarGuideIfVisible(tester);

    expect(find.text('우리 아이 라이더 만들기'), findsOneWidget);
    expect(
      find.text('Timey Rider에 사용할 아이 라이더 이미지를 만든 뒤 선택해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('기본 이미지 미리보기'), findsOneWidget);

    await selectCustomAvatarMode(tester);

    await scrollAvatarPromptToggleIntoView(tester);
    expect(find.text('라이더 이미지 만들기 가이드'), findsOneWidget);
    expect(find.text('라이더 이미지 프롬프트 (예시)'), findsOneWidget);
    expect(find.byKey(const ValueKey('avatarPromptText')), findsNothing);
    expect(find.text('프롬프트 복사하기'), findsNothing);
  });
}
