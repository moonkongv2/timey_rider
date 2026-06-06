import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jy_yamyam/catalogs/avatar_prompt_catalog.dart';
import 'package:jy_yamyam/catalogs/motivation_asset_catalog.dart';
import 'package:jy_yamyam/catalogs/vehicle_catalog.dart';
import 'package:jy_yamyam/l10n/app_texts.dart';
import 'package:jy_yamyam/main.dart' as app;
import 'package:jy_yamyam/models/meal_completion_status.dart';
import 'package:jy_yamyam/models/meal_session_result.dart';
import 'package:jy_yamyam/models/meal_timer_config.dart';
import 'package:jy_yamyam/models/reward_goal.dart';
import 'package:jy_yamyam/models/vehicle.dart';
import 'package:jy_yamyam/models/vehicle_avatar_presentation.dart';
import 'package:jy_yamyam/screens/avatar_setup_screen.dart';
import 'package:jy_yamyam/screens/home_screen.dart';
import 'package:jy_yamyam/screens/meal_history_screen.dart';
import 'package:jy_yamyam/screens/reward_goal_screen.dart';
import 'package:jy_yamyam/screens/result_screen.dart';
import 'package:jy_yamyam/screens/settings_screen.dart';
import 'package:jy_yamyam/screens/timer_screen.dart';
import 'package:jy_yamyam/services/avatar_image_picker.dart';
import 'package:jy_yamyam/services/local_avatar_image_service.dart';
import 'package:jy_yamyam/services/local_meal_progress_service.dart';
import 'package:jy_yamyam/services/local_settings_service.dart';
import 'package:jy_yamyam/services/motivation_audio_service.dart';
import 'package:jy_yamyam/services/orientation_service.dart';
import 'package:jy_yamyam/services/screen_awake_service.dart';
import 'package:jy_yamyam/widgets/app/app_bouncy_button.dart';
import 'package:jy_yamyam/widgets/avatar/avatar_composite_preview.dart';
import 'package:jy_yamyam/widgets/road_painter.dart';
import 'package:jy_yamyam/widgets/road_view.dart';
import 'package:jy_yamyam/widgets/timer_control_bar.dart';
import 'package:jy_yamyam/widgets/vehicle_selection_card.dart';
import 'package:jy_yamyam/widgets/vehicle_widget.dart';

