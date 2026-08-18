import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/models/activity_timer_config.dart';

import 'support/avatar_test_harness.dart';

void main() {
  testWidgets('Avatar setup screen shows guide text and prompt copy button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAvatarSetupScreen(tester, ActivityTimerConfig.defaults());
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);

    await expandAvatarPrompt(tester);
    final texts = AppTexts.ko.avatarSetup;
    expect(find.text(texts.promptHelperText), findsOneWidget);
    expect(avatarPromptText(tester), contains('Timey Rider에 사용할 라이더 이미지'));
    expect(avatarPromptText(tester), contains('새로운 캐릭터처럼 바꾸지'));
    expect(avatarPromptText(tester), contains('배경은 반드시 투명 배경'));
    expect(find.text('프롬프트 복사하기'), findsOneWidget);
  });

  testWidgets('English locale shows English avatar setup copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      locale: const Locale('en'),
    );

    expect(find.text("Create Your Child's Rider"), findsOneWidget);
    expect(find.text('우리 아이 라이더 만들기'), findsNothing);
    expect(find.text('Selected vehicle'), findsOneWidget);
    expect(find.text('Default image preview'), findsOneWidget);

    await selectCustomAvatarMode(tester);

    final texts = AppTexts.en.avatarSetup;
    await tester.dragUntilVisible(
      find.text(texts.guideTitle),
      find.byType(ListView),
      const Offset(0, -100),
    );
    expect(find.text(texts.guideTitle), findsOneWidget);

    await scrollAvatarPromptToggleIntoView(tester);
    expect(find.text(texts.promptCopyTitle), findsOneWidget);
    expect(find.text(texts.promptExpandLabel), findsNothing);
    expect(find.text(texts.copyPromptButton), findsNothing);
    expect(find.byKey(const ValueKey('avatarPromptCopyButton')), findsNothing);

    await expandAvatarPrompt(tester);
    expect(find.text('Copy prompt'), findsOneWidget);
  });

  testWidgets('Avatar setup fire truck prompt includes firefighter guidance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(vehicleId: 'fire_truck'),
    );

    await selectCustomAvatarMode(tester);
    await expandAvatarPrompt(tester);
    expect(avatarPromptText(tester), contains('소방관'));
  });

  testWidgets('Avatar setup police car prompt includes police guidance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(vehicleId: 'police_car'),
    );

    await selectCustomAvatarMode(tester);
    await expandAvatarPrompt(tester);
    expect(avatarPromptText(tester), contains('경찰'));
  });

  testWidgets('Avatar setup vehicle selection updates prompt and config', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
    );
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);
    await scrollAvatarVehicleSelectionIntoView(tester);
    expect(find.text('라이더를 태울 차량'), findsOneWidget);

    await tapVisible(tester, vehicleChoiceFinder('fire_truck'));
    await tester.pump();
    await expandAvatarPrompt(tester);

    expect(changedConfig?.vehicleId, 'fire_truck');
    expect(avatarPromptText(tester), contains('소방관'));
  });
  testWidgets('Avatar setup shows upload button in custom mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAvatarSetupScreen(tester, ActivityTimerConfig.defaults());
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);
    await scrollAvatarSetupToBottom(tester);

    expect(find.widgetWithText(FilledButton, '라이더 이미지 선택'), findsOneWidget);
    expect(
      find.textContaining('사진 앱이나 외부 AI 서비스에서 만든 정사각형 라이더 이미지를 선택해 주세요.'),
      findsOneWidget,
    );

    await scrollAvatarSetupToBottom(tester);
    expect(find.text('합성 미리보기'), findsNothing);
    expect(find.text('라이더 위치 조정'), findsNothing);
    expect(find.byKey(const ValueKey('avatarConfirmButton')), findsNothing);
  });

  testWidgets('Avatar setup picker cancellation does not update config', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      imagePicker: TestAvatarImagePicker(),
      avatarImageService: TestLocalAvatarImageService('/tmp/avatar.png'),
      onConfigChanged: (config) => changedConfig = config,
    );
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);
    await scrollAvatarSetupToBottom(tester);
    await tester.tap(find.widgetWithText(FilledButton, '라이더 이미지 선택'));
    await tester.pumpAndSettle();

    expect(changedConfig, isNull);
    expect(
      find.byKey(const ValueKey('pendingAvatarImagePreview')),
      findsNothing,
    );
  });

  testWidgets('Avatar setup successful upload shows pending preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    final avatarFile = createTemporaryAvatarImage();
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      imagePicker: TestAvatarImagePicker(
        XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          path: 'picked/avatar.png',
        ),
      ),
      avatarImageService: TestLocalAvatarImageService(avatarFile.path),
      onConfigChanged: (config) => changedConfig = config,
    );
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);
    await scrollAvatarSetupToBottom(tester);
    await tester.tap(find.widgetWithText(FilledButton, '라이더 이미지 선택'));
    await tester.pumpAndSettle();

    expect(changedConfig, isNull);
    expect(
      find.byKey(const ValueKey('pendingAvatarImagePreview')),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '다시 선택'), findsOneWidget);
    await scrollAvatarCompositeIntoView(tester);
    expect(find.text('합성 미리보기'), findsOneWidget);
    expect(find.text('이 모습으로 Timey Rider를 탈까요?'), findsOneWidget);
  });

  testWidgets('Avatar setup initializes from custom config', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final avatarFile = createTemporaryAvatarImage();
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
        customAvatarsByVehicle: {
          'motorcycle': VehicleAvatarConfig(
            imagePath: avatarFile.path,
            scale: 1.0,
            offsetX: 0.0,
            offsetY: 0.0,
            rotationDegrees: 0.0,
          ),
        },
      ),
    );
    await dismissAvatarGuideIfVisible(tester);

    await selectCustomAvatarMode(tester);
    expect(find.text('직접 만든 라이더 사용'), findsWidgets);
  });

  testWidgets('Avatar setup warns when saved custom file is missing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
        vehicleId: 'motorcycle',
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: '/missing/avatar.png',
        customAvatarVehicleId: 'motorcycle',
      ),
    );

    final texts = AppTexts.ko.avatarSetup;
    final warningFinder = find.text(texts.missingAvatarWarning);
    await tester.dragUntilVisible(
      warningFinder,
      find.byType(Scrollable).first,
      const Offset(0, -100),
    );
    expect(warningFinder, findsOneWidget);
    expect(
      find.byKey(const ValueKey('pendingAvatarImagePreview')),
      findsNothing,
    );
  });

  testWidgets('Avatar setup size slider updates local adjustment state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final avatarFile = createTemporaryAvatarImage();
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
        vehicleId: 'motorcycle',
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
      ),
    );

    await scrollAvatarAdjustmentIntoView(tester);
    expect(avatarSliderValue(tester, 'avatarScaleSlider'), 1.0);

    avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.2);
    await tester.pump();

    expect(avatarSliderValue(tester, 'avatarScaleSlider'), 1.2);
  });

  testWidgets('Avatar setup reset button resets adjustment controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final avatarFile = createTemporaryAvatarImage();
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
      ),
    );

    await scrollAvatarAdjustmentIntoView(tester);
    avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.25);
    avatarSlider(tester, 'avatarOffsetXSlider').onChanged!(0.12);
    avatarSlider(tester, 'avatarOffsetYSlider').onChanged!(0.08);
    avatarSlider(tester, 'avatarRotationSlider').onChanged!(9.0);
    await tester.pump();

    await tapVisible(tester, find.byKey(const ValueKey('avatarResetButton')));
    await tester.pump();

    expect(avatarSliderValue(tester, 'avatarScaleSlider'), 1.0);
    expect(avatarSliderValue(tester, 'avatarOffsetXSlider'), 0.0);
    expect(avatarSliderValue(tester, 'avatarOffsetYSlider'), 0.0);
    expect(avatarSliderValue(tester, 'avatarRotationSlider'), 0.0);
  });

  testWidgets('Avatar setup confirm saves custom avatar adjustment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    final avatarFile = createTemporaryAvatarImage();
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
      ),
      onConfigChanged: (config) => changedConfig = config,
    );

    await scrollAvatarAdjustmentIntoView(tester);
    avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.3);
    avatarSlider(tester, 'avatarOffsetXSlider').onChanged!(0.1);
    avatarSlider(tester, 'avatarOffsetYSlider').onChanged!(0.05);
    avatarSlider(tester, 'avatarRotationSlider').onChanged!(7.0);
    await tester.pump();

    await tapVisible(tester, find.byKey(const ValueKey('avatarConfirmButton')));
    await tester.pump();

    expect(changedConfig?.avatarMode, AvatarImageMode.custom);
    expect(changedConfig?.customAvatarImagePath, avatarFile.path);
    expect(changedConfig?.customAvatarVehicleId, 'motorcycle');
    expect(changedConfig?.avatarScale, 1.3);
    expect(changedConfig?.avatarOffsetX, 0.1);
    expect(changedConfig?.avatarOffsetY, -0.05);
    expect(changedConfig?.avatarRotationDegrees, 7.0);
    final savedAvatar = changedConfig?.customAvatarConfigForVehicle(
      'motorcycle',
    );
    expect(savedAvatar?.imagePath, avatarFile.path);
    expect(savedAvatar?.scale, 1.3);
    expect(savedAvatar?.offsetX, 0.1);
    expect(savedAvatar?.offsetY, -0.05);
    expect(savedAvatar?.rotationDegrees, 7.0);
    expect(find.text('라이더를 저장했어요.'), findsOneWidget);
  });

  testWidgets('Avatar setup default image button saves default avatar mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    final avatarFile = createTemporaryAvatarImage();
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
        avatarScale: 1.2,
        avatarOffsetX: 0.1,
        avatarOffsetY: -0.1,
        avatarRotationDegrees: 6.0,
      ),
      onConfigChanged: (config) => changedConfig = config,
    );

    await scrollAvatarAdjustmentIntoView(tester);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('avatarUseDefaultButton')),
    );
    await tester.pump();

    expect(changedConfig?.avatarMode, AvatarImageMode.defaultImage);
    expect(changedConfig?.customAvatarImagePath, isNull);
    expect(changedConfig?.customAvatarVehicleId, isNull);
    expect(changedConfig?.avatarScale, 1.0);
    expect(changedConfig?.avatarOffsetX, 0.0);
    expect(changedConfig?.avatarOffsetY, 0.0);
    expect(changedConfig?.avatarRotationDegrees, 0.0);
    expect(changedConfig?.customAvatarConfigForVehicle('motorcycle'), isNull);
    expect(find.text('기본 이미지로 변경했어요.'), findsOneWidget);
  });

  testWidgets('Avatar setup stores custom avatars per vehicle', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    ActivityTimerConfig? changedConfig;
    final busAvatarFile = createTemporaryAvatarImage();
    final fireTruckAvatarFile = createTemporaryAvatarImage();
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
        vehicleId: 'bus',
        avatarMode: AvatarImageMode.custom,
        customAvatarsByVehicle: {
          'bus': VehicleAvatarConfig(
            imagePath: busAvatarFile.path,
            scale: 1.2,
            offsetX: 0.08,
            offsetY: -0.04,
            rotationDegrees: 4.0,
          ),
          'fire_truck': VehicleAvatarConfig(
            imagePath: fireTruckAvatarFile.path,
            scale: 1.35,
            offsetX: -0.06,
            offsetY: 0.03,
            rotationDegrees: -8.0,
          ),
        },
      ),
      onConfigChanged: (config) => changedConfig = config,
    );

    await scrollAvatarAdjustmentIntoView(tester);
    expect(avatarSliderValue(tester, 'avatarScaleSlider'), 1.2);

    await scrollAvatarVehicleSelectionIntoView(tester);
    await tapVisible(tester, vehicleChoiceFinder('fire_truck'));
    await tester.pump();
    await scrollAvatarAdjustmentIntoView(tester);

    expect(avatarSliderValue(tester, 'avatarScaleSlider'), 1.35);
    avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.45);
    await tester.pump();

    await tapVisible(tester, find.byKey(const ValueKey('avatarConfirmButton')));
    await tester.pump();

    expect(
      changedConfig?.customAvatarConfigForVehicle('bus')?.imagePath,
      busAvatarFile.path,
    );
    expect(changedConfig?.customAvatarConfigForVehicle('bus')?.scale, 1.2);
    expect(
      changedConfig?.customAvatarConfigForVehicle('fire_truck')?.imagePath,
      fireTruckAvatarFile.path,
    );
    expect(
      changedConfig?.customAvatarConfigForVehicle('fire_truck')?.scale,
      1.45,
    );
  });

  testWidgets(
    'Avatar setup default image clears only selected vehicle avatar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ActivityTimerConfig? changedConfig;
      final busAvatarFile = createTemporaryAvatarImage();
      final fireTruckAvatarFile = createTemporaryAvatarImage();
      await pumpAvatarSetupScreen(
        tester,
        ActivityTimerConfig.defaults().copyWith(
          vehicleId: 'fire_truck',
          avatarMode: AvatarImageMode.custom,
          customAvatarsByVehicle: {
            'bus': VehicleAvatarConfig(
              imagePath: busAvatarFile.path,
              scale: 1.2,
              offsetX: 0.08,
              offsetY: -0.04,
              rotationDegrees: 4.0,
            ),
            'fire_truck': VehicleAvatarConfig(
              imagePath: fireTruckAvatarFile.path,
              scale: 1.35,
              offsetX: -0.06,
              offsetY: 0.03,
              rotationDegrees: -8.0,
            ),
          },
        ),
        onConfigChanged: (config) => changedConfig = config,
      );

      await scrollAvatarAdjustmentIntoView(tester);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('avatarUseDefaultButton')),
      );
      await tester.pump();

      expect(
        changedConfig?.customAvatarConfigForVehicle('bus')?.imagePath,
        busAvatarFile.path,
      );
      expect(changedConfig?.customAvatarConfigForVehicle('fire_truck'), isNull);
      expect(changedConfig?.avatarMode, AvatarImageMode.custom);
    },
  );

  testWidgets('Avatar setup default mode save keeps default avatar mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
    );

    expect(find.text('기본 이미지 미리보기'), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('avatarUseDefaultButton')),
    );
    await tester.pump();

    expect(changedConfig?.avatarMode, AvatarImageMode.defaultImage);
    expect(find.text('기본 이미지로 변경했어요.'), findsOneWidget);
  });

  testWidgets('Avatar setup confirm without image is disabled and safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityTimerConfig? changedConfig;
    await pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
    );

    await selectCustomAvatarMode(tester);

    expect(find.byKey(const ValueKey('avatarConfirmButton')), findsNothing);
    expect(changedConfig, isNull);
    expect(tester.takeException(), isNull);
  });
}