void main() {
  test('Default config uses default avatar image settings', () {
    final config = MealTimerConfig.defaults();

    expect(config.avatarMode, AvatarImageMode.defaultImage);
    expect(config.customAvatarImagePath, isNull);
    expect(config.customAvatarVehicleId, isNull);
    expect(config.vehicleId, 'motorcycle');
    expect(config.avatarScale, 1.0);
    expect(config.avatarOffsetX, 0.0);
    expect(config.avatarOffsetY, 0.0);
    expect(config.avatarRotationDegrees, 0.0);
    expect(config.customAvatarsByVehicle, isEmpty);
  });

  test('Local settings saves and loads avatar settings', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveConfig(
      MealTimerConfig.defaults().copyWith(
        childName: '지율',
        vehicleId: 'police_car',
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: '/local/avatar.png',
        customAvatarVehicleId: 'police_car',
        avatarScale: 1.25,
        avatarOffsetX: 8.0,
        avatarOffsetY: -6.0,
        avatarRotationDegrees: 12.0,
      ),
    );

    final loadedConfig = await service.loadConfig();
    final preferences = await SharedPreferences.getInstance();
    expect(loadedConfig.childName, '지율');
    expect(loadedConfig.vehicleId, 'police_car');
    expect(preferences.getString('vehicleId'), 'police_car');
    expect(loadedConfig.avatarMode, AvatarImageMode.custom);
    expect(loadedConfig.customAvatarImagePath, '/local/avatar.png');
    expect(loadedConfig.customAvatarVehicleId, 'police_car');
    expect(loadedConfig.avatarScale, 1.25);
    expect(loadedConfig.avatarOffsetX, 8.0);
    expect(loadedConfig.avatarOffsetY, -6.0);
    expect(loadedConfig.avatarRotationDegrees, 12.0);
    final policeCarAvatar = loadedConfig.customAvatarConfigForVehicle(
      'police_car',
    );
    expect(policeCarAvatar?.imagePath, '/local/avatar.png');
    expect(policeCarAvatar?.scale, 1.25);
    expect(policeCarAvatar?.offsetX, 8.0);
    expect(policeCarAvatar?.offsetY, -6.0);
    expect(policeCarAvatar?.rotationDegrees, 12.0);
  });

  test('Local settings saves and loads vehicle avatar maps', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveConfig(
      MealTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        vehicleId: 'bus',
        customAvatarsByVehicle: const {
          'bus': VehicleAvatarConfig(
            imagePath: '/local/bus.png',
            scale: 1.1,
            offsetX: 0.05,
            offsetY: -0.02,
            rotationDegrees: 3.0,
          ),
          'train': VehicleAvatarConfig(
            imagePath: '/local/train.png',
            scale: 1.2,
            offsetX: -0.04,
            offsetY: 0.03,
            rotationDegrees: -5.0,
          ),
        },
      ),
    );

    final loadedConfig = await service.loadConfig();
    expect(
      loadedConfig.customAvatarsByVehicle.keys,
      containsAll(['bus', 'train']),
    );
    expect(
      loadedConfig.customAvatarConfigForVehicle('bus')?.imagePath,
      '/local/bus.png',
    );
    expect(
      loadedConfig.customAvatarConfigForVehicle('train')?.rotationDegrees,
      -5.0,
    );
    expect(loadedConfig.customAvatarImagePath, '/local/bus.png');
    expect(loadedConfig.customAvatarVehicleId, 'bus');
  });

  test('Custom avatar image path can be cleared to null', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveConfig(
      MealTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: '/local/avatar.png',
      ),
    );
    await service.saveConfig(
      MealTimerConfig.defaults().copyWith(customAvatarImagePath: null),
    );

    final loadedConfig = await service.loadConfig();
    final preferences = await SharedPreferences.getInstance();
    expect(loadedConfig.customAvatarImagePath, isNull);
    expect(preferences.getString('customAvatarImagePath'), isNull);
  });

  test(
    'Existing child name and vehicle settings load without avatar keys',
    () async {
      SharedPreferences.setMockInitialValues({
        'vehicleId': 'bus',
        'childName': '민준',
      });

      final config = await LocalSettingsService().loadConfig();

      expect(config.childName, '민준');
      expect(config.vehicleId, 'bus');
      expect(config.avatarMode, AvatarImageMode.defaultImage);
      expect(config.customAvatarImagePath, isNull);
      expect(config.customAvatarVehicleId, isNull);
    },
  );

  test(
    'Existing custom avatar settings infer vehicle id when missing',
    () async {
      SharedPreferences.setMockInitialValues({
        'vehicleId': 'police_car',
        'avatarMode': 'custom',
        'customAvatarImagePath': '/local/avatar.png',
      });

      final config = await LocalSettingsService().loadConfig();

      expect(config.avatarMode, AvatarImageMode.custom);
      expect(config.customAvatarImagePath, '/local/avatar.png');
      expect(config.customAvatarVehicleId, 'police_car');
      expect(
        config.customAvatarConfigForVehicle('police_car')?.imagePath,
        '/local/avatar.png',
      );
    },
  );

  test(
    'Malformed vehicle avatar map falls back to legacy avatar keys',
    () async {
      SharedPreferences.setMockInitialValues({
        'vehicleId': 'fire_truck',
        'avatarMode': 'custom',
        'customAvatarImagePath': '/local/fire-truck.png',
        'customAvatarVehicleId': 'fire_truck',
        'customAvatarsByVehicle': '{not-json',
      });

      final config = await LocalSettingsService().loadConfig();

      expect(config.customAvatarsByVehicle.keys, contains('fire_truck'));
      expect(
        config.customAvatarConfigForVehicle('fire_truck')?.imagePath,
        '/local/fire-truck.png',
      );
    },
  );

  test('Every catalog vehicle defines an avatar slot', () {
    for (final vehicle in VehicleCatalog.all) {
      expect(vehicle.avatarSlot, isNotNull, reason: vehicle.id);
    }
  });

  test(
    'Catalog vehicles use success result videos or the motorcycle fallback',
    () {
      const vehiclesWithResultVideos = {
        'motorcycle',
        'fire_truck',
        'police_car',
        'excavator',
        'airplane',
        'bus',
        'supercar',
        'train',
        't_rex',
        'shark',
        'brachio',
        'pteranodon',
      };

      for (final vehicle in VehicleCatalog.all) {
        final successPath = resultVideoAssetPathForVehicle(
          vehicleId: vehicle.id,
        );

        final expectedSuccessPath =
            vehiclesWithResultVideos.contains(vehicle.id)
            ? 'assets/videos/result_${vehicle.id}_success.mp4'
            : 'assets/videos/result_motorcycle_success.mp4';

        expect(successPath, expectedSuccessPath, reason: vehicle.id);
        expect(File(successPath).existsSync(), isTrue, reason: successPath);
      }
    },
  );

  testWidgets('Failed result screen skips the intro video', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalMealProgressService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          result: _mealResult(mealCompleted: false),
          config: MealTimerConfig.defaults(),
          mealProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아쉽지만 조금 늦었어'), findsOneWidget);
    expect(find.text('오토바이가 먼저 지나갔어.'), findsOneWidget);

    final snapshot = await service.loadSnapshot();
    expect(snapshot.history, hasLength(1));
    expect(snapshot.history.single.mealCompleted, isFalse);
    expect(
      snapshot.history.single.completionStatus,
      MealCompletionStatus.notCompleted,
    );
  });

  test('Result intro video contains in landscape and covers in portrait', () {
    expect(resultIntroMediaFitForSize(const Size(844, 390)), BoxFit.contain);
    expect(resultIntroMediaFitForSize(const Size(390, 844)), BoxFit.cover);
  });

  test('Motivation asset catalog has vehicle video files', () {
    const vehiclesWithMotivationVideos = {
      'motorcycle',
      'fire_truck',
      'police_car',
      'excavator',
      'airplane',
      'bus',
      'supercar',
      'train',
      't_rex',
      'shark',
      'brachio',
      'pteranodon',
    };

    expect(
      MotivationAssetCatalog.vehicleVideoIds,
      unorderedEquals(vehiclesWithMotivationVideos),
    );
    for (final vehicleId in MotivationAssetCatalog.vehicleVideoIds) {
      for (final path in MotivationAssetCatalog.videoPathsForVehicle(
        vehicleId,
      )) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
    expect(File(MotivationAssetCatalog.fallbackVideoPath).existsSync(), isTrue);
  });

  test('Motivation asset catalog falls back for missing vehicle videos', () {
    const fallbackPath = MotivationAssetCatalog.fallbackVideoPath;

    expect(
      motivationVideoAssetPathForVehicle(
        vehicleId: 'fire_truck',
        milestone: 20,
      ),
      'assets/videos/motivation/motivation_fire_truck_1.mp4',
    );
    expect(
      motivationVideoAssetPathForVehicle(vehicleId: 'airplane', milestone: 10),
      'assets/videos/motivation/motivation_airplane_1.mp4',
    );
    expect(
      motivationVideoAssetPathForVehicle(vehicleId: 'brachio', milestone: 10),
      'assets/videos/motivation/motivation_brachio_1.mp4',
    );
    expect(
      motivationVideoAssetPathForVehicle(
        vehicleId: 'missing_vehicle',
        milestone: 10,
      ),
      fallbackPath,
    );
    expect(
      motivationVideoAssetPathForVehicle(
        vehicleId: 'motorcycle',
        milestone: 95,
      ),
      isNull,
    );
    expect(File(fallbackPath).existsSync(), isTrue, reason: fallbackPath);
  });

  test('Motivation video selection can pick a vehicle candidate by index', () {
    expect(
      motivationVideoAssetPathForVehicle(
        vehicleId: 'motorcycle',
        milestone: 10,
        nextInt: (_) => 2,
      ),
      'assets/videos/motivation/motivation_motorcycle_3.mp4',
    );
    expect(
      motivationVideoAssetPathForVehicle(
        vehicleId: 'pteranodon',
        milestone: 10,
        nextInt: (_) => 1,
      ),
      'assets/videos/motivation/motivation_pteranodon_2.mp4',
    );
    expect(
      motivationVideoAssetPathForVehicle(
        vehicleId: 'missing_vehicle',
        milestone: 10,
        nextInt: (_) => 4,
      ),
      MotivationAssetCatalog.fallbackVideoPath,
    );
  });

  test('Motivation asset catalog has locale voice files', () {
    final koVoicePaths = MotivationAssetCatalog.voicePathsForLanguage('ko');
    final enVoicePaths = MotivationAssetCatalog.voicePathsForLanguage('en');

    expect(koVoicePaths, hasLength(22));
    expect(koVoicePaths.first, 'assets/audio/motivation/ko_1.mp3');
    expect(koVoicePaths.last, 'assets/audio/motivation/ko_22.mp3');
    expect(enVoicePaths, hasLength(24));
    expect(enVoicePaths.first, 'assets/audio/motivation/en_1.mp3');
    expect(enVoicePaths.last, 'assets/audio/motivation/en_24.mp3');
    expect(MotivationAssetCatalog.voicePathsForLanguage('ja'), enVoicePaths);

    for (final languageCode in const ['ko', 'en']) {
      for (final path in MotivationAssetCatalog.voicePathsForLanguage(
        languageCode,
      )) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('Motivation voice selection follows sound and locale settings', () {
    expect(
      motivationVoiceAssetPathForVehicle(
        soundEnabled: false,
        vehicleId: 'motorcycle',
        languageCode: 'ko',
        nextInt: (_) => 1,
      ),
      isNull,
    );
    expect(
      motivationVoiceAssetPathForVehicle(
        soundEnabled: true,
        vehicleId: 'motorcycle',
        languageCode: 'ko',
        nextInt: (_) => 1,
      ),
      'assets/audio/motivation/ko_2.mp3',
    );
    expect(
      motivationVoiceAssetPathForVehicle(
        soundEnabled: true,
        vehicleId: 'shark',
        languageCode: 'en',
        nextInt: (_) => 0,
      ),
      'assets/audio/motivation/en_1.mp3',
    );
    expect(
      motivationVoiceAssetPathForVehicle(
        soundEnabled: true,
        vehicleId: 'shark',
        languageCode: 'ja',
        nextInt: (_) => 23,
      ),
      'assets/audio/motivation/en_24.mp3',
    );
  });

  test('Motivation milestone selection keeps the first crossed milestone', () {
    expect(nextMotivationMilestoneForProgress(0.09, {}), isNull);
    expect(nextMotivationMilestoneForProgress(0.10, {}), 10);
    expect(nextMotivationMilestoneForProgress(0.24, {}), 10);
    expect(nextMotivationMilestoneForProgress(0.24, {10}), 20);
    expect(nextMotivationMilestoneForProgress(1.0, {}), isNull);
  });

  test('Motivation video interval requires at least 10 seconds', () {
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 9),
        lastShownAt: null,
      ),
      isFalse,
    );
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 10),
        lastShownAt: null,
      ),
      isTrue,
    );
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 15),
        lastShownAt: const Duration(seconds: 6),
      ),
      isFalse,
    );
    expect(
      canShowMotivationVideoAt(
        elapsed: const Duration(seconds: 16),
        lastShownAt: const Duration(seconds: 6),
      ),
      isTrue,
    );
  });

  test('Arrival dialog copy uses the selected vehicle label', () {
    final timerTexts = AppTexts.ko.timer;

    expect(timerTexts.arrivalDialogMessage('경찰차'), '경찰차가 지나갔어. 식사를 마무리했어?');
    expect(timerTexts.arrivalDialogMessage('포크레인'), '포크레인이 지나갔어. 식사를 마무리했어?');
  });

  test('Timer arrival dialog copy uses the configured vehicle', () {
    expect(
      timerArrivalDialogMessage(
        texts: AppTexts.ko.timer,
        vehicleId: 'excavator',
        languageCode: 'ko',
      ),
      '포크레인이 지나갔어. 식사를 마무리했어?',
    );
    expect(
      timerArrivalDialogMessage(
        texts: AppTexts.en.timer,
        vehicleId: 'police_car',
        languageCode: 'en',
      ),
      'The police car passed by... did you finish your meal?',
    );
  });

  test('Avatar prompt catalog returns prompts for every vehicle', () {
    for (final vehicle in VehicleCatalog.all) {
      final prompt = AvatarPromptCatalog.promptForVehicle(vehicle, 'ko');

      expect(prompt.trim(), isNotEmpty, reason: vehicle.id);
      expect(prompt, contains('첨부한 아이 사진을 참고'));
      expect(prompt, contains('아이의 주요 얼굴 특징은 유지'));
      expect(prompt, contains('정사각형 1:1 헤드샷'));
      expect(prompt, contains('텍스트, 로고, 워터마크 금지'));
    }
  });

  test('Avatar prompt catalog includes vehicle-specific Korean guidance', () {
    final motorcyclePrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.motorcycle,
      'ko',
    );
    final fireTruckPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.fireTruck,
      'ko',
    );
    final policeCarPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.policeCar,
      'ko',
    );
    final excavatorPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.excavator,
      'ko',
    );
    final airplanePrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.airplane,
      'ko',
    );
    final busPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.bus,
      'ko',
    );
    final supercarPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.supercar,
      'ko',
    );
    final trainPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.train,
      'ko',
    );
    final brachioPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.brachio,
      'ko',
    );
    final pteranodonPrompt = AvatarPromptCatalog.promptForVehicle(
      VehicleCatalog.pteranodon,
      'ko',
    );

    expect(
      motorcyclePrompt.contains('오토바이') || motorcyclePrompt.contains('라이더'),
      isTrue,
    );
    expect(fireTruckPrompt, contains('소방관'));
    expect(policeCarPrompt, contains('경찰'));
    expect(
      excavatorPrompt.contains('안전모') || excavatorPrompt.contains('포크레인'),
      isTrue,
    );
    expect(airplanePrompt, contains('조종사'));
    expect(busPrompt, contains('버스 기사'));
    expect(supercarPrompt, contains('레이서'));
    expect(trainPrompt, contains('기관사'));
    expect(brachioPrompt, contains('브라키오'));
    expect(pteranodonPrompt, contains('프테라노돈'));
  });

  testWidgets('First launch asks for child name before home', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'), completeChildNameSetup: false);

    expect(find.text('누가 냠냠 라이더를 탈까?'), findsOneWidget);
    expect(find.text('이름 저장'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '민준');
    await tester.pump();
    await tester.tap(find.text('이름 저장'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '민준');
  });

  testWidgets('Home screen shows meal timer actions', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.text('기본 얼굴 사용 중'), findsOneWidget);
    expect(find.text('만들기'), findsOneWidget);
    expect(find.text('다른 코스'), findsOneWidget);
    expect(find.text('15분 코스'), findsOneWidget);
    expect(find.textContaining('25분 보통 코스'), findsOneWidget);
    expect(find.text('35분 코스'), findsOneWidget);
    expect(find.textContaining('직접 설정'), findsOneWidget);
  });

  testWidgets('Home regular course uses saved default meal duration', (
    tester,
  ) async {
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
          config: MealTimerConfig.defaults().copyWith(
            childName: '지율',
            duration: const Duration(minutes: 35),
          ),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('35분 보통 코스'), findsOneWidget);

    final regularCourseButton = tester.widget<AppBouncyButton>(
      find.ancestor(
        of: find.textContaining('35분 보통 코스'),
        matching: find.byType(AppBouncyButton),
      ),
    );
    regularCourseButton.onPressed!();
    expect(tester.takeException(), isNull);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
      const Duration(minutes: 35),
    );
  });

  testWidgets('Alternate courses exclude the selected default duration', (
    tester,
  ) async {
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
          config: MealTimerConfig.defaults().copyWith(
            childName: '지율',
            duration: const Duration(minutes: 15),
          ),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('15분 보통 코스'), findsOneWidget);
    expect(find.text('15분 코스'), findsNothing);
    expect(find.text('25분 코스'), findsOneWidget);
    expect(find.text('35분 코스'), findsOneWidget);
  });

  testWidgets('Quick courses do not overwrite default meal duration', (
    tester,
  ) async {
    MealTimerConfig? changedConfig;

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
          config: MealTimerConfig.defaults().copyWith(
            childName: '지율',
            duration: const Duration(minutes: 35),
          ),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );
    await tester.pump();

    final quickCourseButton = tester.widget<InkWell>(
      find
          .ancestor(of: find.text('25분 코스'), matching: find.byType(InkWell))
          .first,
    );
    quickCourseButton.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
      const Duration(minutes: 25),
    );
    expect(changedConfig, isNull);
  });

  testWidgets('Home screen vehicle sections render confirmed custom avatar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final avatarFile = _createTemporaryAvatarImage();

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
          config: MealTimerConfig.defaults().copyWith(
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
          mealProgressService: LocalMealProgressService(),
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
    await tester.pump();

    expect(find.text('오늘의 냠냠 미션'), findsOneWidget);
    expect(find.text('오늘의 빠방'), findsOneWidget);
    expect(find.text('아이 얼굴 탑승 중'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsNWidgets(3),
    );
    final customAvatarPreview = find.byWidgetPredicate((widget) {
      return widget is AvatarCompositePreview &&
          widget.avatarScale == 1.25 &&
          widget.avatarOffsetX == 0.07 &&
          widget.avatarOffsetY == -0.03 &&
          widget.avatarRotationDegrees == 5.0;
    });
    expect(customAvatarPreview, findsNWidgets(3));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Home screen shows saved avatar only on its vehicle choice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final avatarFile = _createTemporaryAvatarImage();

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
          config: MealTimerConfig.defaults().copyWith(
            childName: '지율',
            vehicleId: 'excavator',
            avatarMode: AvatarImageMode.custom,
            customAvatarImagePath: avatarFile.path,
            customAvatarVehicleId: 'police_car',
          ),
          mealProgressService: LocalMealProgressService(),
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
    await tester.pump();

    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) {
        return widget is AvatarCompositePreview &&
            widget.vehicle.id == 'excavator' &&
            widget.avatarMode == AvatarImageMode.custom;
      }),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Home avatar CTA opens avatar setup screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.ensureVisible(find.text('만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();

    expect(find.text('우리 아이 아바타 만들기'), findsOneWidget);
    expect(
      find.text('외부 AI 서비스에서 아이 사진을 귀여운 라이더 캐릭터로 만든 뒤 업로드해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('기본 이미지 미리보기'), findsOneWidget);

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();

    await _scrollAvatarPromptIntoView(tester);
    expect(find.text('이미지 생성 가이드'), findsOneWidget);
    expect(find.text('프롬프트 복사'), findsOneWidget);
    expect(find.text('프롬프트 복사하기'), findsOneWidget);
  });

  testWidgets('Avatar setup screen shows guide text and prompt copy button', (
    tester,
  ) async {
    await _pumpAvatarSetupScreen(tester, MealTimerConfig.defaults());

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();

    await _scrollAvatarPromptIntoView(tester);
    expect(find.text('아이 얼굴이 잘 보이는 정면 사진을 사용해 주세요.'), findsOneWidget);
    expect(find.text('얼굴이 크고 선명할수록 좋아요.'), findsOneWidget);
    expect(find.text('텍스트, 로고, 워터마크는 없어야 해요.'), findsOneWidget);
    expect(_avatarPromptText(tester), contains('첨부한 아이 사진을 참고'));
    expect(_avatarPromptText(tester), contains('정사각형 1:1 헤드샷'));
    expect(find.text('프롬프트 복사하기'), findsOneWidget);
  });

  testWidgets('English locale shows English avatar setup copy', (tester) async {
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults(),
      locale: const Locale('en'),
    );

    expect(find.text("Create Your Child's Avatar"), findsOneWidget);
    expect(find.text('우리 아이 아바타 만들기'), findsNothing);
    expect(find.text('Selected vehicle'), findsOneWidget);
    expect(find.text('Default image preview'), findsOneWidget);

    await tester.tap(find.text('Use custom avatar'));
    await tester.pump();

    await _scrollAvatarPromptIntoView(tester);
    expect(find.text('Image generation guide'), findsOneWidget);
    expect(find.text('Copy prompt'), findsWidgets);
    expect(find.text('프롬프트 복사'), findsNothing);
  });

  testWidgets('Avatar setup fire truck prompt includes firefighter guidance', (
    tester,
  ) async {
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(vehicleId: 'fire_truck'),
    );

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();
    await _scrollAvatarPromptIntoView(tester);
    expect(_avatarPromptText(tester), contains('소방관'));
  });

  testWidgets('Avatar setup police car prompt includes police guidance', (
    tester,
  ) async {
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(vehicleId: 'police_car'),
    );

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();
    await _scrollAvatarPromptIntoView(tester);
    expect(_avatarPromptText(tester), contains('경찰'));
  });

  testWidgets('Avatar setup vehicle selection updates prompt and config', (
    tester,
  ) async {
    MealTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
    );

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();
    await _scrollAvatarVehicleSelectionIntoView(tester);
    expect(find.text('아바타를 태울 차량'), findsOneWidget);

    await _tapVisible(tester, _vehicleChoiceFinder('fire_truck'));
    await tester.pump();
    await _scrollAvatarPromptIntoView(tester);

    expect(changedConfig?.vehicleId, 'fire_truck');
    expect(_avatarPromptText(tester), contains('소방관'));
  });

  testWidgets('Avatar setup shows upload button in custom mode', (
    tester,
  ) async {
    await _pumpAvatarSetupScreen(tester, MealTimerConfig.defaults());

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, '아바타 이미지 업로드'), findsOneWidget);
    expect(
      find.textContaining('생성형 AI에서 만든 정사각형 아바타 이미지를 업로드해 주세요.'),
      findsOneWidget,
    );
  });

  testWidgets('Avatar setup picker cancellation does not update config', (
    tester,
  ) async {
    MealTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults(),
      imagePicker: _FakeAvatarImagePicker(),
      avatarImageService: _FakeLocalAvatarImageService('/tmp/avatar.png'),
      onConfigChanged: (config) => changedConfig = config,
    );

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '아바타 이미지 업로드'));
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
    MealTimerConfig? changedConfig;
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults(),
      imagePicker: _FakeAvatarImagePicker(
        XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          path: 'picked/avatar.png',
        ),
      ),
      avatarImageService: _FakeLocalAvatarImageService(avatarFile.path),
      onConfigChanged: (config) => changedConfig = config,
    );

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '아바타 이미지 업로드'));
    await tester.pumpAndSettle();

    expect(changedConfig, isNull);
    expect(
      find.byKey(const ValueKey('pendingAvatarImagePreview')),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '다시 업로드'), findsOneWidget);
    await _scrollAvatarCompositeIntoView(tester);
    expect(find.text('합성 미리보기'), findsOneWidget);
    expect(find.text('이 모습으로 냠냠라이더를 탈까요?'), findsOneWidget);
  });

  testWidgets('Avatar setup initializes from custom config', (tester) async {
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
      ),
    );

    expect(find.text('직접 만든 아바타 사용'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '다시 업로드'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pendingAvatarImagePreview')),
      findsOneWidget,
    );
    await _scrollAvatarCompositeIntoView(tester);
    expect(find.text('합성 미리보기'), findsOneWidget);
  });

  testWidgets('Avatar setup warns when saved custom file is missing', (
    tester,
  ) async {
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: '/missing/avatar.png',
        customAvatarVehicleId: 'motorcycle',
      ),
    );

    expect(find.text('아바타 이미지를 찾을 수 없어 기본 이미지로 보여드려요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pendingAvatarImagePreview')),
      findsNothing,
    );
  });

  testWidgets('Avatar setup size slider updates local adjustment state', (
    tester,
  ) async {
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
      ),
    );

    await _scrollAvatarAdjustmentIntoView(tester);
    expect(_avatarSliderValue(tester, 'avatarScaleSlider'), 1.0);

    _avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.2);
    await tester.pump();

    expect(_avatarSliderValue(tester, 'avatarScaleSlider'), 1.2);
  });

  testWidgets('Avatar setup reset button resets adjustment controls', (
    tester,
  ) async {
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
      ),
    );

    await _scrollAvatarAdjustmentIntoView(tester);
    _avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.25);
    _avatarSlider(tester, 'avatarOffsetXSlider').onChanged!(0.12);
    _avatarSlider(tester, 'avatarOffsetYSlider').onChanged!(-0.08);
    _avatarSlider(tester, 'avatarRotationSlider').onChanged!(9.0);
    await tester.pump();

    await _tapVisible(tester, find.byKey(const ValueKey('avatarResetButton')));
    await tester.pump();

    expect(_avatarSliderValue(tester, 'avatarScaleSlider'), 1.0);
    expect(_avatarSliderValue(tester, 'avatarOffsetXSlider'), 0.0);
    expect(_avatarSliderValue(tester, 'avatarOffsetYSlider'), 0.0);
    expect(_avatarSliderValue(tester, 'avatarRotationSlider'), 0.0);
  });

  testWidgets('Avatar setup confirm saves custom avatar adjustment', (
    tester,
  ) async {
    MealTimerConfig? changedConfig;
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: avatarFile.path,
        customAvatarVehicleId: 'motorcycle',
      ),
      onConfigChanged: (config) => changedConfig = config,
    );

    await _scrollAvatarAdjustmentIntoView(tester);
    _avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.3);
    _avatarSlider(tester, 'avatarOffsetXSlider').onChanged!(0.1);
    _avatarSlider(tester, 'avatarOffsetYSlider').onChanged!(-0.05);
    _avatarSlider(tester, 'avatarRotationSlider').onChanged!(7.0);
    await tester.pump();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('avatarConfirmButton')),
    );
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
    expect(find.text('아바타를 저장했어요.'), findsOneWidget);
  });

  testWidgets('Avatar setup default image button saves default avatar mode', (
    tester,
  ) async {
    MealTimerConfig? changedConfig;
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(
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

    await _scrollAvatarAdjustmentIntoView(tester);
    await _tapVisible(
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
    MealTimerConfig? changedConfig;
    final busAvatarFile = _createTemporaryAvatarImage();
    final fireTruckAvatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults().copyWith(
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

    await _scrollAvatarAdjustmentIntoView(tester);
    expect(_avatarSliderValue(tester, 'avatarScaleSlider'), 1.2);

    await _scrollAvatarVehicleSelectionIntoView(tester);
    await _tapVisible(tester, _vehicleChoiceFinder('fire_truck'));
    await tester.pump();
    await _scrollAvatarAdjustmentBackIntoView(tester);

    expect(_avatarSliderValue(tester, 'avatarScaleSlider'), 1.35);
    _avatarSlider(tester, 'avatarScaleSlider').onChanged!(1.45);
    await tester.pump();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('avatarConfirmButton')),
    );
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
      MealTimerConfig? changedConfig;
      final busAvatarFile = _createTemporaryAvatarImage();
      final fireTruckAvatarFile = _createTemporaryAvatarImage();
      await _pumpAvatarSetupScreen(
        tester,
        MealTimerConfig.defaults().copyWith(
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

      await _scrollAvatarAdjustmentIntoView(tester);
      await _tapVisible(
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
    MealTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
    );

    expect(find.text('기본 이미지 미리보기'), findsOneWidget);
    await _tapVisible(
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
    MealTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      MealTimerConfig.defaults(),
      onConfigChanged: (config) => changedConfig = config,
    );

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();

    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('avatarConfirmButton')),
    );
    expect(confirmButton.onPressed, isNull);
    expect(changedConfig, isNull);
    expect(tester.takeException(), isNull);
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

    await tester.tap(find.textContaining('25분 보통 코스'));
    await tester.pump();

    expect(find.textContaining('남은 시간'), findsNothing);
    expect(find.text('도착까지'), findsNothing);
  });

  testWidgets('Settings screen shows avatar settings entry', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('아바타 설정'), findsOneWidget);
    expect(find.text('기본 이미지 사용 중'), findsOneWidget);
    expect(find.text('아바타 설정하기'), findsOneWidget);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(_vehicleChoiceFinder('motorcycle'), findsNothing);
  });

  testWidgets('Settings screen shows custom avatar state when active', (
    tester,
  ) async {
    final avatarFile = _createTemporaryAvatarImage();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: MealTimerConfig.defaults().copyWith(
            avatarMode: AvatarImageMode.custom,
            customAvatarImagePath: avatarFile.path,
            customAvatarVehicleId: 'motorcycle',
          ),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('아바타 설정'), findsOneWidget);
    expect(find.text('직접 만든 아바타 사용 중'), findsOneWidget);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(find.byType(VehicleSelectionCard), findsNothing);
  });

  testWidgets('Home screen shows quick courses above vehicle choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    expect(find.text('빠방 고르기'), findsNothing);
    expect(find.text('오토바이'), findsNothing);
    expect(find.text('소방차'), findsNothing);
    expect(find.text('경찰차'), findsNothing);
    expect(find.text('포크레인'), findsNothing);

    for (final vehicle in VehicleCatalog.all) {
      expect(
        _assetImage(vehicle.selectionImagePath),
        vehicle.id == 'motorcycle' ? findsNWidgets(2) : findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('selectedVehiclePreview')),
      findsOneWidget,
    );

    final firstRowTop = tester
        .getTopLeft(_vehicleChoiceFinder('motorcycle'))
        .dy;
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('fire_truck')).dy,
      firstRowTop,
    );
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('police_car')).dy,
      firstRowTop,
    );
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('excavator')).dy,
      firstRowTop,
    );
    final secondRowTop = tester.getTopLeft(_vehicleChoiceFinder('airplane')).dy;
    expect(secondRowTop, greaterThan(firstRowTop));
    expect(tester.getTopLeft(_vehicleChoiceFinder('bus')).dy, secondRowTop);
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('supercar')).dy,
      secondRowTop,
    );
    expect(tester.getTopLeft(_vehicleChoiceFinder('train')).dy, secondRowTop);
    final thirdRowTop = tester.getTopLeft(_vehicleChoiceFinder('t_rex')).dy;
    expect(thirdRowTop, greaterThan(secondRowTop));
    expect(tester.getTopLeft(_vehicleChoiceFinder('shark')).dy, thirdRowTop);
    expect(tester.getTopLeft(_vehicleChoiceFinder('brachio')).dy, thirdRowTop);
    expect(
      tester.getTopLeft(_vehicleChoiceFinder('pteranodon')).dy,
      thirdRowTop,
    );
    expect(
      tester.getSize(_vehicleChoiceFinder('motorcycle')).width,
      tester.getSize(_vehicleChoiceFinder('fire_truck')).width,
    );
    final firstRowCenterX =
        (_vehicleChoiceRect(tester, 'motorcycle').left +
            _vehicleChoiceRect(tester, 'excavator').right) /
        2;
    final thirdRowCenterX =
        (_vehicleChoiceRect(tester, 't_rex').left +
            _vehicleChoiceRect(tester, 'pteranodon').right) /
        2;
    expect((thirdRowCenterX - firstRowCenterX).abs(), lessThan(1.0));

    final vehicleTitleTop = tester.getTopLeft(find.text('오늘의 빠방')).dy;
    final firstCourseTop = tester.getTopLeft(find.text('15분 코스')).dy;
    expect(firstCourseTop, lessThan(vehicleTitleTop));
  });

  testWidgets(
    'Vehicle selection card renders custom avatars on saved choices',
    (tester) async {
      final busAvatarFile = _createTemporaryAvatarImage();
      final fireTruckAvatarFile = _createTemporaryAvatarImage();
      final avatarConfigs = {
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
      };

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: VehicleSelectionCard(
                title: '차량 선택',
                selectedVehicleId: 'motorcycle',
                onVehicleSelected: (_) {},
                avatarForVehicle: (vehicleId) {
                  final avatarConfig = avatarConfigs[vehicleId];
                  if (avatarConfig == null) {
                    return null;
                  }

                  return VehicleAvatarPresentation(
                    mode: AvatarImageMode.custom,
                    imagePath: avatarConfig.imagePath,
                    scale: avatarConfig.scale,
                    offsetX: avatarConfig.offsetX,
                    offsetY: avatarConfig.offsetY,
                    rotationDegrees: avatarConfig.rotationDegrees,
                  );
                },
                avatarImageBuilder: (context, imagePath) {
                  return ColoredBox(
                    key: ValueKey('customAvatar.$imagePath'),
                    color: Colors.pink,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(ValueKey('customAvatar.${busAvatarFile.path}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('customAvatar.${fireTruckAvatarFile.path}')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Selected vehicle on home is saved to preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(_vehicleChoiceFinder('police_car'));
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('vehicleId'), 'police_car');
    expect(
      _assetImage(VehicleCatalog.policeCar.selectionImagePath),
      findsNWidgets(2),
    );
    expect(
      _assetImage(VehicleCatalog.motorcycle.selectionImagePath),
      findsOneWidget,
    );
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
            vehicleId: 'fire_truck',
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

    expect(changedConfig?.vehicleId, 'police_car');
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
    await tester.pump();

    expect(find.text('이름을 저장했어요.'), findsOneWidget);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '서아');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('서아의 냠냠 기록'), findsOneWidget);
  });

  testWidgets('Empty child name in settings shows validation message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('이름 저장'));
    await tester.pump();

    expect(find.text('아이 이름을 입력해 주세요.'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '지율');
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
            child: RoadView(progress: 0.15, vehicle: VehicleCatalog.fireTruck),
          ),
        ),
      ),
    );
    expect(
      tester.widget<VehicleWidget>(find.byType(VehicleWidget)).isFacingLeft,
      isTrue,
    );
  });

  testWidgets('Road view renders custom avatar overlay from local file', (
    tester,
  ) async {
    final avatarFile = _createTemporaryAvatarImage();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              avatar: VehicleAvatarPresentation(
                mode: AvatarImageMode.custom,
                imagePath: avatarFile.path,
                scale: 1.2,
                offsetX: 0.05,
                offsetY: -0.04,
                rotationDegrees: 6,
              ),
              avatarImageBuilder: (context, imagePath) {
                return const ColoredBox(
                  key: ValueKey('avatarCompositeOverlayImage'),
                  color: Colors.pink,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Road view ignores missing custom avatar file safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              avatar: const VehicleAvatarPresentation(
                mode: AvatarImageMode.custom,
                imagePath: '/missing/avatar.png',
                scale: 1.2,
                offsetX: 0.05,
                offsetY: -0.04,
                rotationDegrees: 6,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avatarCompositeOverlayImage')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Road view limits motivation video to 16:9 in landscape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              motivationVideoAssetPath:
                  MotivationAssetCatalog.fallbackVideoPath,
              motivationVideoMilestone: 10,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final videoSize = tester.getSize(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );
    expect(videoSize.width, lessThanOrEqualTo(460));
    expect(videoSize.width / videoSize.height, closeTo(16 / 9, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Motivation video can render as a separate road layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              motivationVideoAssetPath:
                  MotivationAssetCatalog.fallbackVideoPath,
              motivationVideoMilestone: 10,
              showMotivationVideo: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsNothing,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadMotivationVideoLayer(
              assetPath: MotivationAssetCatalog.fallbackVideoPath,
              milestone: 10,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final videoSize = tester.getSize(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );
    expect(videoSize.width, lessThanOrEqualTo(460));
    expect(videoSize.width / videoSize.height, closeTo(16 / 9, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Timer screen does not apply avatar saved for another vehicle', (
    tester,
  ) async {
    final avatarFile = _createTemporaryAvatarImage();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: MealTimerConfig.defaults().copyWith(
            vehicleId: 'excavator',
            avatarMode: AvatarImageMode.custom,
            customAvatarImagePath: avatarFile.path,
            customAvatarVehicleId: 'police_car',
          ),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RoadView), findsOneWidget);
    expect(
      tester.widget<RoadView>(find.byType(RoadView)).avatar.mode,
      AvatarImageMode.defaultImage,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Timer screen applies avatar config for selected vehicle', (
    tester,
  ) async {
    final avatarFile = _createTemporaryAvatarImage();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: MealTimerConfig.defaults().copyWith(
            vehicleId: 'fire_truck',
            avatarMode: AvatarImageMode.custom,
            customAvatarsByVehicle: {
              'fire_truck': VehicleAvatarConfig(
                imagePath: avatarFile.path,
                scale: 1.4,
                offsetX: 0.11,
                offsetY: -0.07,
                rotationDegrees: 9.0,
              ),
            },
          ),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.avatar.mode, AvatarImageMode.custom);
    expect(roadView.avatar.imagePath, avatarFile.path);
    expect(roadView.avatar.scale, 1.4);
    expect(roadView.avatar.offsetX, 0.11);
    expect(roadView.avatar.offsetY, -0.07);
    expect(roadView.avatar.rotationDegrees, 9.0);
  });

  testWidgets('Timer screen plays motivation voice after video starts', (
    tester,
  ) async {
    final motivationAudioService = _FakeMotivationAudioService();
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TimerScreen(
          config: MealTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 100),
            soundEnabled: true,
          ),
          mealProgressService: LocalMealProgressService(),
          motivationAudioService: motivationAudioService,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsOneWidget,
    );
    expect(motivationAudioService.playedAssets, isEmpty);

    await tester.pump(motivationVoiceStartDelay);

    expect(motivationAudioService.playedAssets, hasLength(1));
    expect(
      motivationAudioService.playedAssets.single,
      startsWith('assets/audio/motivation/ko_'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Timer screen gives the route primary space in landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: MealTimerConfig.defaults(),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final roadSize = tester.getSize(find.byType(RoadView));
    expect(roadSize, const Size(1200, 520));
    expect(roadSize.width, greaterThan(760));
    expect(roadSize.height, greaterThan(460));
    expect(roadSize.height, lessThanOrEqualTo(560));
    final roadRect = tester.getRect(find.byType(RoadView));
    expect(
      roadRect.contains(tester.getCenter(find.byIcon(Icons.home_rounded))),
      isTrue,
    );
    expect(
      roadRect.contains(tester.getCenter(find.byIcon(Icons.flag_rounded))),
      isTrue,
    );
    expect(
      roadRect.contains(tester.getCenter(find.byType(VehicleWidget))),
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byType(RoadView),
        matching: find.byType(VehicleWidget),
      ),
      findsNothing,
    );
    expect(find.byType(VehicleWidget), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('remainingTimeBadge'))).width,
      360,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('remainingTimeBadge'))).height,
      lessThanOrEqualTo(
        tester
            .getSize(find.byKey(const ValueKey('timerProgressMessageCard')))
            .height,
      ),
    );
    final roadBounds = createRoadBounds(const Size(1200, 520));
    final expectedRoadRight =
        roadRect.left + (roadRect.width * roadBounds.right / 1200);
    final expectedRoadLeft =
        roadRect.left + (roadRect.width * roadBounds.left / 1200);
    expect(
      tester.getRect(find.byKey(const ValueKey('remainingTimeBadge'))).right,
      closeTo(expectedRoadRight, 1),
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('timerProgressMessageCard')))
          .left,
      greaterThanOrEqualTo(expectedRoadLeft),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('timerProgressIndicator')))
          .width,
      greaterThan(250),
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('timerProgressMessageCard')))
          .right,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const ValueKey('remainingTimeBadge'))).left,
      ),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('오늘의 냠냠코스'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(
      tester.widget<TimerControlBar>(find.byType(TimerControlBar)).isVertical,
      isFalse,
    );

    tester.view.physicalSize = const Size(900, 500);
    await tester.pump();

    expect(tester.getSize(find.byType(RoadView)), roadSize);
  });

  testWidgets('Timer screen allows landscape only while mounted', (
    tester,
  ) async {
    final orientationService = _FakeOrientationService();

    await tester.pumpWidget(
      MaterialApp(
        home: TimerScreen(
          config: MealTimerConfig.defaults(),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
          orientationService: orientationService,
        ),
      ),
    );
    await tester.pump();

    expect(orientationService.calls, ['allowTimerOrientations']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(orientationService.calls, [
      'allowTimerOrientations',
      'lockPortrait',
    ]);
  });

  testWidgets('Timer screen keeps screen awake only when setting is enabled', (
    tester,
  ) async {
    final screenAwakeService = _FakeScreenAwakeService();

    await tester.pumpWidget(
      MaterialApp(
        home: TimerScreen(
          config: MealTimerConfig.defaults().copyWith(keepScreenAwake: true),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
          screenAwakeService: screenAwakeService,
        ),
      ),
    );
    await tester.pump();

    expect(screenAwakeService.enabledValues, [true]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(screenAwakeService.enabledValues, [true, false]);
  });

  testWidgets(
    'Timer screen leaves wakelock untouched when setting is disabled',
    (tester) async {
      final screenAwakeService = _FakeScreenAwakeService();

      await tester.pumpWidget(
        MaterialApp(
          home: TimerScreen(
            config: MealTimerConfig.defaults().copyWith(keepScreenAwake: false),
            mealProgressService: LocalMealProgressService(),
            onConfigChanged: (_) {},
            screenAwakeService: screenAwakeService,
          ),
        ),
      );
      await tester.pump();

      expect(screenAwakeService.enabledValues, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(screenAwakeService.enabledValues, isEmpty);
    },
  );

  testWidgets('Timer screen asks before leaving with the back button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const Scaffold(body: Center(child: Text('타이머 열기'))),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: MealTimerConfig.defaults(),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('오늘의 냠냠코스'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('코스를 그만할까요?'), findsOneWidget);
    expect(find.text('지금 나가면 진행 중인 냠냠코스가 저장되지 않아요.'), findsOneWidget);

    await tester.tap(find.text('계속하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('코스를 그만할까요?'), findsNothing);
    expect(find.text('오늘의 냠냠코스'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.tap(find.text('그만하기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('타이머 열기'), findsOneWidget);
    expect(find.text('오늘의 냠냠코스'), findsNothing);
  });

  testWidgets('English locale shows English home copy', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('en'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.text("Today's Yamyam Mission"), findsOneWidget);
    expect(
      find.text('Your rider is waiting for a tasty finish'),
      findsOneWidget,
    );
    expect(find.text("Today's vehicle"), findsOneWidget);
    expect(find.text('15-min Ride'), findsOneWidget);
    expect(find.text('A light warm-up'), findsOneWidget);
    expect(find.textContaining('25-min Regular Ride'), findsOneWidget);
    expect(find.text('Other rides'), findsOneWidget);
    expect(find.text('35-min Ride'), findsOneWidget);
    expect(find.text('Cruise to the finish'), findsOneWidget);
    expect(find.textContaining('Custom time'), findsOneWidget);
  });

  testWidgets('English locale shows English timer progress copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    await tester.ensureVisible(find.text('Pause'));
    await tester.pump();
    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Taking a little break'), findsOneWidget);
    expect(find.text('Taking a break'), findsOneWidget);
  });

  testWidgets('Unsupported locale falls back to English', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ja'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Custom time'), findsOneWidget);
  });

  test('Fast meal awards only one random sticker', () async {
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

    expect(recordedSession.awardedRewards, hasLength(1));
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
    expect(recordedSession.entry.mealCompleted, isFalse);
    expect(
      recordedSession.entry.completionStatus,
      MealCompletionStatus.notCompleted,
    );
    expect(recordedSession.entry.rewardIds, isEmpty);
  });

  test('Arrival-completed meal records at-arrival status', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    final recordedSession = await service.recordMealResult(
      _mealResult(
        actualDuration: const Duration(minutes: 20),
        completedBeforeArrival: false,
        completionStatus: MealCompletionStatus.completedAtArrival,
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(
      recordedSession.entry.completionStatus,
      MealCompletionStatus.completedAtArrival,
    );
    expect(
      snapshot.history.single.completionStatus,
      MealCompletionStatus.completedAtArrival,
    );
  });

  test('Completed meal fills exactly one active reward goal slot', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordMealResult(_mealResult());
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.updatedRewardGoal?.filledCount, 1);
    expect(recordedSession.rewardGoalJustReady, isFalse);
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
  });

  test('Completed meal fills all active reward goals', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );
    await service.createRewardGoal(requiredStickerCount: 7, rewardText: '딸기');

    final recordedSession = await service.recordMealResult(_mealResult());
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.updatedRewardGoals, hasLength(2));
    expect(snapshot.activeRewardGoals, hasLength(2));
    expect(snapshot.activeRewardGoals.map((goal) => goal.filledCount), [1, 1]);
  });

  test('Only two active reward goals can be created', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );
    await service.createRewardGoal(requiredStickerCount: 7, rewardText: '딸기');

    expect(
      () =>
          service.createRewardGoal(requiredStickerCount: 10, rewardText: '젤리'),
      throwsStateError,
    );
  });

  test(
    'Legacy single reward goal storage loads into list storage shape',
    () async {
      final legacyGoal = RewardGoal(
        id: 'legacy-active',
        rewardText: '아이스크림',
        requiredStickerCount: 5,
        filledSlots: const [],
        createdAt: DateTime(2026, 5, 4, 12),
        status: RewardGoalStatus.active,
      );
      final legacyUsedGoal = RewardGoal(
        id: 'legacy-used',
        rewardText: '딸기',
        requiredStickerCount: 1,
        filledSlots: [
          RewardGoalSlot(
            rewardId: 'sticker_finish_flag',
            filledAt: DateTime(2026, 5, 4, 12),
            mealSessionId: 'meal-1',
          ),
        ],
        createdAt: DateTime(2026, 5, 4, 12),
        status: RewardGoalStatus.redeemed,
        redeemedAt: DateTime(2026, 5, 5, 12),
      );
      SharedPreferences.setMockInitialValues({
        'activeRewardGoal': jsonEncode(legacyGoal.toJson()),
        'redeemedRewardGoals': [jsonEncode(legacyUsedGoal.toJson())],
      });

      final snapshot = await LocalMealProgressService().loadSnapshot();

      expect(snapshot.activeRewardGoals, hasLength(1));
      expect(snapshot.activeRewardGoals.first.rewardText, '아이스크림');
      expect(snapshot.usedRewardGoals, hasLength(1));
      expect(snapshot.usedRewardGoals.first.status, RewardGoalStatus.used);
    },
  );

  test('Legacy meal history loads with completion status fallback', () async {
    SharedPreferences.setMockInitialValues({
      'mealHistory': [
        jsonEncode({
          'id': 'legacy-meal',
          'startedAt': DateTime(2026, 5, 4, 12).toIso8601String(),
          'endedAt': DateTime(2026, 5, 4, 12, 25).toIso8601String(),
          'targetMs': const Duration(minutes: 20).inMilliseconds,
          'actualMs': const Duration(minutes: 25).inMilliseconds,
          'completedBeforeArrival': false,
          'rewardIds': <String>[],
        }),
      ],
    });

    final snapshot = await LocalMealProgressService().loadSnapshot();

    expect(snapshot.history.single.mealCompleted, isTrue);
    expect(
      snapshot.history.single.completionStatus,
      MealCompletionStatus.completedAfterArrival,
    );
  });

  test('Fast meal fills only one reward goal slot', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordMealResult(
      _mealResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 13),
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
  });

  test('Incomplete meal does not fill a reward goal slot', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordMealResult(
      _mealResult(mealCompleted: false),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.updatedRewardGoal, isNull);
    expect(snapshot.activeRewardGoals.single.filledCount, 0);
  });

  test('Reward goal becomes earned when required count is reached', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 2,
      rewardText: '아이스크림',
    );

    await service.recordMealResult(
      _mealResult(endedAt: DateTime(2026, 5, 4, 12)),
    );
    final recordedSession = await service.recordMealResult(
      _mealResult(endedAt: DateTime(2026, 5, 4, 13)),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.rewardGoalJustReady, isTrue);
    expect(snapshot.activeRewardGoals, isEmpty);
    expect(snapshot.earnedRewardGoals.single.status, RewardGoalStatus.earned);
    expect(snapshot.earnedRewardGoals.single.earnedAt, isNotNull);
  });

  test('Using an earned goal moves it to used history', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 1,
      rewardText: '아이스크림',
    );
    await service.recordMealResult(_mealResult());

    final usedGoal = await service.useEarnedRewardGoal();
    final snapshot = await service.loadSnapshot();

    expect(usedGoal?.status, RewardGoalStatus.used);
    expect(usedGoal?.usedAt, isNotNull);
    expect(snapshot.activeRewardGoals, isEmpty);
    expect(snapshot.earnedRewardGoals, isEmpty);
    expect(snapshot.usedRewardGoals, hasLength(1));
    expect(snapshot.usedRewardGoals.first.rewardText, '아이스크림');
  });

  test('Active reward goal can be updated', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final updatedGoal = await service.updateActiveRewardGoal(
      requiredStickerCount: 7,
      rewardText: '딸기',
    );
    final snapshot = await service.loadSnapshot();

    expect(updatedGoal?.rewardText, '딸기');
    expect(updatedGoal?.requiredStickerCount, 7);
    expect(snapshot.activeRewardGoals.single.rewardText, '딸기');
    expect(snapshot.activeRewardGoals.single.requiredStickerCount, 7);
  });

  test(
    'Reducing required count to filled count makes reward goal earned',
    () async {
      SharedPreferences.setMockInitialValues({});

      final service = LocalMealProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 5,
        rewardText: '아이스크림',
      );
      await service.recordMealResult(_mealResult());
      await service.recordMealResult(
        _mealResult(endedAt: DateTime(2026, 5, 4, 13)),
      );

      final updatedGoal = await service.updateActiveRewardGoal(
        requiredStickerCount: 2,
        rewardText: '아이스크림',
      );

      final snapshot = await service.loadSnapshot();

      expect(updatedGoal?.status, RewardGoalStatus.earned);
      expect(updatedGoal?.earnedAt, isNotNull);
      expect(snapshot.activeRewardGoals, isEmpty);
      expect(snapshot.earnedRewardGoals, hasLength(1));
    },
  );

  test('Active reward goal can be canceled', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final canceledGoal = await service.cancelActiveRewardGoal();
    final snapshot = await service.loadSnapshot();

    expect(canceledGoal?.rewardText, '아이스크림');
    expect(snapshot.activeRewardGoals, isEmpty);
    expect(snapshot.usedRewardGoals, isEmpty);
  });

  test('Existing sticker inventory counts still increase', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordMealResult(_mealResult());
    final snapshot = await service.loadSnapshot();
    final inventoryCount = snapshot.inventory.fold<int>(
      0,
      (total, item) => total + item.count,
    );

    expect(inventoryCount, recordedSession.awardedRewards.length);
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
  });

  testWidgets('Home screen shows reward goal CTA', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: HomeScreen(
          config: MealTimerConfig.defaults().copyWith(childName: 'Jiyul'),
          mealProgressService: LocalMealProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Create Reward Promise'), findsOneWidget);
  });

  testWidgets('Home meal records summary opens meal history screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalMealProgressService();
    await service.recordMealResult(
      _mealResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: HomeScreen(
          config: MealTimerConfig.defaults().copyWith(childName: 'Jiyul'),
          mealProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Recent meal 20:00 · complete'), findsOneWidget);

    await tester.tap(find.text("Jiyul's meal records"));
    await tester.pumpAndSettle();

    expect(find.byType(MealHistoryScreen), findsOneWidget);
    expect(find.text('Meal Records'), findsOneWidget);
  });

  testWidgets('Home meal records summary shows incomplete status', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalMealProgressService();
    await service.recordMealResult(
      _mealResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        mealCompleted: false,
        completionStatus: MealCompletionStatus.notCompleted,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: HomeScreen(
          config: MealTimerConfig.defaults().copyWith(childName: '강우'),
          mealProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('최근 식사 20:00 · 미완료 · 스티커 없음 · 초과 +05:00'), findsOneWidget);
  });

  testWidgets('Reward goal creation form saves a goal', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalMealProgressService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: RewardGoalScreen(mealProgressService: service),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, '7'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ice cream');
    await tester.pump();
    await tester.tap(find.text('Save Promise'));
    await tester.pumpAndSettle();

    final snapshot = await service.loadSnapshot();
    expect(snapshot.activeRewardGoals.single.rewardText, 'ice cream');
    expect(snapshot.activeRewardGoals.single.requiredStickerCount, 7);
  });

  testWidgets('Earned reward use flow asks for confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalMealProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 1,
      rewardText: 'ice cream',
    );
    await service.recordMealResult(_mealResult());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: RewardGoalScreen(mealProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use Reward'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Reward'));
    await tester.pumpAndSettle();
    expect(find.text('Use this reward?'), findsOneWidget);

    await tester.tap(find.text('Keep Promise'));
    await tester.pumpAndSettle();
    expect((await service.loadSnapshot()).earnedRewardGoals, hasLength(1));

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use Reward'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Reward'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Reward').last);
    await tester.pumpAndSettle();

    final snapshot = await service.loadSnapshot();
    expect(snapshot.earnedRewardGoals, isEmpty);
    expect(snapshot.usedRewardGoals, hasLength(1));
  });

  testWidgets('Meal history screen shows empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: MealHistoryScreen(
          mealProgressService: LocalMealProgressService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('식사 기록'), findsOneWidget);
    expect(find.text('아직 식사 기록이 없어요'), findsOneWidget);
    expect(find.text('타이머를 완료하면 기록이 여기에 쌓여요.'), findsOneWidget);
  });

  testWidgets('Meal history screen lists saved meal records', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalMealProgressService();
    await service.recordMealResult(
      _mealResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeArrival: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: MealHistoryScreen(mealProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('12:25'), findsOneWidget);
    expect(find.text('목표'), findsOneWidget);
    expect(find.text('20:00'), findsNWidgets(2));
    expect(find.text('실제'), findsOneWidget);
    expect(find.text('25:00'), findsNothing);
    expect(find.text('초과 +05:00'), findsNothing);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('받은 스티커'), findsOneWidget);
  });

  testWidgets('Meal history screen shows incomplete meal records', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalMealProgressService();
    await service.recordMealResult(
      _mealResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        mealCompleted: false,
        completionStatus: MealCompletionStatus.notCompleted,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: MealHistoryScreen(mealProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('미완료'), findsOneWidget);
    expect(find.text('스티커 없음'), findsOneWidget);
    expect(find.text('초과 +05:00'), findsOneWidget);
  });
}

MealSessionResult _mealResult({
  DateTime? startedAt,
  DateTime? endedAt,
  Duration targetDuration = const Duration(minutes: 20),
  Duration actualDuration = const Duration(minutes: 25),
  bool completedBeforeArrival = false,
  bool mealCompleted = true,
  MealCompletionStatus? completionStatus,
}) {
  final resolvedStartedAt = startedAt ?? DateTime(2026, 5, 4, 12);
  final resolvedEndedAt = endedAt ?? resolvedStartedAt.add(actualDuration);

  return MealSessionResult(
    startedAt: resolvedStartedAt,
    endedAt: resolvedEndedAt,
    targetDuration: targetDuration,
    actualDuration: actualDuration,
    completedBeforeArrival: completedBeforeArrival,
    mealCompleted: mealCompleted,
    completionStatus: completionStatus,
  );
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

Future<void> _pumpAvatarSetupScreen(
  WidgetTester tester,
  MealTimerConfig config, {
  Locale locale = const Locale('ko'),
  ValueChanged<MealTimerConfig>? onConfigChanged,
  AvatarImagePicker? imagePicker,
  LocalAvatarImageService? avatarImageService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: AvatarSetupScreen(
        config: config,
        onConfigChanged: onConfigChanged ?? (_) {},
        imagePicker: imagePicker,
        avatarImageService: avatarImageService,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _scrollAvatarPromptIntoView(WidgetTester tester) async {
  for (var index = 0; index < 4; index += 1) {
    if (find.byKey(const ValueKey('avatarPromptText')).evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollAvatarVehicleSelectionIntoView(WidgetTester tester) async {
  for (var index = 0; index < 4; index += 1) {
    if (find.text('아바타를 태울 차량').evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollAvatarCompositeIntoView(WidgetTester tester) async {
  for (var index = 0; index < 4; index += 1) {
    if (find.text('합성 미리보기').evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollAvatarAdjustmentIntoView(WidgetTester tester) async {
  for (var index = 0; index < 6; index += 1) {
    if (find.byKey(const ValueKey('avatarScaleSlider')).evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollAvatarAdjustmentBackIntoView(WidgetTester tester) async {
  for (var index = 0; index < 6; index += 1) {
    if (find.byKey(const ValueKey('avatarScaleSlider')).evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Slider _avatarSlider(WidgetTester tester, String keyValue) {
  return tester.widget<Slider>(find.byKey(ValueKey(keyValue)));
}

double _avatarSliderValue(WidgetTester tester, String keyValue) {
  return _avatarSlider(tester, keyValue).value;
}

File _createTemporaryAvatarImage() {
  final temporaryDirectory = Directory.systemTemp.createTempSync(
    'road_avatar_test_',
  );
  final avatarFile = File('${temporaryDirectory.path}/avatar.png');
  avatarFile.writeAsBytesSync(_transparentPngBytes);
  addTearDown(() {
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });
  return avatarFile;
}

final _transparentPngBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Material _vehicleChoiceMaterial(WidgetTester tester, String vehicleId) {
  return tester.widget<Material>(_vehicleChoiceFinder(vehicleId));
}

Rect _vehicleChoiceRect(WidgetTester tester, String vehicleId) {
  return tester.getRect(_vehicleChoiceFinder(vehicleId));
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

String _avatarPromptText(WidgetTester tester) {
  return tester
      .widget<SelectableText>(find.byKey(const ValueKey('avatarPromptText')))
      .data!;
}

class _FakeAvatarImagePicker implements AvatarImagePicker {
  const _FakeAvatarImagePicker([this.pickedFile]);

  final XFile? pickedFile;

  @override
  Future<XFile?> pickAvatarImage() async {
    return pickedFile;
  }
}

class _FakeScreenAwakeService implements ScreenAwakeService {
  final List<bool> enabledValues = [];

  @override
  Future<void> setEnabled(bool enabled) async {
    enabledValues.add(enabled);
  }
}

class _FakeOrientationService implements OrientationService {
  final List<String> calls = [];

  @override
  Future<void> lockPortrait() async {
    calls.add('lockPortrait');
  }

  @override
  Future<void> allowTimerOrientations() async {
    calls.add('allowTimerOrientations');
  }
}

class _FakeMotivationAudioService implements MotivationAudioService {
  final List<String> playedAssets = [];
  var stopCount = 0;
  var disposeCount = 0;

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

class _FakeLocalAvatarImageService extends LocalAvatarImageService {
  const _FakeLocalAvatarImageService(this.savedPath);

  final String savedPath;

  @override
  Future<String> savePickedAvatarImage(XFile pickedFile) async {
    return savedPath;
  }
}
