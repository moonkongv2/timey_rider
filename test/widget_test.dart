import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/catalogs/activity_marker_catalog.dart';
import 'package:timey_rider/catalogs/avatar_prompt_catalog.dart';
import 'package:timey_rider/catalogs/motivation_asset_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/l10n/app_texts.dart';
import 'package:timey_rider/main.dart' as app;
import 'package:timey_rider/models/active_activity_timer_session.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_session_result.dart';
import 'package:timey_rider/models/activity_timer_config.dart';
import 'package:timey_rider/models/activity_timer_preset.dart';
import 'package:timey_rider/models/reward_goal.dart';
import 'package:timey_rider/models/reward_item.dart';
import 'package:timey_rider/models/vehicle.dart';
import 'package:timey_rider/models/vehicle_avatar_presentation.dart';
import 'package:timey_rider/screens/avatar_setup_screen.dart';
import 'package:timey_rider/screens/home_screen.dart';
import 'package:timey_rider/screens/activity_history_screen.dart';
import 'package:timey_rider/screens/reward_goal_screen.dart';
import 'package:timey_rider/screens/result_screen.dart';
import 'package:timey_rider/screens/settings_screen.dart';
import 'package:timey_rider/screens/timer_screen.dart';
import 'package:timey_rider/screens/user_guide_screen.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/avatar_image_picker.dart';
import 'package:timey_rider/services/local_avatar_image_service.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'package:timey_rider/services/local_recent_timer_service.dart';
import 'package:timey_rider/services/local_saved_timer_preset_service.dart';
import 'package:timey_rider/services/local_settings_service.dart';
import 'package:timey_rider/services/motivation_audio_service.dart';
import 'package:timey_rider/services/orientation_service.dart';
import 'package:timey_rider/services/screen_awake_service.dart';
import 'package:timey_rider/utils/motivation_video_schedule.dart'
    as motivation_schedule;
import 'package:timey_rider/widgets/app/app_bouncy_button.dart';
import 'package:timey_rider/widgets/avatar/avatar_composite_preview.dart';
import 'package:timey_rider/widgets/road_painter.dart';
import 'package:timey_rider/widgets/road_view.dart';
import 'package:timey_rider/widgets/reward_sticker_image.dart';
import 'package:timey_rider/widgets/timer_control_bar.dart';
import 'package:timey_rider/widgets/vehicle_selection_card.dart';
import 'package:timey_rider/widgets/vehicle_widget.dart';

void main() {
  test('Default config uses default avatar image settings', () {
    final config = ActivityTimerConfig.defaults();

    expect(config.avatarMode, AvatarImageMode.defaultImage);
    expect(config.customAvatarImagePath, isNull);
    expect(config.customAvatarVehicleId, isNull);
    expect(config.vehicleId, 'motorcycle');
    expect(config.soundEnabled, isTrue);
    expect(config.motivationVideoEnabled, isTrue);
    expect(config.motivationVideoUseCustomInterval, isFalse);
    expect(config.motivationVideoInterval, const Duration(minutes: 3));
    expect(config.activityId, ActivityCatalog.defaultActivity.id);
    expect(config.duration, ActivityCatalog.defaultActivity.defaultDuration);
    expect(config.markerMode, ActivityMarkerMode.activityDefault);
    expect(config.avatarScale, 1.0);
    expect(config.avatarOffsetX, 0.0);
    expect(config.avatarOffsetY, 0.0);
    expect(config.avatarRotationDegrees, 0.0);
    expect(config.customAvatarsByVehicle, isEmpty);
    expect(config.markerIds, ActivityCatalog.defaultActivity.markerIds);
    expect(config.selectedMarkerIds, isEmpty);
  });

  test('Activity marker catalog has non-empty unique ids', () {
    final ids = ActivityMarkerCatalog.all.map((marker) => marker.id).toList();

    expect(ids, isNotEmpty);
    expect(ids.every((id) => id.trim().isNotEmpty), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('Activity marker automatic selection returns valid ids', () {
    final ids = ActivityMarkerCatalog.automaticSelectionIds();

    expect(ids, isNotEmpty);
    expect(ids, hasLength(2));
    for (final id in ids) {
      expect(ActivityMarkerCatalog.findById(id), isNotNull);
    }
  });

  test('Activity marker course slots returns exactly 30 markers', () {
    final slots = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    expect(slots, hasLength(30));
  });

  test('Activity marker course slot count scales with duration', () {
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 1),
      ),
      30,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 5),
      ),
      30,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 15),
      ),
      54,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 25),
      ),
      90,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 35),
      ),
      126,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 60),
      ),
      144,
    );
  });

  test('Activity marker course slots only uses selected ids', () {
    const selectedIds = ['top_teeth', 'bottom_teeth', 'molars'];
    final slots = ActivityMarkerCatalog.courseSlotsFor(selectedIds);

    expect(slots.map((marker) => marker.id).toSet(), {
      'top_teeth',
      'bottom_teeth',
      'molars',
    });
  });

  test('Reward catalog uses routine activity stickers', () {
    final ids = RewardCatalog.successStickers
        .map((reward) => reward.id)
        .toList();

    expect(ids, [
      'sticker_finish_flag',
      'sticker_twinkle_star',
      'sticker_sparkly_teeth',
      'sticker_book_buddy',
      'sticker_cleanup_champ',
      'sticker_happy_clock',
      'sticker_rainbow_course',
      'sticker_rocket',
    ]);
    expect(RewardCatalog.sparklyTeethSticker.emoji, '✨');
    expect(RewardCatalog.bookBuddySticker.emoji, '📚');
    expect(RewardCatalog.cleanupChampSticker.emoji, '🧸');
    expect(RewardCatalog.happyClockSticker.emoji, '⏰');
  });

  testWidgets('Reward sticker image falls back for missing routine assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RewardStickerImage(reward: RewardCatalog.sparklyTeethSticker),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('✨'), findsOneWidget);
  });

  test('Activity marker course slots fall back for invalid selected ids', () {
    final slots = ActivityMarkerCatalog.courseSlotsFor(['missing']);

    expect(
      slots.map((marker) => marker.id).toSet(),
      ActivityMarkerCatalog.defaultSelectionIds.toSet(),
    );
  });

  test(
    'Activity marker course slots avoids 3 consecutive identical ids when possible',
    () {
      final slots = ActivityMarkerCatalog.courseSlotsFor([
        'top_teeth',
        'top_teeth',
        'bottom_teeth',
      ]);

      for (var index = 2; index < slots.length; index += 1) {
        expect(
          slots[index].id == slots[index - 1].id &&
              slots[index].id == slots[index - 2].id,
          isFalse,
        );
      }
    },
  );

  test('ActivityTimerConfig copyWith preserves and updates marker ids', () {
    final config = ActivityTimerConfig.defaults().copyWith(
      markerIds: const ['top_teeth', 'bottom_teeth'],
      selectedMarkerIds: const ['top_teeth'],
    );
    final preservedConfig = config.copyWith(vehicleId: 'bus');
    final updatedConfig = config.copyWith(
      markerIds: const ['cover', 'bookmark'],
      selectedMarkerIds: const ['cover'],
    );

    expect(preservedConfig.markerIds, ['top_teeth', 'bottom_teeth']);
    expect(preservedConfig.selectedMarkerIds, ['top_teeth']);
    expect(updatedConfig.markerIds, ['cover', 'bookmark']);
    expect(updatedConfig.selectedMarkerIds, ['cover']);
  });

  test('ActivityTimerConfig copyWith updates motivation video settings', () {
    final config = ActivityTimerConfig.defaults().copyWith(
      motivationVideoEnabled: false,
      motivationVideoUseCustomInterval: true,
      motivationVideoInterval: const Duration(minutes: 5),
    );
    final preservedConfig = config.copyWith(vehicleId: 'bus');
    final updatedConfig = config.copyWith(
      motivationVideoEnabled: true,
      motivationVideoUseCustomInterval: false,
      motivationVideoInterval: const Duration(minutes: 10),
    );

    expect(preservedConfig.motivationVideoEnabled, isFalse);
    expect(preservedConfig.motivationVideoUseCustomInterval, isTrue);
    expect(preservedConfig.motivationVideoInterval, const Duration(minutes: 5));
    expect(updatedConfig.motivationVideoEnabled, isTrue);
    expect(updatedConfig.motivationVideoUseCustomInterval, isFalse);
    expect(updatedConfig.motivationVideoInterval, const Duration(minutes: 10));
  });

  test('ActivityTimerConfig copyWith updates marker mode', () {
    final config = ActivityTimerConfig.defaults().copyWith(
      markerMode: ActivityMarkerMode.activityDefault,
    );
    final preservedConfig = config.copyWith(vehicleId: 'bus');
    final updatedConfig = config.copyWith(markerMode: ActivityMarkerMode.off);

    expect(preservedConfig.markerMode, ActivityMarkerMode.activityDefault);
    expect(updatedConfig.markerMode, ActivityMarkerMode.off);
  });

  test('Local settings saves and loads avatar settings', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveConfig(
      ActivityTimerConfig.defaults().copyWith(
        childName: '지율',
        vehicleId: 'police_car',
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: '/local/avatar.png',
        customAvatarVehicleId: 'police_car',
        avatarScale: 1.25,
        avatarOffsetX: 8.0,
        avatarOffsetY: -6.0,
        avatarRotationDegrees: 12.0,
        markerIds: const ['top_teeth', 'bottom_teeth'],
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
    expect(loadedConfig.markerIds, ActivityCatalog.defaultActivity.markerIds);
    expect(preferences.getStringList('markerIds'), isNull);
    expect(preferences.getString('activityId'), 'brushing');
    final policeCarAvatar = loadedConfig.customAvatarConfigForVehicle(
      'police_car',
    );
    expect(policeCarAvatar?.imagePath, '/local/avatar.png');
    expect(policeCarAvatar?.scale, 1.25);
    expect(policeCarAvatar?.offsetX, 8.0);
    expect(policeCarAvatar?.offsetY, -6.0);
    expect(policeCarAvatar?.rotationDegrees, 12.0);
  });

  test('Local settings saves and loads motivation video settings', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveConfig(
      ActivityTimerConfig.defaults().copyWith(
        motivationVideoEnabled: false,
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 5),
      ),
    );

    final loadedConfig = await service.loadConfig();
    final preferences = await SharedPreferences.getInstance();
    expect(loadedConfig.motivationVideoEnabled, isFalse);
    expect(loadedConfig.motivationVideoUseCustomInterval, isTrue);
    expect(loadedConfig.motivationVideoInterval, const Duration(minutes: 5));
    expect(preferences.getBool('motivationVideoEnabled'), isFalse);
    expect(preferences.getBool('motivationVideoUseCustomInterval'), isTrue);
    expect(preferences.getInt('motivationVideoIntervalMinutes'), 5);
  });

  test('Local settings saves and loads marker mode', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveConfig(
      ActivityTimerConfig.defaults().copyWith(
        markerMode: ActivityMarkerMode.activityDefault,
      ),
    );

    final loadedConfig = await service.loadConfig();
    final preferences = await SharedPreferences.getInstance();
    expect(loadedConfig.markerMode, ActivityMarkerMode.activityDefault);
    expect(preferences.getString('markerMode'), 'activityDefault');
  });

  test('Local settings falls back for invalid marker mode', () async {
    SharedPreferences.setMockInitialValues({'markerMode': 'unknown'});

    final loadedConfig = await LocalSettingsService().loadConfig();

    expect(loadedConfig.markerMode, ActivityMarkerMode.activityDefault);
  });

  test(
    'Local settings falls back for invalid motivation video interval',
    () async {
      SharedPreferences.setMockInitialValues({
        'motivationVideoEnabled': false,
        'motivationVideoUseCustomInterval': true,
        'motivationVideoIntervalMinutes': 0,
      });

      final loadedConfig = await LocalSettingsService().loadConfig();

      expect(loadedConfig.motivationVideoEnabled, isFalse);
      expect(loadedConfig.motivationVideoUseCustomInterval, isTrue);
      expect(loadedConfig.motivationVideoInterval, const Duration(minutes: 3));
    },
  );

  test('Local settings saves and loads vehicle avatar maps', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalSettingsService();
    await service.saveConfig(
      ActivityTimerConfig.defaults().copyWith(
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
      ActivityTimerConfig.defaults().copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: '/local/avatar.png',
      ),
    );
    await service.saveConfig(
      ActivityTimerConfig.defaults().copyWith(customAvatarImagePath: null),
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

  test('Catalog vehicles define the expected course kind', () {
    const expectedCourseKinds = {
      'airplane': VehicleCourseKind.sky,
      'pteranodon': VehicleCourseKind.sky,
      'shark': VehicleCourseKind.water,
      'train': VehicleCourseKind.rail,
      't_rex': VehicleCourseKind.field,
      'brachio': VehicleCourseKind.field,
    };

    for (final vehicle in VehicleCatalog.all) {
      expect(
        vehicle.courseKind,
        expectedCourseKinds[vehicle.id] ?? VehicleCourseKind.road,
        reason: vehicle.id,
      );
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

  testWidgets('Completed-before-arrival result shows intro video screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final introVideoPaths = <String>[];

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
          result: _activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.pump();

    expect(introVideoPaths, [
      resultVideoAssetPathForVehicle(vehicleId: 'motorcycle'),
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Completed-after-arrival result also shows intro video screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final introVideoPaths = <String>[];

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
          result: _activityResult(completedBeforeEnd: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.pump();

    expect(introVideoPaths, [
      resultVideoAssetPathForVehicle(vehicleId: 'motorcycle'),
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Needs-more-time result screen skips the intro video', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final service = LocalActivityProgressService();
    final introVideoPaths = <String>[];

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
          result: _activityResult(activityCompleted: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: service,
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();

    expect(introVideoPaths, isEmpty);
    expect(find.byKey(const ValueKey('resultIntroScreen')), findsNothing);
    expect(find.text('조금 더 필요했어'), findsOneWidget);
    expect(find.text('오토바이가 먼저 도착했어.'), findsOneWidget);
    expect(
      _assetImage('assets/images/result_failed_bg_portrait.png'),
      findsOneWidget,
    );
    expect(
      _assetImage(failureRiderAssetPathForVehicle(vehicleId: 'motorcycle')),
      findsOneWidget,
    );

    final snapshot = await service.loadSnapshot();
    expect(snapshot.history, hasLength(1));
    expect(snapshot.history.single.activityCompleted, isFalse);
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.needsMoreTime,
    );
  });

  testWidgets('Time-ended result skips reward intro and sticker copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final introVideoPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          result: _activityResult(
            completionStatus: ActivityCompletionStatus.timeEnded,
          ),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (assetPath) {
            introVideoPaths.add(assetPath);
            return VideoPlayerController.asset(assetPath);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(introVideoPaths, isEmpty);
    expect(find.text("Time's Up!"), findsOneWidget);
    expect(find.text("Let's move to the next little mission."), findsOneWidget);
    expect(find.byType(RewardStickerImage), findsNothing);
    expect(find.textContaining('sticker'), findsNothing);
  });

  testWidgets('Result screen records after the sticker choice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();

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
          result: _activityResult(includeStickerDecision: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('미션을 마쳤나요?'), findsOneWidget);
    expect(find.text('스티커 받기'), findsOneWidget);
    expect(find.text('이번엔 스티커 받지 않기'), findsOneWidget);
    expect((await service.loadSnapshot()).history, isEmpty);

    await tester.tap(find.byKey(const ValueKey('resultSkipStickerButton')));
    await tester.pumpAndSettle();

    expect(find.text('미션 완료!'), findsOneWidget);
    expect(find.byType(RewardStickerImage), findsNothing);
    final snapshot = await service.loadSnapshot();
    expect(snapshot.history, hasLength(1));
    expect(snapshot.history.single.activityCompleted, isTrue);
    expect(snapshot.history.single.rewardIds, isEmpty);
    expect(snapshot.inventory, isEmpty);
  });

  testWidgets('Success result screen uses portrait background after intro', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
        home: ResultScreen(
          result: _activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('미션 완료!'), findsOneWidget);
    expect(
      _assetImage('assets/images/result_success_bg_portrait.png'),
      findsOneWidget,
    );
  });

  testWidgets('Completed result help explains sticker reward', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
        home: ResultScreen(
          result: _activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('부모님 응원 팁'), findsOneWidget);
    expect(find.text('아이에게 이렇게 말해보세요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('completedResultGuardianTipCard')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('completedResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.text('아이에게 이렇게 말해보세요'), findsWidgets);
    expect(find.text('끝까지 해보려고 한 게 정말 좋았어.'), findsOneWidget);
    expect(find.text('빨리 해서 잘했어.'), findsOneWidget);
    expect(find.textContaining('스티커 1개'), findsOneWidget);
  });

  testWidgets('Incomplete result help explains record without sticker', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
        home: ResultScreen(
          result: _activityResult(activityCompleted: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('부모님 응원 팁'), findsOneWidget);
    expect(find.text('다음 도전을 부드럽게 응원해요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('incompleteResultGuardianTipCard')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('incompleteResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.text('아이에게 이렇게 말해보세요'), findsOneWidget);
    expect(find.textContaining('오늘은 시간이 조금 더 필요했네'), findsOneWidget);
    expect(find.textContaining('미완료는 벌이 아니라 다음 조절을 위한 기록'), findsOneWidget);
    expect(find.text('실패했네.'), findsOneWidget);
  });

  testWidgets('English completed result help shows coaching sections', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          result: _activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parent tips'), findsOneWidget);
    expect(find.text('Try saying this'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('completedResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(
      find.textContaining('The activity was confirmed finished'),
      findsOneWidget,
    );
    expect(find.text('Try saying this'), findsWidgets);
    expect(find.text('Try to avoid'), findsOneWidget);
  });

  testWidgets('English incomplete result help frames incomplete as guidance', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: ResultScreen(
          result: _activityResult(activityCompleted: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parent tips'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('incompleteResultGuardianTipCard')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.textContaining('not a punishment'), findsWidgets);
  });

  testWidgets('Failed result screen uses selected rider image in landscape', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
        home: ResultScreen(
          result: _activityResult(activityCompleted: false),
          config: ActivityTimerConfig.defaults().copyWith(vehicleId: 'bus'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('compactLandscapeResultCard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('incompleteResultGuardianTipButton')),
      findsOneWidget,
    );
    expect(find.text('버스가 먼저 도착했어.'), findsOneWidget);
    expect(
      _assetImage('assets/images/result_failed_bg_landscape.png'),
      findsOneWidget,
    );
    expect(
      _assetImage(failureRiderAssetPathForVehicle(vehicleId: 'bus')),
      findsOneWidget,
    );
  });

  testWidgets('Success result keeps actions visible in compact landscape', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
        home: ResultScreen(
          result: _activityResult(completedBeforeEnd: true),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          introControllerFactory: (_) {
            return VideoPlayerController.asset(
              'assets/videos/missing_result_success.mp4',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('compactLandscapeResultCard')),
    );
    final restartButton = find.widgetWithText(FilledButton, '다시 출발');
    final homeButton = find.widgetWithText(OutlinedButton, '홈으로');

    expect(find.text('미션 완료!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('completedResultGuardianTipButton')),
      findsOneWidget,
    );
    expect(
      _assetImage('assets/images/result_success_bg_landscape.png'),
      findsOneWidget,
    );
    expect(restartButton, findsOneWidget);
    expect(homeButton, findsOneWidget);
    expect(cardRect.contains(tester.getCenter(restartButton)), isTrue);
    expect(cardRect.contains(tester.getCenter(homeButton)), isTrue);
    expect(
      tester.getRect(restartButton).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );
    expect(
      tester.getRect(homeButton).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );
  });

  testWidgets('Result screen allows landscape until disposed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final orientationService = _FakeOrientationService();

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
          result: _activityResult(activityCompleted: false),
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
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

  test(
    'Motivation schedule switches to three-minute cadence after 30 minutes',
    () {
      expect(usesTimedMotivationSchedule(const Duration(minutes: 30)), isFalse);
      expect(usesTimedMotivationSchedule(const Duration(minutes: 31)), isTrue);

      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 30),
          elapsed: const Duration(minutes: 3),
          progress: 0.10,
          shownMilestones: {},
        ),
        10,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 2, seconds: 59),
          progress: 0.05,
          shownMilestones: {},
        ),
        isNull,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 3),
          progress: 0.05,
          shownMilestones: {},
        ),
        3,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 6, seconds: 1),
          progress: 0.10,
          shownMilestones: {3},
        ),
        6,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 9, seconds: 59),
          progress: 0.16,
          shownMilestones: {},
        ),
        9,
      );
      expect(
        nextMotivationMilestoneForTimer(
          duration: const Duration(minutes: 60),
          elapsed: const Duration(minutes: 60),
          progress: 1,
          shownMilestones: {57},
        ),
        isNull,
      );
    },
  );

  test('Motivation schedule can be disabled from config', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(motivationVideoEnabled: false),
    );

    expect(schedule.usesTimedSchedule(const Duration(minutes: 60)), isFalse);
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 60),
        elapsed: const Duration(minutes: 3),
        progress: 0.05,
        shownMilestones: {},
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 2),
        progress: 0.10,
        shownMilestones: {},
      ),
      isNull,
    );
  });

  test('Custom motivation interval ignores percent milestones', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 5),
      ),
    );

    expect(schedule.usesTimedSchedule(const Duration(minutes: 15)), isTrue);
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 2),
        progress: 0.10,
        shownMilestones: {},
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 5),
        progress: 0.33,
        shownMilestones: {},
      ),
      5,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 15),
        elapsed: const Duration(minutes: 10),
        progress: 0.66,
        shownMilestones: {5},
      ),
      10,
    );
  });

  test('Custom motivation interval longer than timer duration never plays', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 10),
      ),
    );

    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 5),
        elapsed: const Duration(minutes: 4, seconds: 59),
        progress: 0.99,
        shownMilestones: {},
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 5),
        elapsed: const Duration(minutes: 5),
        progress: 1,
        shownMilestones: {},
      ),
      isNull,
    );
  });

  test('Timed motivation schedule can restart from an elapsed offset', () {
    final schedule = motivation_schedule.MotivationVideoSchedule.fromConfig(
      ActivityTimerConfig.defaults().copyWith(
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 3),
      ),
    );

    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 60),
        elapsed: const Duration(minutes: 10, seconds: 59),
        progress: 0.18,
        shownMilestones: {},
        scheduleStartedAt: const Duration(minutes: 8),
      ),
      isNull,
    );
    expect(
      schedule.nextMilestoneForTimer(
        duration: const Duration(minutes: 60),
        elapsed: const Duration(minutes: 11),
        progress: 0.18,
        shownMilestones: {},
        scheduleStartedAt: const Duration(minutes: 8),
      ),
      11,
    );
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

  test('Result outcome helpers separate positive and rewardable statuses', () {
    expect(
      isPositiveResult(ActivityCompletionStatus.completedBeforeEnd),
      isTrue,
    );
    expect(isPositiveResult(ActivityCompletionStatus.timeEnded), isTrue);
    expect(isPositiveResult(ActivityCompletionStatus.needsMoreTime), isFalse);

    expect(isRewardableResult(ActivityCompletionStatus.completedAtEnd), isTrue);
    expect(isRewardableResult(ActivityCompletionStatus.timeEnded), isFalse);
    expect(isRewardableResult(ActivityCompletionStatus.canceled), isFalse);
  });

  test('Arrival dialog copy uses the selected vehicle label', () {
    final timerTexts = AppTexts.ko.timer;

    expect(
      timerTexts.arrivalDialogMessage('경찰차', '양치'),
      '경찰차가 도착했어. 양치 미션을 마쳤어?',
    );
    expect(
      timerTexts.arrivalDialogMessage('포크레인', '정리'),
      '포크레인이 도착했어. 정리 미션을 마쳤어?',
    );
  });

  test('Timer arrival dialog copy uses the configured vehicle', () {
    expect(
      timerArrivalDialogMessage(
        texts: AppTexts.ko.timer,
        vehicleId: 'excavator',
        languageCode: 'ko',
        activityLabel: '양치',
      ),
      '포크레인이 도착했어. 양치 미션을 마쳤어?',
    );
    expect(
      timerArrivalDialogMessage(
        texts: AppTexts.en.timer,
        vehicleId: 'police_car',
        languageCode: 'en',
        activityLabel: 'Brush Teeth',
      ),
      'The police car arrived. Did you finish Brush Teeth?',
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

  testWidgets('First launch shows onboarding before child name setup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(
      tester,
      const Locale('ko'),
      completeOnboarding: false,
      completeChildNameSetup: false,
    );

    expect(find.byKey(const ValueKey('onboardingScreen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboardingSkipButton')));
    await tester.pumpAndSettle();

    expect(find.text('누가 Timey Rider를 탈까?'), findsOneWidget);
    expect(find.text('이름 저장'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '민준');
    await tester.pump();
    await tester.tap(find.text('이름 저장'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('childName'), '민준');
    expect(preferences.getBool('hasSeenOnboarding'), isTrue);
  });

  testWidgets('Home screen shows activity timer actions', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

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

    await _openTimerBuilder(tester);

    expect(find.text('양치'), findsOneWidget);
    expect(find.text('책 읽기'), findsOneWidget);
    expect(find.text('정리'), findsOneWidget);
    expect(find.text('놀이'), findsOneWidget);
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
      SharedPreferences.setMockInitialValues({});
      await _startApp(tester, locale);
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

  testWidgets('Home screen opens a saved active timer session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 10));
    final session = ActiveActivityTimerSession(
      sessionId: 'active-session',
      startedAt: startedAt,
      config: ActivityTimerConfig.defaults().copyWith(
        childName: '지율',
        duration: const Duration(minutes: 35),
        vehicleId: 'bus',
      ),
      state: ActiveActivityTimerSessionState.running,
    );
    await const ActiveActivityTimerSessionStore().save(session);

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
            duration: const Duration(minutes: 25),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);
    expect(find.text('진행 중인 활동 타이머'), findsOneWidget);

    await tester.tap(find.text('이어가기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.restoredSession?.sessionId, 'active-session');
    expect(timerScreen.config.duration, const Duration(minutes: 35));
  });

  testWidgets('Home screen can cancel a saved active timer session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final now = DateTime(2026, 6, 10, 8, 10);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: DateTime(2026, 6, 10, 8),
        config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('activeTimerCancelButton')));
    await tester.pump();

    expect(find.text('진행 중인 타이머를 취소할까요?'), findsOneWidget);

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(await const ActiveActivityTimerSessionStore().load(), isNull);
    await tester.pump();
    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsNothing);
  });

  testWidgets('Home active timer remaining time updates every second', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    var now = DateTime(2026, 6, 10, 8);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: now.subtract(Duration(minutes: 24, seconds: 50)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
        ),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    await tester.pump();

    final activeTimerCard = find.byKey(const ValueKey('activeTimerResumeCard'));
    String remainingText() {
      return tester
          .widget<Text>(
            find.descendant(
              of: activeTimerCard,
              matching: find.textContaining('남은 시간'),
            ),
          )
          .data!;
    }

    final initialRemainingText = remainingText();
    expect(initialRemainingText, startsWith('남은 시간 00:'));

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(remainingText(), isNot(initialRemainingText));
  });

  testWidgets('Home screen shows finished copy for arrived active sessions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final now = DateTime(2026, 6, 10, 8);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: now.subtract(const Duration(minutes: 30)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
        ),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsOneWidget);
    expect(find.text('활동 시간이 끝났어요'), findsOneWidget);
    expect(find.textContaining('남은 시간'), findsNothing);
  });

  testWidgets('Home screen clears stale active timer sessions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final now = DateTime(2026, 6, 10, 8);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'stale-session',
        startedAt: now.subtract(const Duration(hours: 25)),
        config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    await tester.pump();

    expect(await const ActiveActivityTimerSessionStore().load(), isNull);
    expect(find.byKey(const ValueKey('activeTimerResumeCard')), findsNothing);
  });

  testWidgets('Home screen resumes finished active sessions at the finish', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final now = DateTime(2026, 6, 10, 8);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'finished-session',
        startedAt: now.subtract(const Duration(minutes: 30)),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 25),
        ),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('이어가기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.widget<RoadView>(find.byType(RoadView)).progress, 1);
  });

  testWidgets('Starting a new timer with an active session asks first', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final now = DateTime(2026, 6, 10, 8, 10);
    await const ActiveActivityTimerSessionStore().save(
      ActiveActivityTimerSession(
        sessionId: 'active-session',
        startedAt: DateTime(2026, 6, 10, 8),
        config: ActivityTimerConfig.defaults().copyWith(
          childName: '지율',
          duration: const Duration(minutes: 35),
        ),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

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
            duration: const Duration(minutes: 25),
            markerMode: ActivityMarkerMode.off,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => now,
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _startTimerBuilder(tester);

    expect(find.text('진행 중인 타이머가 있어요'), findsOneWidget);
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).actions,
      hasLength(2),
    );
    expect(find.byType(TimerScreen), findsNothing);

    await tester.tap(find.text('새로 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.restoredSession, isNull);
    expect(timerScreen.config.duration, const Duration(minutes: 2));
  });

  testWidgets('Timer builder shows all manual marker choices', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _selectTimerBuilderManualMode(tester);
    expect(tester.takeException(), isNull);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timerBuilderSelectedMarkerCount')),
      findsOneWidget,
    );
    expect(find.text('0/5개 선택'), findsOneWidget);
    expect(find.text('마커를 1~5개 선택해요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_top_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_bottom_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_cover')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_blocks')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderMarker_star')),
      findsOneWidget,
    );
    expect(find.text('안쪽 꼼꼼'), findsNothing);
    expect(find.text('마무리 헹굼'), findsNothing);

    for (final markerId in [
      'top_teeth',
      'bottom_teeth',
      'molars',
      'tongue',
      'star',
    ]) {
      tester
          .widget<ChoiceChip>(
            find.byKey(ValueKey('timerBuilderMarker_$markerId')),
          )
          .onSelected!(true);
      await tester.pump();
    }

    expect(find.text('5/5개 선택'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('timerBuilderMarker_cover')),
          )
          .onSelected,
      isNull,
    );
    expect(find.byType(TimerScreen), findsNothing);
  });

  testWidgets('Timer builder can switch to manual marker mode', (tester) async {
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
            duration: const Duration(minutes: 25),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsOneWidget);
    expect(find.text('2. 마커'), findsOneWidget);

    await _selectTimerBuilderManualMode(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderMarker_top_teeth')),
      findsOneWidget,
    );
  });

  testWidgets('Timer builder auto marker starts timer without manual choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.off,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_top_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_bottom_teeth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_star')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderAutoMarkerPreview_flag')),
      findsOneWidget,
    );
    await _startTimerBuilder(tester);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsNothing);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
      hasLength(
        ActivityMarkerCatalog.autoSelectionIdsForActivity('brushing').length,
      ),
    );
    expect(
      tester
          .widget<TimerScreen>(find.byType(TimerScreen))
          .config
          .selectedMarkerIds,
      isEmpty,
    );
  });

  testWidgets('Timer builder automatic marker starts timer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.activityDefault,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _startTimerBuilder(tester);

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsNothing);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
      hasLength(
        ActivityMarkerCatalog.autoSelectionIdsForActivity('brushing').length,
      ),
    );
    expect(
      tester
          .widget<TimerScreen>(find.byType(TimerScreen))
          .config
          .selectedMarkerIds,
      isEmpty,
    );
  });

  testWidgets('Starting timer builder opens timer screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _startTimerBuilder(tester);

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
      const Duration(minutes: 2),
    );
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
      hasLength(ActivityMarkerCatalog.maxSelectableMarkerCount),
    );
  });

  testWidgets(
    'Selecting timer builder markers opens timer with selected markers',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(() async {
        await const ActiveActivityTimerSessionStore().clear();
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
              duration: const Duration(minutes: 25),
              markerMode: ActivityMarkerMode.manual,
            ),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      await _openTimerBuilder(tester);
      await _selectTimerBuilderManualMarkers(tester, [
        'top_teeth',
        'bottom_teeth',
      ]);
      await _startTimerBuilder(tester);

      expect(
        tester.widget<TimerScreen>(find.byType(TimerScreen)).config.markerIds,
        ['top_teeth', 'bottom_teeth'],
      );
      expect(
        tester
            .widget<TimerScreen>(find.byType(TimerScreen))
            .config
            .selectedMarkerIds,
        ['top_teeth', 'bottom_teeth'],
      );
    },
  );

  testWidgets('Timer builder saves the latest started timer preset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalRecentTimerService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 9),
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _selectTimerBuilderActivity(tester, 'reading');
    await _setTimerBuilderMinutes(tester, 18);
    await _selectTimerBuilderManualMarkers(tester, ['cover', 'bookmark']);
    await _startTimerBuilder(tester);

    final preset = await const LocalRecentTimerService().load();
    expect(preset, isNotNull);
    expect(preset!.activityId, 'reading');
    expect(preset.duration, const Duration(minutes: 18));
    expect(preset.markerMode, ActivityMarkerMode.manual);
    expect(preset.markerIds, ['cover', 'bookmark']);
    expect(preset.selectedMarkerIds, ['cover', 'bookmark']);
    expect(preset.updatedAt, DateTime(2026, 6, 14, 9));
  });

  testWidgets('Timer builder applies a saved recent timer preset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalRecentTimerService().clear();
    });
    await const LocalRecentTimerService().save(
      ActivityTimerPreset(
        activityId: 'brushing',
        duration: Duration(minutes: 18),
        markerMode: ActivityMarkerMode.manual,
        markerIds: ['cover', 'bookmark'],
        selectedMarkerIds: ['cover', 'bookmark'],
        updatedAt: DateTime(2026, 6, 14, 8),
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderRecentPresetCard')),
      findsOneWidget,
    );
    expect(find.text('최근 설정'), findsOneWidget);
    expect(find.textContaining('양치 · 18분'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('timerBuilderRecentPresetApplyButton')),
    );
    await tester.pump();
    await _startTimerBuilder(tester);

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.config.activityId, 'brushing');
    expect(timerScreen.config.duration, const Duration(minutes: 18));
    expect(timerScreen.config.markerMode, ActivityMarkerMode.manual);
    expect(timerScreen.config.markerIds, ['cover', 'bookmark']);
    expect(timerScreen.config.selectedMarkerIds, ['cover', 'bookmark']);
  });

  testWidgets('Timer builder saves a reusable timer preset', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 10),
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _selectTimerBuilderActivity(tester, 'reading');
    await _setTimerBuilderMinutes(tester, 18);
    await _selectTimerBuilderManualMarkers(tester, ['cover', 'bookmark']);
    await _saveTimerBuilderPreset(tester);

    final presets = await const LocalSavedTimerPresetService().load();
    expect(presets, hasLength(1));
    expect(presets.first.activityId, 'reading');
    expect(presets.first.duration, const Duration(minutes: 18));
    expect(presets.first.markerMode, ActivityMarkerMode.manual);
    expect(presets.first.selectedMarkerIds, ['cover', 'bookmark']);
    expect(presets.first.updatedAt, DateTime(2026, 6, 14, 10));
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCard_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCount')),
      findsOneWidget,
    );
    expect(find.text('1/5개'), findsOneWidget);
    expect(find.text('저장한 타이머'), findsOneWidget);
    expect(find.text('저장했어요.'), findsOneWidget);
  });

  testWidgets('Timer builder shows the saved timer preset limit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });

    final savedTimerPresetService = const LocalSavedTimerPresetService();
    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxSavedPresets;
      index += 1
    ) {
      await savedTimerPresetService.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: Duration(minutes: 10 + index),
          markerMode: ActivityMarkerMode.activityDefault,
          markerIds: const ['star'],
          selectedMarkerIds: const [],
          updatedAt: DateTime(2026, 6, 14, index),
          customName: '저장 $index',
        ),
      );
    }

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 12),
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    expect(find.text('5/5개'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetLimitHint')),
      findsOneWidget,
    );
    expect(find.text('저장한 타이머 5/5개'), findsOneWidget);
    expect(find.text('새로 저장하면 가장 오래된 타이머가 정리돼요.'), findsOneWidget);

    await _selectTimerBuilderActivity(tester, 'reading');
    await _setTimerBuilderMinutes(tester, 18);
    await _saveTimerBuilderPreset(tester);

    final presets = await savedTimerPresetService.load();
    expect(presets, hasLength(LocalSavedTimerPresetService.maxSavedPresets));
    expect(find.text('5/5개'), findsOneWidget);
    expect(find.text('저장했어요. 오래된 타이머는 자동으로 정리돼요.'), findsOneWidget);
  });

  testWidgets('Timer builder toggles saved timer home favorites', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });
    const savedTimerPresetService = LocalSavedTimerPresetService();
    await savedTimerPresetService.save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: const Duration(minutes: 15),
        markerMode: ActivityMarkerMode.activityDefault,
        updatedAt: DateTime(2026, 6, 14, 8),
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    expect(find.byTooltip('홈에 표시'), findsOneWidget);
    tester
        .widget<IconButton>(
          find.byKey(const ValueKey('timerBuilderSavedPresetFavoriteButton_0')),
        )
        .onPressed!();
    await tester.pump();

    var presets = await savedTimerPresetService.load();
    expect(presets.first.isFavorite, isTrue);
    expect(find.byTooltip('홈에서 숨기기'), findsOneWidget);

    tester
        .widget<IconButton>(
          find.byKey(const ValueKey('timerBuilderSavedPresetFavoriteButton_0')),
        )
        .onPressed!();
    await tester.pump();

    presets = await savedTimerPresetService.load();
    expect(presets.first.isFavorite, isFalse);
    expect(find.byTooltip('홈에 표시'), findsOneWidget);
  });

  testWidgets('Timer builder shows the home favorite limit message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });
    const savedTimerPresetService = LocalSavedTimerPresetService();
    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxFavoritePresets + 1;
      index += 1
    ) {
      await savedTimerPresetService.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: Duration(minutes: 10 + index),
          markerMode: ActivityMarkerMode.activityDefault,
          updatedAt: DateTime(2026, 6, 14, index),
          customName: '홈 타이머 $index',
        ),
      );
    }

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxFavoritePresets;
      index += 1
    ) {
      tester
          .widget<IconButton>(
            find.byKey(
              ValueKey('timerBuilderSavedPresetFavoriteButton_$index'),
            ),
          )
          .onPressed!();
      await tester.pump();
    }

    tester
        .widget<IconButton>(
          find.byKey(
            ValueKey(
              'timerBuilderSavedPresetFavoriteButton_${LocalSavedTimerPresetService.maxFavoritePresets}',
            ),
          ),
        )
        .onPressed!();
    await tester.pump();

    final presets = await savedTimerPresetService.load();
    expect(
      presets.where((preset) => preset.isFavorite),
      hasLength(LocalSavedTimerPresetService.maxFavoritePresets),
    );
    expect(find.text('홈에는 최대 3개까지 표시할 수 있어요.'), findsOneWidget);
  });

  testWidgets('Home shows favorite saved timer presets for quick start', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
      await const LocalRecentTimerService().clear();
    });
    await const LocalSavedTimerPresetService().save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: Duration(minutes: 18),
        markerMode: ActivityMarkerMode.manual,
        markerIds: ['cover', 'bookmark'],
        selectedMarkerIds: ['cover', 'bookmark'],
        updatedAt: DateTime(2026, 6, 14, 8),
        isFavorite: true,
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('homeFavoriteTimerCard_0')),
      findsOneWidget,
    );
    expect(find.text('책 읽기'), findsOneWidget);
    expect(find.text('18분'), findsOneWidget);
    final favoriteTop = tester
        .getTopLeft(find.byKey(const ValueKey('homeFavoriteTimerCard_0')))
        .dy;
    final createTimerTop = tester
        .getTopLeft(find.byKey(const ValueKey('createTimerCard')))
        .dy;
    expect(favoriteTop, lessThan(createTimerTop));
    final favoriteActionCenter = tester.getCenter(
      find.descendant(
        of: find.byKey(const ValueKey('homeFavoriteTimerCard_0')),
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    final createActionCenter = tester.getCenter(
      find.descendant(
        of: find.byKey(const ValueKey('createTimerCard')),
        matching: find.byIcon(Icons.add_rounded),
      ),
    );
    expect(createActionCenter.dx, closeTo(favoriteActionCenter.dx, 0.1));

    await tester.tap(find.byKey(const ValueKey('homeFavoriteTimerCard_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.config.activityId, 'reading');
    expect(timerScreen.config.duration, const Duration(minutes: 18));
    expect(timerScreen.config.markerMode, ActivityMarkerMode.manual);
    expect(timerScreen.config.markerIds, ['cover', 'bookmark']);
    expect(timerScreen.config.selectedMarkerIds, ['cover', 'bookmark']);
  });

  testWidgets('Timer builder saves a named custom timer preset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 11),
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _selectTimerBuilderActivity(tester, 'custom');
    await _setTimerBuilderMinutes(tester, 12);
    await _saveTimerBuilderPreset(tester);

    expect(find.text('타이머 이름'), findsOneWidget);
    const longCustomName = '피아노연습타이머이름길게입력테스트초과';
    const limitedCustomName = '피아노연습타이머이름길게입력테스트초';
    await tester.enterText(
      find.byKey(const ValueKey('timerBuilderCustomNameField')),
      longCustomName,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('timerBuilderCustomNameField')),
          )
          .controller
          ?.text,
      limitedCustomName,
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('timerBuilderSaveCustomNameButton')),
        )
        .onPressed!();
    await tester.pump();

    final presets = await const LocalSavedTimerPresetService().load();
    expect(presets, hasLength(1));
    expect(presets.first.activityId, 'custom');
    expect(presets.first.customName, limitedCustomName);
    expect(find.textContaining('$limitedCustomName · 12분'), findsOneWidget);
  });

  testWidgets('Timer builder can save a custom timer as Other without a name', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
          now: () => DateTime(2026, 6, 14, 11),
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _selectTimerBuilderActivity(tester, 'custom');
    await _saveTimerBuilderPreset(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('timerBuilderUseOtherNameButton')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final presets = await const LocalSavedTimerPresetService().load();
    expect(presets, hasLength(1));
    expect(presets.first.customName, isNull);
    expect(find.textContaining('기타 · 10분'), findsOneWidget);
  });

  testWidgets('Timer builder applies and deletes a saved timer preset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
      await const LocalSavedTimerPresetService().clear();
    });
    await const LocalSavedTimerPresetService().save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: Duration(minutes: 18),
        markerMode: ActivityMarkerMode.manual,
        markerIds: ['cover', 'bookmark'],
        selectedMarkerIds: ['cover', 'bookmark'],
        updatedAt: DateTime(2026, 6, 14, 8),
      ),
    );

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
          config: ActivityTimerConfig.defaults().copyWith(childName: '지율'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCard_0')),
      findsOneWidget,
    );
    expect(find.textContaining('책 읽기 · 18분'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('timerBuilderSavedPresetApplyButton_0')),
    );
    await tester.pump();
    await _startTimerBuilder(tester);

    var timerScreen = tester.widget<TimerScreen>(find.byType(TimerScreen));
    expect(timerScreen.config.activityId, 'reading');
    expect(timerScreen.config.duration, const Duration(minutes: 18));
    expect(timerScreen.config.markerIds, ['cover', 'bookmark']);

    Navigator.of(tester.element(find.byType(TimerScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await _openTimerBuilder(tester);

    tester
        .widget<IconButton>(
          find.byKey(const ValueKey('timerBuilderSavedPresetDeleteButton_0')),
        )
        .onPressed!();
    await tester.pump();

    expect(await const LocalSavedTimerPresetService().load(), isEmpty);
    expect(
      find.byKey(const ValueKey('timerBuilderSavedPresetCard_0')),
      findsNothing,
    );
  });

  testWidgets('Dismissing the timer builder does not open timer screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
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
            duration: const Duration(minutes: 25),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsNothing);
    expect(find.byType(TimerScreen), findsNothing);
  });

  testWidgets('Timer builder shows MVP activities and default durations', (
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
          config: ActivityTimerConfig.defaults().copyWith(
            childName: '지율',
            duration: const Duration(minutes: 15),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);
    await _openTimerBuilder(tester);

    expect(find.text('양치'), findsOneWidget);
    expect(find.text('책 읽기'), findsOneWidget);
    expect(find.text('정리'), findsOneWidget);
    expect(find.text('놀이'), findsOneWidget);
    expect(find.text('식사'), findsOneWidget);
    expect(find.text('기타'), findsOneWidget);
    expect(find.text('2분'), findsOneWidget);

    await _selectTimerBuilderActivity(tester, 'reading');

    expect(find.text('15분'), findsOneWidget);
  });

  testWidgets('Timer builder does not overwrite default duration', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
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
            duration: const Duration(minutes: 35),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );
    await tester.pump();

    await _openTimerBuilder(tester);
    await _selectTimerBuilderActivity(tester, 'reading');

    expect(find.byKey(const ValueKey('timerBuilderSheet')), findsOneWidget);
    expect(find.byType(TimerScreen), findsNothing);

    await _startTimerBuilder(tester);

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
      const Duration(minutes: 15),
    );
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).config.activityId,
      'reading',
    );
    expect(changedConfig, isNull);
  });

  testWidgets(
    'Timer motivation settings do not overwrite default activity duration',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(() async {
        await const ActiveActivityTimerSessionStore().clear();
      });
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
              duration: const Duration(minutes: 35),
              markerMode: ActivityMarkerMode.manual,
            ),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (config) => changedConfig = config,
          ),
        ),
      );
      await tester.pump();

      await _openTimerBuilder(tester);
      await _selectTimerBuilderActivity(tester, 'reading');
      await _startTimerBuilder(tester);

      expect(find.byType(TimerScreen), findsOneWidget);
      expect(
        tester.widget<TimerScreen>(find.byType(TimerScreen)).config.duration,
        const Duration(minutes: 15),
      );

      await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
          )
          .onChanged!(false);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('motivationSettingsApplyButton')),
      );
      await tester.pump();

      expect(changedConfig?.duration, const Duration(minutes: 35));
      expect(changedConfig?.motivationVideoEnabled, isFalse);
      expect(
        changedConfig?.markerIds,
        ActivityCatalog.defaultActivity.markerIds,
      );
    },
  );

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
    await _pumpHomeAvatarFileCheck(tester);

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
    await tester.pump();
  });

  testWidgets(
    'Home screen falls back to default avatar state when file is missing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

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
      await _pumpHomeAvatarFileCheck(tester);

      expect(find.text('기본 얼굴 사용 중'), findsOneWidget);
      expect(find.text('만들기'), findsOneWidget);
      expect(find.text('아이 얼굴 탑승 중'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Home screen shows saved avatar only on its vehicle choice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final avatarFile = _createTemporaryAvatarImage();
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
    await _pumpHomeAvatarFileCheck(tester);

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

    await tester.tap(_vehicleChoiceFinder('police_car'));
    await tester.pumpAndSettle();
    await _pumpHomeAvatarFileCheck(tester);

    expect(changedConfig?.vehicleId, 'police_car');
    expect(find.text('아이 얼굴 탑승 중'), findsOneWidget);
    expect(find.text('기본 얼굴 사용 중'), findsNothing);

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
    await _pumpAvatarSetupScreen(tester, ActivityTimerConfig.defaults());

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
      ActivityTimerConfig.defaults(),
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
      ActivityTimerConfig.defaults().copyWith(vehicleId: 'fire_truck'),
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
      ActivityTimerConfig.defaults().copyWith(vehicleId: 'police_car'),
    );

    await tester.tap(find.text('직접 만든 아바타 사용'));
    await tester.pump();
    await _scrollAvatarPromptIntoView(tester);
    expect(_avatarPromptText(tester), contains('경찰'));
  });

  testWidgets('Avatar setup vehicle selection updates prompt and config', (
    tester,
  ) async {
    ActivityTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
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
    await _pumpAvatarSetupScreen(tester, ActivityTimerConfig.defaults());

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
    ActivityTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
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
    ActivityTimerConfig? changedConfig;
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
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
    expect(find.text('이 모습으로 Timey Rider를 탈까요?'), findsOneWidget);
  });

  testWidgets('Avatar setup initializes from custom config', (tester) async {
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
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
      ActivityTimerConfig.defaults().copyWith(
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
      ActivityTimerConfig.defaults().copyWith(
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
      ActivityTimerConfig.defaults().copyWith(
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
    ActivityTimerConfig? changedConfig;
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults().copyWith(
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
    ActivityTimerConfig? changedConfig;
    final avatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
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
    ActivityTimerConfig? changedConfig;
    final busAvatarFile = _createTemporaryAvatarImage();
    final fireTruckAvatarFile = _createTemporaryAvatarImage();
    await _pumpAvatarSetupScreen(
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
      ActivityTimerConfig? changedConfig;
      final busAvatarFile = _createTemporaryAvatarImage();
      final fireTruckAvatarFile = _createTemporaryAvatarImage();
      await _pumpAvatarSetupScreen(
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
    ActivityTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
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
    ActivityTimerConfig? changedConfig;
    await _pumpAvatarSetupScreen(
      tester,
      ActivityTimerConfig.defaults(),
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
    SharedPreferences.setMockInitialValues({
      'durationMinutes': 25,
      'markerMode': 'off',
    });

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('남은 시간 보여주기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('남은 시간 보여주기'), findsOneWidget);
    await tester.tap(find.text('남은 시간 보여주기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await _openTimerBuilder(tester);
    await _startTimerBuilder(tester);

    expect(find.textContaining('남은 시간'), findsNothing);
  });

  testWidgets('Settings screen opens Korean parent guide', (tester) async {
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
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('userGuideSettingsTile')), findsOneWidget);
    expect(find.text('사용 안내'), findsOneWidget);
    expect(find.text('활동 미션, 응원 영상, 스티커 규칙을 확인해요.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('userGuideSettingsTile')));
    await tester.pumpAndSettle();

    expect(find.byType(UserGuideScreen), findsOneWidget);
    expect(find.text('사용 안내'), findsOneWidget);
    expect(find.text('보호자 가이드'), findsOneWidget);
    expect(
      find.textContaining('아이의 루틴을 함께 돕는 보호자도 참고할 수 있어요.'),
      findsOneWidget,
    );
  });

  testWidgets('User guide uses English localization', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('ko'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: UserGuideScreen(),
      ),
    );

    expect(find.text('Parent Guide'), findsWidgets);
    expect(find.textContaining('parents and other caregivers'), findsOneWidget);
    expect(
      find.text('Review activity missions, cheer videos, and sticker rules.'),
      findsOneWidget,
    );
    expect(find.text('What is Timey Rider?'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Course markers'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Course markers'), findsOneWidget);
    expect(
      find.textContaining('Only manually chosen picture markers'),
      findsOneWidget,
    );
  });

  testWidgets('User guide shows key Korean guide copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: [Locale('ko'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: UserGuideScreen(),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('코스 마커'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('코스 마커'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('직접 고른 그림 마커').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('직접 고른 그림 마커'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('동기부여 영상'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('동기부여 영상'), findsOneWidget);
    expect(find.textContaining('일부 구간을 건너뛸 수 있어요'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('스티커 받기를 선택하면 랜덤 성공 스티커'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('스티커'), findsWidgets);
  });

  testWidgets('Settings screen opens course marker help sheet', (tester) async {
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
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('markerModeHelpButton')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('markerModeHelpButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('markerModeHelpButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.textContaining('직접 고른 그림 마커'), findsWidgets);
  });

  testWidgets('Settings screen updates course marker mode', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var latestConfig = ActivityTimerConfig.defaults();

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
          config: latestConfig,
          onConfigChanged: (config) => latestConfig = config,
        ),
      ),
    );

    expect(find.text('코스 마커'), findsOneWidget);
    final segmentedButtonFinder = find.byKey(
      const ValueKey('markerModeSegmentedButton'),
    );
    final segmentedButton = tester.widget<SegmentedButton<ActivityMarkerMode>>(
      segmentedButtonFinder,
    );
    final segmentedButtonRect = tester.getRect(segmentedButtonFinder);
    final cardRect = tester.getRect(
      find.ancestor(of: segmentedButtonFinder, matching: find.byType(Card)),
    );
    expect(segmentedButton.selected, {ActivityMarkerMode.activityDefault});
    expect(segmentedButton.showSelectedIcon, isFalse);
    expect(segmentedButtonRect.left, greaterThanOrEqualTo(cardRect.left));
    expect(segmentedButtonRect.right, lessThanOrEqualTo(cardRect.right));
    expect(find.text('사용 안 함'), findsOneWidget);
    expect(find.text('직접 선택'), findsOneWidget);
    expect(find.text('자동'), findsOneWidget);
    expect(find.text('활동에 맞게'), findsNothing);
    expect(
      find.text('자동은 활동에 맞는 그림 마커를 미리 보여주고 사용해요. 직접 고른 그림 마커만 활동 기록에 남아요.'),
      findsOneWidget,
    );

    segmentedButton.onSelectionChanged!({ActivityMarkerMode.manual});
    await tester.pump();

    expect(latestConfig.markerMode, ActivityMarkerMode.manual);
  });

  testWidgets('Settings screen updates motivation video settings', (
    tester,
  ) async {
    var latestConfig = ActivityTimerConfig.defaults();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(
          config: latestConfig,
          onConfigChanged: (config) => latestConfig = config,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
        )
        .onChanged!(true);
    await tester.pump();

    expect(latestConfig.motivationVideoUseCustomInterval, isTrue);
    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsOneWidget,
    );

    tester
        .widget<SegmentedButton<int>>(
          find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
        )
        .onSelectionChanged!({10});
    await tester.pump();

    expect(latestConfig.motivationVideoInterval, const Duration(minutes: 10));

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        )
        .onChanged!(false);
    await tester.pump();

    expect(latestConfig.motivationVideoEnabled, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
          )
          .onChanged,
      isNull,
    );
    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsNothing,
    );
  });

  testWidgets('Settings screen opens motivation video help sheet', (
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
        home: SettingsScreen(
          config: ActivityTimerConfig.defaults(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('motivationVideoHelpButton')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('motivationVideoHelpButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('motivationVideoHelpButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appHelpSheet')), findsOneWidget);
    expect(find.text('동기부여 영상 안내'), findsWidgets);
    expect(find.textContaining('일부 구간을 건너뛸 수 있어요'), findsOneWidget);
    expect(find.textContaining('3분, 5분, 10분'), findsOneWidget);
  });

  testWidgets('Home settings apply motivation video settings to new timers', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
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
            duration: const Duration(minutes: 25),
            markerMode: ActivityMarkerMode.manual,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
        )
        .onChanged!(true);
    await tester.pump();

    tester
        .widget<SegmentedButton<int>>(
          find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
        )
        .onSelectionChanged!({5});
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(changedConfig?.motivationVideoUseCustomInterval, isTrue);
    expect(changedConfig?.motivationVideoInterval, const Duration(minutes: 5));

    await _openTimerBuilder(tester);
    await _startTimerBuilder(tester);

    final timerConfig = tester
        .widget<TimerScreen>(find.byType(TimerScreen))
        .config;
    expect(timerConfig.duration, const Duration(minutes: 2));
    expect(timerConfig.motivationVideoUseCustomInterval, isTrue);
    expect(timerConfig.motivationVideoInterval, const Duration(minutes: 5));
  });

  testWidgets('Settings screen keeps vehicle and avatar actions on home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('아바타 설정'), findsNothing);
    expect(find.text('기본 이미지 사용 중'), findsNothing);
    expect(find.text('아바타 설정하기'), findsNothing);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(_vehicleChoiceFinder('motorcycle'), findsNothing);
  });

  testWidgets('Settings screen hides custom avatar state when active', (
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
          config: ActivityTimerConfig.defaults().copyWith(
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

    expect(find.text('아바타 설정'), findsNothing);
    expect(find.text('직접 만든 아바타 사용 중'), findsNothing);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(find.byType(VehicleSelectionCard), findsNothing);
  });

  testWidgets('Home screen shows vehicle summary above timer builder', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.byKey(const ValueKey('createTimerCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);
    expect(find.text('빠방 고르기'), findsNothing);
    expect(find.text('변경'), findsOneWidget);
    expect(find.text('오토바이'), findsNothing);
    expect(find.text('소방차'), findsNothing);
    expect(find.text('경찰차'), findsNothing);
    expect(find.text('포크레인'), findsNothing);

    for (final vehicle in VehicleCatalog.all) {
      expect(
        _assetImage(vehicle.selectionImagePath),
        vehicle.id == 'motorcycle' ? findsOneWidget : findsNothing,
      );
    }
    expect(
      find.byKey(const ValueKey('selectedVehiclePreview')),
      findsOneWidget,
    );
    expect(_vehicleChoiceFinder('motorcycle'), findsNothing);

    final vehicleTitleTop = tester.getTopLeft(find.text('오늘의 빠방')).dy;
    final timerBuilderTop = tester
        .getTopLeft(find.byKey(const ValueKey('createTimerCard')))
        .dy;
    expect(timerBuilderTop, greaterThan(vehicleTitleTop));

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();

    expect(find.text('빠방 고르기'), findsOneWidget);
    expect(_vehicleChoiceFinder('motorcycle'), findsOneWidget);
    expect(
      tester.getSize(_vehicleChoiceFinder('motorcycle')).width,
      tester.getSize(_vehicleChoiceFinder('fire_truck')).width,
    );
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

  testWidgets(
    'Vehicle selection card limits custom avatar size in selected preview',
    (tester) async {
      final avatarFile = _createTemporaryAvatarImage();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: VehicleSelectionCard(
                title: '차량 선택',
                selectedVehicleId: 'fire_truck',
                onVehicleSelected: (_) {},
                showSelectedPreview: true,
                showChoices: false,
                avatar: VehicleAvatarPresentation(
                  mode: AvatarImageMode.custom,
                  imagePath: avatarFile.path,
                  scale: 1.25,
                  offsetX: 0.07,
                  offsetY: -0.03,
                  rotationDegrees: 5.0,
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

      expect(
        find.byKey(const ValueKey('selectedVehiclePreview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('avatarCompositeOverlayImage')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) {
          return widget is AvatarCompositePreview &&
              widget.vehicle.id == 'fire_truck' &&
              widget.size == 96.0 &&
              widget.avatarScale == 1.25 &&
              widget.avatarOffsetX == 0.07 &&
              widget.avatarOffsetY == -0.03 &&
              widget.avatarRotationDegrees == 5.0;
        }),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Selected vehicle on home is saved to preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('ko'));

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();
    await tester.tap(_vehicleChoiceFinder('police_car'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('vehicleId'), 'police_car');
    expect(
      _assetImage(VehicleCatalog.policeCar.selectionImagePath),
      findsOneWidget,
    );
    expect(
      _assetImage(VehicleCatalog.motorcycle.selectionImagePath),
      findsNothing,
    );
  });

  testWidgets('Vehicle selection updates even without parent rebuild', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ActivityTimerConfig? changedConfig;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            childName: '지율',
            vehicleId: 'fire_truck',
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('vehiclePickerOpenButton')));
    await tester.pumpAndSettle();

    final selectedColor = _vehicleChoiceMaterial(tester, 'fire_truck').color;
    final unselectedColor = _vehicleChoiceMaterial(tester, 'police_car').color;
    expect(selectedColor, isNot(unselectedColor));

    await tester.tap(_vehicleChoiceFinder('police_car'));
    await tester.pumpAndSettle();

    expect(changedConfig?.vehicleId, 'police_car');
    expect(_vehicleChoiceFinder('fire_truck'), findsNothing);
    expect(_vehicleChoiceFinder('police_car'), findsNothing);
    expect(
      _assetImage(VehicleCatalog.policeCar.selectionImagePath),
      findsOneWidget,
    );
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

    expect(find.text('서아의 활동 기록'), findsOneWidget);
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
      lessThan(roadBounds.center.dx),
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

  testWidgets('Road view passes each vehicle course kind to the road painter', (
    tester,
  ) async {
    Future<RoadPainter> pumpRoadPainterForVehicle(
      VehicleDefinition vehicle,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(progress: 0.5, vehicle: vehicle),
            ),
          ),
        ),
      );

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<RoadPainter>();
      expect(painters, isNotEmpty, reason: vehicle.id);
      return painters.single;
    }

    final roadPainter = await pumpRoadPainterForVehicle(
      VehicleCatalog.fireTruck,
    );
    expect(roadPainter.courseKind, VehicleCourseKind.road);

    final skyPainter = await pumpRoadPainterForVehicle(VehicleCatalog.airplane);
    expect(skyPainter.courseKind, VehicleCourseKind.sky);

    final waterPainter = await pumpRoadPainterForVehicle(VehicleCatalog.shark);
    expect(waterPainter.courseKind, VehicleCourseKind.water);

    final railPainter = await pumpRoadPainterForVehicle(VehicleCatalog.train);
    expect(railPainter.courseKind, VehicleCourseKind.rail);

    final fieldPainter = await pumpRoadPainterForVehicle(VehicleCatalog.tRex);
    expect(fieldPainter.courseKind, VehicleCourseKind.field);
  });

  testWidgets('Road view keeps vehicle inside portrait bounds at route ends', (
    tester,
  ) async {
    Future<void> pumpRoad(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(
                progress: progress,
                vehicle: VehicleCatalog.fireTruck,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpRoad(0);
    var roadRect = tester.getRect(find.byType(RoadView));
    var vehicleRect = tester.getRect(find.byType(VehicleWidget));
    expect(vehicleRect.left, greaterThanOrEqualTo(roadRect.left));
    expect(vehicleRect.top, greaterThanOrEqualTo(roadRect.top));
    expect(vehicleRect.right, lessThanOrEqualTo(roadRect.right));
    expect(vehicleRect.bottom, lessThanOrEqualTo(roadRect.bottom));

    await pumpRoad(1);
    roadRect = tester.getRect(find.byType(RoadView));
    vehicleRect = tester.getRect(find.byType(VehicleWidget));
    expect(vehicleRect.left, greaterThanOrEqualTo(roadRect.left));
    expect(vehicleRect.top, greaterThanOrEqualTo(roadRect.top));
    expect(vehicleRect.right, lessThanOrEqualTo(roadRect.right));
    expect(vehicleRect.bottom, lessThanOrEqualTo(roadRect.bottom));
  });

  testWidgets(
    'Road view applies portrait road anchor offset for long vehicles',
    (tester) async {
      const progress = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(progress: progress, vehicle: VehicleCatalog.tRex),
            ),
          ),
        ),
      );
      await tester.pump();

      final roadSize = tester.getSize(find.byType(RoadView));
      final vehicleSize = tester.getSize(find.byType(VehicleWidget)).height;
      final rawRoadPoint = roadPointForProgress(roadSize, progress);
      final expectedVehicleCenterY =
          rawRoadPoint.dy +
          (vehicleSize * VehicleCatalog.tRex.roadAnchorOffset.portraitDyRatio);

      expect(vehicleSize, closeTo(120, 0.1));
      expect(
        tester.getCenter(find.byType(VehicleWidget)).dy,
        closeTo(expectedVehicleCenterY, 1),
      );
    },
  );

  testWidgets('RoadView with 30 markers renders 30 activity markers', (
    tester,
  ) async {
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < markers.length; index += 1) {
      expect(find.byKey(ValueKey('roadActivityMarker_$index')), findsOneWidget);
    }
  });

  testWidgets('RoadView at progress 1 hides activity markers', (tester) async {
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('roadActivityMarker_0')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 1,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < markers.length; index += 1) {
      expect(find.byKey(ValueKey('roadActivityMarker_$index')), findsNothing);
    }
  });

  testWidgets('RoadView keeps long-course vehicle inside viewport', (
    tester,
  ) async {
    Future<void> pumpLongRoad(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(
                progress: progress,
                vehicle: VehicleCatalog.fireTruck,
                courseDuration: const Duration(minutes: 60),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    for (final progress in const [0.0, 0.5, 1.0]) {
      await pumpLongRoad(progress);

      final roadRect = tester.getRect(find.byType(RoadView));
      final vehicleRect = tester.getRect(find.byType(VehicleWidget));
      expect(vehicleRect.left, greaterThanOrEqualTo(roadRect.left));
      expect(vehicleRect.top, greaterThanOrEqualTo(roadRect.top));
      expect(vehicleRect.right, lessThanOrEqualTo(roadRect.right));
      expect(vehicleRect.bottom, lessThanOrEqualTo(roadRect.bottom));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('RoadView keeps long-course activity markers in the road layer', (
    tester,
  ) async {
    final markers = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: RoadView(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              markers: markers,
              markerClearProgress: 0,
              courseDuration: const Duration(minutes: 60),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (var index = 0; index < markers.length; index += 1) {
      expect(find.byKey(ValueKey('roadActivityMarker_$index')), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('RoadPainter roadStrokeWidthForSize stays within expected clamps', () {
    expect(roadStrokeWidthForSize(const Size(100, 640)), 22);
    expect(roadStrokeWidthForSize(const Size(1000, 1200)), 32);
    expect(roadStrokeWidthForSize(const Size(1200, 100)), 30);
    expect(roadStrokeWidthForSize(const Size(1200, 900)), 44);
    expect(roadStrokeWidthForSize(const Size(420, 640)), closeTo(24.36, 0.01));
  });

  test('RoadCourseVisualStyle maps course kinds to distinct palettes', () {
    final roadStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.road,
    );
    final skyStyle = RoadCourseVisualStyle.forCourseKind(VehicleCourseKind.sky);
    final waterStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.water,
    );
    final railStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.rail,
    );
    final fieldStyle = RoadCourseVisualStyle.forCourseKind(
      VehicleCourseKind.field,
    );

    expect(roadStyle.pathColor, const Color(0xFFBCEFD0));
    expect(roadStyle.backgroundColors, hasLength(4));
    expect(roadStyle.backgroundStops, const [0, 0.5, 0.78, 1]);
    expect(skyStyle.pathColor, isNot(roadStyle.pathColor));
    expect(waterStyle.pathColor, isNot(roadStyle.pathColor));
    expect(railStyle.pathColor, isNot(roadStyle.pathColor));
    expect(fieldStyle.pathColor, isNot(roadStyle.pathColor));
    expect(fieldStyle.backgroundColors, hasLength(4));
    expect(fieldStyle.backgroundStops, const [0, 0.48, 0.80, 1]);
  });

  test('RoadPainter uses course-specific flow patterns', () {
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.road),
      RoadPainter.laneDashPatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.sky),
      RoadPainter.skyFlowPatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.water),
      RoadPainter.waterWavePatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.rail),
      RoadPainter.railSleeperPatternLength,
    );
    expect(
      RoadPainter.flowPatternLengthForCourseKind(VehicleCourseKind.field),
      RoadPainter.fieldFlowPatternLength,
    );
    expect(
      RoadPainter.skyPathCloudAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
    expect(
      RoadPainter.waterWaveAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
    expect(
      RoadPainter.railAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
    expect(
      RoadPainter.fieldAnimationDuration,
      greaterThan(RoadPainter.laneDashAnimationDuration),
    );
  });

  test('RoadPainter rail track scales with road width', () {
    final portraitBaseRoadWidth = roadStrokeWidthForSize(const Size(420, 640));
    final landscapeBaseRoadWidth = roadStrokeWidthForSize(
      const Size(1200, 520),
    );
    final portraitRailWidth = RoadPainter.effectiveRoadStrokeWidthForCourseKind(
      VehicleCourseKind.rail,
      portraitBaseRoadWidth,
    );
    final landscapeRailWidth =
        RoadPainter.effectiveRoadStrokeWidthForCourseKind(
          VehicleCourseKind.rail,
          landscapeBaseRoadWidth,
        );

    expect(portraitRailWidth, lessThan(portraitBaseRoadWidth));
    expect(landscapeRailWidth, lessThan(landscapeBaseRoadWidth));
    expect(portraitRailWidth, 14);
    expect(landscapeRailWidth, closeTo(landscapeBaseRoadWidth * 0.52, 0.01));
    expect(
      RoadPainter.effectiveRoadStrokeWidthForCourseKind(
        VehicleCourseKind.road,
        landscapeBaseRoadWidth,
      ),
      landscapeBaseRoadWidth,
    );
    expect(
      RoadPainter.railSleeperHalfLengthForRoadWidth(landscapeRailWidth) * 2,
      greaterThan(landscapeRailWidth),
    );
  });

  testWidgets('RoadPainter renders the sky course clouds safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CustomPaint(
        size: Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.sky,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('RoadPainter renders the water course waves safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CustomPaint(
        size: Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.water,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('RoadPainter renders the rail course track safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CustomPaint(
        size: Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.rail,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('RoadPainter renders the field course details safely', (
    tester,
  ) async {
    final footprintImage = await _createTestFootprintImage();
    addTearDown(footprintImage.dispose);

    await tester.pumpWidget(
      CustomPaint(
        size: const Size(420, 640),
        painter: RoadPainter(
          progress: 0.5,
          laneDashPhase: 12,
          courseKind: VehicleCourseKind.field,
          fieldFootprintImage: footprintImage,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('RoadCourseGeometry keeps five minutes as the current route', () {
    const viewportSize = Size(420, 640);
    final baselinePathLength = createRoadPath(
      viewportSize,
    ).computeMetrics().first.length;
    final geometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 5),
    );
    final shortGeometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 1),
    );

    expect(geometry.viewportSize, viewportSize);
    expect(geometry.canvasSize.width, viewportSize.width);
    expect(geometry.canvasSize.height, closeTo(viewportSize.height, 0.01));
    expect(geometry.rowCount, 9);
    expect(geometry.roadBounds, createRoadBounds(viewportSize));
    expect(
      roadMetricForGeometry(geometry).length,
      closeTo(baselinePathLength, 0.01),
    );
    expect(shortGeometry.canvasSize.height, closeTo(viewportSize.height, 0.01));
    expect(shortGeometry.rowCount, geometry.rowCount);
  });

  test('RoadCourseGeometry keeps landscape baseline at five rows', () {
    const viewportSize = Size(1200, 520);
    final geometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 5),
    );

    expect(geometry.canvasSize.height, closeTo(viewportSize.height, 0.01));
    expect(geometry.rowCount, 5);
    expect(
      roadMetricForGeometry(geometry).length,
      closeTo(createRoadPath(viewportSize).computeMetrics().first.length, 0.01),
    );
  });

  test('RoadCourseGeometry scales long route path metrics by duration', () {
    const viewportSize = Size(420, 640);
    final baselineGeometry = createRoadCourseGeometry(
      viewportSize: viewportSize,
      duration: const Duration(minutes: 5),
    );
    final baselineLength = roadMetricForGeometry(baselineGeometry).length;
    var previousRowCount = baselineGeometry.rowCount;
    var previousCanvasHeight = baselineGeometry.canvasSize.height;

    for (final expectation in const [
      (minutes: 15, factor: 3.0),
      (minutes: 25, factor: 5.0),
      (minutes: 35, factor: 7.0),
      (minutes: 60, factor: 12.0),
    ]) {
      final geometry = createRoadCourseGeometry(
        viewportSize: viewportSize,
        duration: Duration(minutes: expectation.minutes),
      );
      final lengthRatio =
          roadMetricForGeometry(geometry).length / baselineLength;

      expect(geometry.rowCount, greaterThan(previousRowCount));
      expect(geometry.canvasSize.height, greaterThan(previousCanvasHeight));
      expect(lengthRatio, closeTo(expectation.factor, 0.12));
      expect(
        roadStrokeWidthForSize(geometry.viewportSize),
        closeTo(24.36, 0.01),
      );

      previousRowCount = geometry.rowCount;
      previousCanvasHeight = geometry.canvasSize.height;
    }
  });

  test('RoadCourseGeometry camera follows long courses toward the finish', () {
    final geometry = createRoadCourseGeometry(
      viewportSize: const Size(420, 640),
      duration: const Duration(minutes: 60),
    );
    final startOffset = roadCameraOffsetForGeometryProgress(
      geometry: geometry,
      progress: 0,
    );
    final middleOffset = roadCameraOffsetForGeometryProgress(
      geometry: geometry,
      progress: 0.5,
    );
    final finishOffset = roadCameraOffsetForGeometryProgress(
      geometry: geometry,
      progress: 1,
    );

    expect(startOffset, greaterThan(middleOffset));
    expect(middleOffset, greaterThan(finishOffset));
    expect(finishOffset, closeTo(0, 0.01));
    expect(
      startOffset,
      lessThanOrEqualTo(
        geometry.canvasSize.height - geometry.viewportSize.height,
      ),
    );
  });

  test('RoadPainter repaints for progress or lane dash phase changes', () {
    const basePainter = RoadPainter(progress: 0.3, laneDashPhase: 0);
    final geometry = createRoadCourseGeometry(
      viewportSize: const Size(420, 640),
      duration: const Duration(minutes: 15),
    );

    expect(
      basePainter.shouldRepaint(
        const RoadPainter(progress: 0.3, laneDashPhase: 10),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(progress: 0.4, laneDashPhase: 0),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(progress: 0.3, laneDashPhase: 0),
      ),
      isFalse,
    );
    expect(
      basePainter.shouldRepaint(
        RoadPainter(progress: 0.3, laneDashPhase: 0, geometry: geometry),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          courseKind: VehicleCourseKind.sky,
        ),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          courseKind: VehicleCourseKind.water,
        ),
      ),
      isTrue,
    );
    expect(
      basePainter.shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          courseKind: VehicleCourseKind.rail,
        ),
      ),
      isTrue,
    );
    expect(
      const RoadPainter(
        progress: 0.3,
        laneDashPhase: 0,
        courseKind: VehicleCourseKind.sky,
      ).shouldRepaint(
        const RoadPainter(
          progress: 0.3,
          laneDashPhase: 0,
          skyPathCloudPhase: 8,
          courseKind: VehicleCourseKind.sky,
        ),
      ),
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

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadMotivationVideoLayer(
              assetPath: MotivationAssetCatalog.fallbackVideoPath,
              milestone: 10,
              reservedRightInset: 92,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final insetVideoRect = tester.getRect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );
    expect(insetVideoRect.right, lessThanOrEqualTo(1200 - 16 - 92));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('RoadView keeps motivation video fixed while long road scrolls', (
    tester,
  ) async {
    Future<void> pumpLongRoadWithVideo(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 640,
              child: RoadView(
                progress: progress,
                vehicle: VehicleCatalog.fireTruck,
                motivationVideoAssetPath:
                    MotivationAssetCatalog.fallbackVideoPath,
                motivationVideoMilestone: 10,
                courseDuration: const Duration(minutes: 60),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpLongRoadWithVideo(0);
    final startRect = tester.getRect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );

    await pumpLongRoadWithVideo(0.5);
    final middleRect = tester.getRect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
    );

    expect(middleRect.left, closeTo(startRect.left, 0.1));
    expect(middleRect.top, closeTo(startRect.top, 0.1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('RoadVehicleLayer keeps long-course vehicle inside viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 520,
            child: RoadVehicleLayer(
              progress: 0.5,
              vehicle: VehicleCatalog.fireTruck,
              courseDuration: const Duration(minutes: 60),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final layerRect = tester.getRect(find.byType(RoadVehicleLayer));
    final vehicleRect = tester.getRect(find.byType(VehicleWidget));
    expect(vehicleRect.left, greaterThanOrEqualTo(layerRect.left));
    expect(vehicleRect.top, greaterThanOrEqualTo(layerRect.top));
    expect(vehicleRect.right, lessThanOrEqualTo(layerRect.right));
    expect(vehicleRect.bottom, lessThanOrEqualTo(layerRect.bottom));
    expect(tester.takeException(), isNull);

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
          config: ActivityTimerConfig.defaults().copyWith(
            vehicleId: 'excavator',
            avatarMode: AvatarImageMode.custom,
            customAvatarImagePath: avatarFile.path,
            customAvatarVehicleId: 'police_car',
          ),
          activityProgressService: LocalActivityProgressService(),
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
          config: ActivityTimerConfig.defaults().copyWith(
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
          activityProgressService: LocalActivityProgressService(),
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

  testWidgets('TimerScreen passes marker ids to road markers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            markerIds: const ['top_teeth', 'bottom_teeth'],
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(
      roadView.markers,
      hasLength(
        ActivityMarkerCatalog.courseSlotCountForDuration(
          ActivityTimerConfig.defaults().duration,
        ),
      ),
    );
    expect(roadView.markers.map((marker) => marker.id).toSet(), {
      'top_teeth',
      'bottom_teeth',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerScreen hides road markers when marker mode is off', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            markerMode: ActivityMarkerMode.off,
            markerIds: const [],
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.markers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerScreen passes configured duration to the road course', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.courseDuration, const Duration(minutes: 60));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerScreen saves an active session when started', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final startedAt = DateTime(2026, 6, 10, 8);
    final store = ActiveActivityTimerSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 35),
            childName: '지율',
            vehicleId: 'bus',
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => startedAt,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final session = await store.load();
    expect(session, isNotNull);
    expect(session!.startedAt, startedAt);
    expect(session.duration, const Duration(minutes: 35));
    expect(session.config.childName, '지율');
    expect(session.config.vehicleId, 'bus');
    expect(session.state, ActiveActivityTimerSessionState.running);
    expect(session.totalPausedDuration, Duration.zero);
    expect(session.pausedAt, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen updates active session when paused and resumed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime(2026, 6, 10, 8);
    final store = ActiveActivityTimerSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 35),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 250));
    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();

    final pausedSession = await store.load();
    expect(pausedSession, isNotNull);
    expect(pausedSession!.state, ActiveActivityTimerSessionState.paused);
    expect(pausedSession.pausedAt, now);
    expect(pausedSession.totalPausedDuration, Duration.zero);

    now = now.add(const Duration(minutes: 3));
    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();

    final resumedSession = await store.load();
    expect(resumedSession, isNotNull);
    expect(resumedSession!.state, ActiveActivityTimerSessionState.running);
    expect(resumedSession.pausedAt, isNull);
    expect(resumedSession.totalPausedDuration, const Duration(minutes: 3));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen clears active session after completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = ActiveActivityTimerSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(await store.load(), isNotNull);

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(await store.load(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen restores progress from an active session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    final startedAt = DateTime(2026, 6, 10, 8);
    final now = startedAt.add(const Duration(minutes: 20));
    final session = ActiveActivityTimerSession(
      sessionId: 'active-session',
      startedAt: startedAt,
      config: ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(minutes: 60),
        vehicleId: 'bus',
      ),
      state: ActiveActivityTimerSessionState.running,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: session,
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final roadView = tester.widget<RoadView>(find.byType(RoadView));
    expect(roadView.courseDuration, const Duration(minutes: 60));
    expect(roadView.vehicle.id, 'bus');
    expect(roadView.progress, closeTo(1 / 3, 0.01));
    expect(
      tester.widget<TimerScreen>(find.byType(TimerScreen)).restoredSession,
      session,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen resumes ticking from a restored paused session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    var now = DateTime(2026, 6, 10, 8, 30);
    final session = ActiveActivityTimerSession(
      sessionId: 'paused-session',
      startedAt: DateTime(2026, 6, 10, 8),
      config: ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(minutes: 30),
      ),
      state: ActiveActivityTimerSessionState.paused,
      pausedAt: DateTime(2026, 6, 10, 8, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          restoredSession: session,
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      closeTo(1 / 3, 0.01),
    );

    tester
        .widget<TimerControlBar>(find.byType(TimerControlBar))
        .onPauseResume!();
    await tester.pump();

    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 40));

    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      closeTo(0.4, 0.01),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('TimerScreen refreshes elapsed time when app resumes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      await const ActiveActivityTimerSessionStore().clear();
    });
    var now = DateTime(2026, 6, 10, 8);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 25),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<RoadView>(find.byType(RoadView)).progress, 0);

    now = now.add(const Duration(minutes: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      closeTo(0.4, 0.01),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Activity done before arrival does not immediately push result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
    expect(
      tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete,
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Fast finish drive animates display progress to finish', (
    tester,
  ) async {
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 100),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    now = now.add(const Duration(seconds: 50));
    await tester.pump(const Duration(milliseconds: 250));

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    final driveDuration = finishDriveDurationForProgress(0.5);
    await tester.pump(driveDuration - const Duration(milliseconds: 1));

    expect(find.byType(ResultScreen), findsNothing);
    expect(
      tester.widget<RoadView>(find.byType(RoadView)).progress,
      greaterThan(0.99),
    );

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Controls are disabled during fast finish drive', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 10),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    final controls = tester.widget<TimerControlBar>(
      find.byType(TimerControlBar),
    );
    expect(controls.onPauseResume, isNull);
    expect(controls.onComplete, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Completing after arrival opens result without fast finish', (
    tester,
  ) async {
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 1),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Time-ended activity opens result automatically at arrival', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    var now = DateTime(2026);
    final service = LocalActivityProgressService();

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
          config: ActivityTimerConfig.defaults().copyWith(
            activityId: ActivityCatalog.play.id,
            duration: const Duration(seconds: 1),
          ),
          activityProgressService: service,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('시간이 다 되었어요'), findsOneWidget);
    expect(find.text('아이와 함께 돌아본 뒤 스티커를 받을지 선택해 주세요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('resultSkipStickerButton')),
      findsOneWidget,
    );
    expect((await service.loadSnapshot()).history, isEmpty);

    await tester.tap(find.byKey(const ValueKey('resultSkipStickerButton')));
    await tester.pumpAndSettle();

    final snapshot = await service.loadSnapshot();
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.timeEnded,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Timer records directly selected markers on completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    var now = DateTime(2026);
    final service = LocalActivityProgressService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 1),
            markerMode: ActivityMarkerMode.manual,
            markerIds: const ['top_teeth', 'bottom_teeth'],
            selectedMarkerIds: const ['top_teeth', 'bottom_teeth'],
          ),
          activityProgressService: service,
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('resultSkipStickerButton')));
    await tester.pumpAndSettle();

    final snapshot = await service.loadSnapshot();
    expect(snapshot.history.single.selectedMarkerIds, [
      'top_teeth',
      'bottom_teeth',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Timer hands orientation control to result screen', (
    tester,
  ) async {
    var now = DateTime(2026);
    final orientationService = _FakeOrientationService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 1),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
          orientationService: orientationService,
        ),
      ),
    );
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    tester.widget<TimerControlBar>(find.byType(TimerControlBar)).onComplete!();
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(orientationService.calls, [
      'allowTimerOrientations',
      'allowTimerOrientations',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(orientationService.calls, [
      'allowTimerOrientations',
      'allowTimerOrientations',
      'lockPortrait',
    ]);
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
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(seconds: 100),
            soundEnabled: true,
          ),
          activityProgressService: LocalActivityProgressService(),
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

  testWidgets(
    'Timer screen uses three-minute motivation cadence for long timer',
    (tester) async {
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
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      now = now.add(const Duration(minutes: 2, seconds: 59));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Timer screen custom motivation interval ignores percent milestones',
    (tester) async {
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
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 15),
              soundEnabled: false,
              motivationVideoUseCustomInterval: true,
              motivationVideoInterval: const Duration(minutes: 5),
            ),
            activityProgressService: LocalActivityProgressService(),
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsNothing,
      );

      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_10')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Timer screen closes active motivation video when disabled', (
    tester,
  ) async {
    ActivityTimerConfig? changedConfig;
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
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
            soundEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (config) => changedConfig = config,
        ),
      ),
    );
    await tester.pump();

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('motivationVideoBubble_3')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('timerMotivationVideoHelpButton')),
      findsOneWidget,
    );

    tester
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        )
        .onChanged!(false);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('motivationSettingsApplyButton')),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('motivationVideoBubble_3')), findsNothing);
    expect(changedConfig?.motivationVideoEnabled, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'Timer motivation settings dismiss keeps pending changes unapplied',
    (tester) async {
      ActivityTimerConfig? changedConfig;
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
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            now: () => now,
            onConfigChanged: (config) => changedConfig = config,
          ),
        ),
      );
      await tester.pump();

      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
          )
          .onChanged!(false);
      await tester.pump();
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('motivationSettingsCancelButton')),
          )
          .onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(changedConfig, isNull);
      expect(
        find.byKey(const ValueKey('motivationVideoEnabledSwitch')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Timer screen restarts custom motivation interval from change time',
    (tester) async {
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
            config: ActivityTimerConfig.defaults().copyWith(
              duration: const Duration(minutes: 60),
              soundEnabled: false,
            ),
            activityProgressService: LocalActivityProgressService(),
            now: () => now,
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('motivationVideoCustomIntervalSwitch')),
          )
          .onChanged!(true);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('motivationSettingsApplyButton')),
      );
      await tester.pump();

      now = now.add(const Duration(minutes: 2, seconds: 59));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_3')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsNothing,
      );

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('motivationVideoBubble_5')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Timer screen skips motivation videos when disabled', (
    tester,
  ) async {
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
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
            soundEnabled: false,
            motivationVideoEnabled: false,
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('motivationVideoBubble_3')), findsNothing);
    expect(
      find.byKey(const ValueKey('motivationVideoBubble_10')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Timer screen keeps vehicle fixed when paused', (tester) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var now = DateTime(2026);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
          ),
          activityProgressService: LocalActivityProgressService(),
          now: () => now,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    now = now.add(const Duration(minutes: 20));
    await tester.pump(const Duration(milliseconds: 250));

    Offset vehicleCenterInRoad() {
      final roadRect = tester.getRect(find.byType(RoadView));
      final vehicleCenter = tester.getCenter(find.byType(VehicleWidget));
      return vehicleCenter - roadRect.topLeft;
    }

    final centerBeforePause = vehicleCenterInRoad();
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    final centerAfterPause = vehicleCenterInRoad();

    now = now.add(const Duration(minutes: 10));
    await tester.pump(const Duration(seconds: 1));
    final centerAfterPausedTime = vehicleCenterInRoad();

    expect(centerAfterPause.dx, closeTo(centerBeforePause.dx, 0.1));
    expect(centerAfterPause.dy, closeTo(centerBeforePause.dy, 0.1));
    expect(centerAfterPausedTime.dx, closeTo(centerBeforePause.dx, 0.1));
    expect(centerAfterPausedTime.dy, closeTo(centerBeforePause.dy, 0.1));

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
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 5),
          ),
          activityProgressService: LocalActivityProgressService(),
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
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(
      tester.widget<TimerControlBar>(find.byType(TimerControlBar)).isVertical,
      isFalse,
    );

    tester.view.physicalSize = const Size(900, 500);
    await tester.pump();

    expect(tester.getSize(find.byType(RoadView)), roadSize);
  });

  testWidgets('Timer screen keeps long landscape course viewport fixed', (
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
          config: ActivityTimerConfig.defaults().copyWith(
            duration: const Duration(minutes: 60),
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(RoadView)), const Size(1200, 520));
    expect(
      tester.widget<RoadView>(find.byType(RoadView)).courseDuration,
      const Duration(minutes: 60),
    );
    expect(
      tester
          .widget<RoadVehicleLayer>(find.byType(RoadVehicleLayer))
          .courseDuration,
      const Duration(minutes: 60),
    );
    expect(
      tester
          .getRect(find.byType(RoadView))
          .contains(tester.getCenter(find.byType(VehicleWidget))),
      isTrue,
    );
  });

  testWidgets(
    'Timer screen places controls inside compact landscape course action slot',
    (tester) async {
      tester.view.physicalSize = const Size(852, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: TimerScreen(
            config: ActivityTimerConfig.defaults(),
            activityProgressService: LocalActivityProgressService(),
            onConfigChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      final roadRect = tester.getRect(find.byType(RoadView));
      final controlsRect = tester.getRect(
        find.byKey(const ValueKey('compactLandscapeControls')),
      );
      final settingsRect = tester.getRect(
        find.byKey(const ValueKey('motivationSettingsButton')),
      );
      final pauseRect = tester.getRect(find.byIcon(Icons.pause_rounded));
      final roadBounds = createRoadBounds(const Size(1200, 520));
      final expectedRoadRight =
          roadRect.left + (roadRect.width * roadBounds.right / 1200);

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(TimerControlBar), findsNothing);
      expect(find.byIcon(Icons.video_settings_rounded), findsOneWidget);
      expect(roadRect.width, greaterThan(760));
      expect(roadRect.height, greaterThan(320));
      expect(controlsRect.left, greaterThanOrEqualTo(expectedRoadRight));
      expect(controlsRect.right, lessThanOrEqualTo(roadRect.right));
      expect(controlsRect.width, lessThanOrEqualTo(72));
      expect(controlsRect.height, lessThanOrEqualTo(210));
      expect(controlsRect.contains(settingsRect.center), isTrue);
      expect(controlsRect.contains(pauseRect.center), isTrue);
      expect(settingsRect.bottom, lessThanOrEqualTo(pauseRect.top));
      expect(
        controlsRect.right,
        lessThanOrEqualTo(tester.view.physicalSize.width),
      );
      expect(
        controlsRect.bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
    },
  );

  testWidgets('Timer motivation settings sheet scrolls in compact landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults().copyWith(
            motivationVideoUseCustomInterval: true,
          ),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('motivationSettingsButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('motivationVideoIntervalSegmentedButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motivationSettingsApplyButton')),
      findsOneWidget,
    );
  });

  testWidgets('Timer screen allows landscape only while mounted', (
    tester,
  ) async {
    final orientationService = _FakeOrientationService();

    await tester.pumpWidget(
      MaterialApp(
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
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
          config: ActivityTimerConfig.defaults().copyWith(
            keepScreenAwake: true,
          ),
          activityProgressService: LocalActivityProgressService(),
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
            config: ActivityTimerConfig.defaults().copyWith(
              keepScreenAwake: false,
            ),
            activityProgressService: LocalActivityProgressService(),
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
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('오늘의 미션'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('코스를 그만할까요?'), findsOneWidget);
    expect(find.text('지금 나가면 진행 중인 미션이 저장되지 않아요.'), findsOneWidget);

    await tester.tap(find.text('계속하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('코스를 그만할까요?'), findsNothing);
    expect(find.text('오늘의 미션'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.tap(find.text('그만하기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('타이머 열기'), findsOneWidget);
    expect(find.text('오늘의 미션'), findsNothing);
  });

  testWidgets('English locale shows English home copy', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _startApp(tester, const Locale('en'));

    expect(find.byKey(const ValueKey('homeLogo')), findsOneWidget);
    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.text("Today's vehicle"), findsOneWidget);
    expect(find.text('Create Timer'), findsWidgets);
    expect(find.byKey(const ValueKey('createTimerButton')), findsOneWidget);

    await _openTimerBuilder(tester);

    expect(find.text('Brush Teeth'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Cleanup'), findsOneWidget);
    expect(find.text('Play Time'), findsOneWidget);
    expect(find.text('Meal'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('2 min'), findsOneWidget);

    await _selectTimerBuilderActivity(tester, 'reading');

    expect(find.text('15 min'), findsOneWidget);
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
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.text("We're off!"), findsOneWidget);
    expect(find.text('Time left'), findsOneWidget);
    expect(find.text('출발했어요!'), findsNothing);
  });

  testWidgets('Paused timer shows paused status copy', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: TimerScreen(
          config: ActivityTimerConfig.defaults(),
          activityProgressService: LocalActivityProgressService(),
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
    expect(find.textContaining('Create Timer'), findsWidgets);
  });

  test('Fast activity awards only one random sticker', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 10),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 13),
        completedBeforeEnd: true,
      ),
    );

    expect(recordedSession.awardedRewards, hasLength(1));
  });

  test('Completed overtime activity awards a random sticker', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 25),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeEnd: false,
      ),
    );

    expect(recordedSession.awardedRewards, hasLength(1));
  });

  test('Activity with disabled rewards does not award stickers', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(activityId: 'play'),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityId, 'play');
  });

  test('Time-ended activity does not award stickers', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(completionStatus: ActivityCompletionStatus.timeEnded),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityCompleted, isTrue);
  });

  test('Time-ended activity can award stickers by parent choice', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        activityId: 'play',
        completionStatus: ActivityCompletionStatus.timeEnded,
        receiveSticker: true,
      ),
    );

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(recordedSession.entry.activityId, 'play');
    expect(recordedSession.entry.activityCompleted, isTrue);
  });

  test('Play time ended does not award stickers', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        activityId: 'play',
        completionStatus: ActivityCompletionStatus.timeEnded,
      ),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityId, 'play');
    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.timeEnded,
    );
  });

  test('Brushing completed at end awards one routine sticker', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        activityId: 'brushing',
        completionStatus: ActivityCompletionStatus.completedAtEnd,
      ),
    );

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(
      RewardCatalog.successStickers,
      contains(recordedSession.awardedRewards.single),
    );
    expect(recordedSession.entry.activityId, 'brushing');
    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.completedAtEnd,
    );
  });

  test('Incomplete activity does not award stickers', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 25),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeEnd: false,
        activityCompleted: false,
      ),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityCompleted, isFalse);
    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.needsMoreTime,
    );
    expect(recordedSession.entry.rewardIds, isEmpty);
  });

  test('Arrival-completed activity records at-arrival status', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        actualDuration: const Duration(minutes: 20),
        completedBeforeEnd: false,
        completionStatus: ActivityCompletionStatus.completedAtEnd,
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.completedAtEnd,
    );
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.completedAtEnd,
    );
  });

  test('Activity history stores directly selected marker ids', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(selectedMarkerIds: const ['top_teeth', 'bottom_teeth']),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.entry.selectedMarkerIds, [
      'top_teeth',
      'bottom_teeth',
    ]);
    expect(snapshot.history.single.selectedMarkerIds, [
      'top_teeth',
      'bottom_teeth',
    ]);

    final preferences = await SharedPreferences.getInstance();
    final rawHistory = preferences.getStringList('activityHistory');
    final rawInventory = preferences.getStringList('activityRewardInventory');
    expect(rawHistory, isNotNull);
    expect(rawInventory, isNotNull);
    expect(preferences.getStringList('mealHistory'), isNull);
    expect(preferences.getStringList('rewardInventory'), isNull);
    final historyJson = Map<String, Object?>.from(
      jsonDecode(rawHistory!.single) as Map,
    );
    expect(historyJson['activityId'], ActivityCatalog.defaultActivity.id);
    expect(historyJson['completedBeforeEnd'], isFalse);
    expect(historyJson['selectedMarkerIds'], ['top_teeth', 'bottom_teeth']);
    expect(historyJson.containsKey('completedBeforeArrival'), isFalse);
    expect(historyJson.containsKey('mealCompleted'), isFalse);
  });

  test('Deleting activity history removes only the saved record', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 2,
      rewardText: '아이스크림',
    );
    final recordedSession = await service.recordActivityResult(
      _activityResult(),
    );
    final beforeDelete = await service.loadSnapshot();

    expect(beforeDelete.history, hasLength(1));
    expect(beforeDelete.inventory, isNotEmpty);
    expect(beforeDelete.activeRewardGoals.single.filledCount, 1);

    final deleted = await service.deleteActivityHistoryEntry(
      recordedSession.entry.id,
    );
    final afterDelete = await service.loadSnapshot();

    expect(deleted, isTrue);
    expect(afterDelete.history, isEmpty);
    expect(afterDelete.inventory, hasLength(beforeDelete.inventory.length));
    expect(
      afterDelete.inventory.single.rewardId,
      beforeDelete.inventory.single.rewardId,
    );
    expect(
      afterDelete.inventory.single.count,
      beforeDelete.inventory.single.count,
    );
    expect(afterDelete.activeRewardGoals.single.filledCount, 1);
    expect(
      afterDelete.activeRewardGoals.single.filledSlots.single.activitySessionId,
      recordedSession.entry.id,
    );
  });

  test(
    'Deleting missing activity history entry leaves records unchanged',
    () async {
      SharedPreferences.setMockInitialValues({});

      final service = LocalActivityProgressService();
      await service.recordActivityResult(_activityResult());

      final deleted = await service.deleteActivityHistoryEntry('missing');
      final snapshot = await service.loadSnapshot();

      expect(deleted, isFalse);
      expect(snapshot.history, hasLength(1));
    },
  );

  test(
    'Completed activity fills exactly one active reward goal slot',
    () async {
      SharedPreferences.setMockInitialValues({});

      final service = LocalActivityProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 5,
        rewardText: '아이스크림',
      );

      final recordedSession = await service.recordActivityResult(
        _activityResult(),
      );
      final snapshot = await service.loadSnapshot();

      expect(recordedSession.updatedRewardGoal?.filledCount, 1);
      expect(recordedSession.rewardGoalJustReady, isFalse);
      expect(snapshot.activeRewardGoals.single.filledCount, 1);
    },
  );

  test('Completed activity fills all active reward goals', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );
    await service.createRewardGoal(requiredStickerCount: 7, rewardText: '딸기');

    final recordedSession = await service.recordActivityResult(
      _activityResult(),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.updatedRewardGoals, hasLength(2));
    expect(snapshot.activeRewardGoals, hasLength(2));
    expect(snapshot.activeRewardGoals.map((goal) => goal.filledCount), [1, 1]);
  });

  test(
    'Parent-skipped completed activity does not fill reward goals',
    () async {
      SharedPreferences.setMockInitialValues({});

      final service = LocalActivityProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 5,
        rewardText: '아이스크림',
      );

      final recordedSession = await service.recordActivityResult(
        _activityResult(
          completionStatus: ActivityCompletionStatus.completedAtEnd,
          receiveSticker: false,
        ),
      );
      final snapshot = await service.loadSnapshot();

      expect(recordedSession.awardedRewards, isEmpty);
      expect(recordedSession.updatedRewardGoal, isNull);
      expect(snapshot.activeRewardGoals.single.filledCount, 0);
      expect(snapshot.history.single.activityCompleted, isTrue);
    },
  );

  test('Parent-awarded time-ended activity fills reward goals', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordActivityResult(
      _activityResult(
        activityId: 'play',
        completionStatus: ActivityCompletionStatus.timeEnded,
        receiveSticker: true,
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(recordedSession.updatedRewardGoal?.filledCount, 1);
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.timeEnded,
    );
  });

  test('Only two active reward goals can be created', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
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
            activitySessionId: 'activity-1',
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

      final snapshot = await LocalActivityProgressService().loadSnapshot();

      expect(snapshot.activeRewardGoals, hasLength(1));
      expect(snapshot.activeRewardGoals.first.rewardText, '아이스크림');
      expect(snapshot.usedRewardGoals, hasLength(1));
      expect(snapshot.usedRewardGoals.first.status, RewardGoalStatus.used);
    },
  );

  test('Legacy history key loads with completion status fallback', () async {
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

    final snapshot = await LocalActivityProgressService().loadSnapshot();

    expect(snapshot.history.single.activityCompleted, isTrue);
    expect(
      snapshot.history.single.activityId,
      ActivityCatalog.defaultActivity.id,
    );
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.completedAfterEnd,
    );
    expect(snapshot.history.single.selectedMarkerIds, isEmpty);
  });

  test('Fast activity fills only one reward goal slot', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordActivityResult(
      _activityResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 13),
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
  });

  test('Incomplete activity does not fill a reward goal slot', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordActivityResult(
      _activityResult(activityCompleted: false),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.updatedRewardGoal, isNull);
    expect(snapshot.activeRewardGoals.single.filledCount, 0);
  });

  test('Reward goal becomes earned when required count is reached', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 2,
      rewardText: '아이스크림',
    );

    await service.recordActivityResult(
      _activityResult(endedAt: DateTime(2026, 5, 4, 12)),
    );
    final recordedSession = await service.recordActivityResult(
      _activityResult(endedAt: DateTime(2026, 5, 4, 13)),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.rewardGoalJustReady, isTrue);
    expect(snapshot.activeRewardGoals, isEmpty);
    expect(snapshot.earnedRewardGoals.single.status, RewardGoalStatus.earned);
    expect(snapshot.earnedRewardGoals.single.earnedAt, isNotNull);
  });

  test('Using an earned goal moves it to used history', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 1,
      rewardText: '아이스크림',
    );
    await service.recordActivityResult(_activityResult());

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

    final service = LocalActivityProgressService();
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

      final service = LocalActivityProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 5,
        rewardText: '아이스크림',
      );
      await service.recordActivityResult(_activityResult());
      await service.recordActivityResult(
        _activityResult(endedAt: DateTime(2026, 5, 4, 13)),
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

    final service = LocalActivityProgressService();
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

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await service.recordActivityResult(
      _activityResult(),
    );
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
          config: ActivityTimerConfig.defaults().copyWith(childName: 'Jiyul'),
          activityProgressService: LocalActivityProgressService(),
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Create Reward Promise'), findsOneWidget);
  });

  testWidgets('Home activity history summary opens activity history screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();
    await service.recordActivityResult(
      _activityResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(childName: 'Jiyul'),
          activityProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Recent activity 20:00 · Completed'), findsOneWidget);

    await tester.tap(find.text("Jiyul's activity history"));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityHistoryScreen), findsOneWidget);
    expect(find.text('Activity Records'), findsOneWidget);
  });

  testWidgets('Home activity history summary shows incomplete status', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();
    await service.recordActivityResult(
      _activityResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        activityCompleted: false,
        completionStatus: ActivityCompletionStatus.needsMoreTime,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: HomeScreen(
          config: ActivityTimerConfig.defaults().copyWith(childName: '강우'),
          activityProgressService: service,
          onConfigChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(
      find.text('최근 기록 20:00 · 조금 더 필요 · 스티커 받지 않음 · 초과 +05:00'),
      findsOneWidget,
    );
  });

  testWidgets('Reward goal creation form saves a goal', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: RewardGoalScreen(activityProgressService: service),
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
    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 1,
      rewardText: 'ice cream',
    );
    await service.recordActivityResult(_activityResult());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: RewardGoalScreen(activityProgressService: service),
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

  testWidgets('Activity history screen shows empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(
          activityProgressService: LocalActivityProgressService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('활동 기록'), findsOneWidget);
    expect(find.text('아직 저장된 활동 기록이 없어.'), findsOneWidget);
    expect(find.text('미션 타이머를 마치면 기록이 여기에 쌓여요.'), findsOneWidget);
  });

  testWidgets('Activity history screen lists saved activity records', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();
    await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeEnd: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('양치'), findsOneWidget);
    expect(find.text('🪥'), findsOneWidget);
    expect(find.textContaining('12:25'), findsOneWidget);
    expect(find.text('목표'), findsOneWidget);
    expect(find.text('20:00'), findsNWidgets(2));
    expect(find.text('실제'), findsOneWidget);
    expect(find.text('25:00'), findsNothing);
    expect(find.text('초과 +05:00'), findsNothing);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('받은 스티커'), findsOneWidget);
    expect(find.text('고른 마커'), findsNothing);
  });

  testWidgets('Activity history screen deletes a record after confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('12:25'), findsOneWidget);

    await tester.tap(
      find.byKey(
        ValueKey('deleteActivityHistoryEntry-${recordedSession.entry.id}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이 활동 기록을 삭제할까요?'), findsOneWidget);
    expect(find.text('기록만 삭제되고 받은 스티커는 유지돼요.'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('활동 기록을 삭제했어요.'), findsOneWidget);
    expect(find.textContaining('12:25'), findsNothing);
    expect(find.text('아직 저장된 활동 기록이 없어.'), findsOneWidget);
    expect((await service.loadSnapshot()).history, isEmpty);
  });

  testWidgets('Activity history delete dialog can be canceled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();
    final recordedSession = await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey('deleteActivityHistoryEntry-${recordedSession.entry.id}'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.textContaining('12:25'), findsOneWidget);
    expect((await service.loadSnapshot()).history, hasLength(1));
  });

  testWidgets('Activity history screen shows directly selected markers', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();
    await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 20),
        selectedMarkerIds: const ['top_teeth', 'bottom_teeth'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('activityHistoryHelpCard')),
      findsOneWidget,
    );
    expect(find.text('활동 기록 안내'), findsOneWidget);
    expect(find.text('고른 마커'), findsOneWidget);
    expect(find.text('위쪽 반짝'), findsNothing);
    expect(find.text('아래쪽 반짝'), findsNothing);
    expect(find.text('😁'), findsOneWidget);
    expect(find.text('🫧'), findsOneWidget);
  });

  testWidgets('Activity history screen shows needs-more-time records', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalActivityProgressService();
    await service.recordActivityResult(
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        activityCompleted: false,
        completionStatus: ActivityCompletionStatus.needsMoreTime,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppTexts.supportedLocales,
        home: ActivityHistoryScreen(activityProgressService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('조금 더 필요'), findsOneWidget);
    expect(find.text('스티커 받지 않음'), findsOneWidget);
    expect(find.text('초과 +05:00'), findsOneWidget);
  });
}

ActivitySessionResult _activityResult({
  String activityId = 'brushing',
  DateTime? startedAt,
  DateTime? endedAt,
  Duration targetDuration = const Duration(minutes: 20),
  Duration actualDuration = const Duration(minutes: 25),
  bool completedBeforeEnd = false,
  bool activityCompleted = true,
  ActivityCompletionStatus? completionStatus,
  List<String> selectedMarkerIds = const [],
  bool includeStickerDecision = true,
  bool? receiveSticker,
}) {
  final resolvedStartedAt = startedAt ?? DateTime(2026, 5, 4, 12);
  final resolvedEndedAt = endedAt ?? resolvedStartedAt.add(actualDuration);
  final resolvedCompletionStatus =
      completionStatus ??
      (activityCompleted
          ? (completedBeforeEnd
                ? ActivityCompletionStatus.completedBeforeEnd
                : ActivityCompletionStatus.completedAfterEnd)
          : ActivityCompletionStatus.needsMoreTime);

  return ActivitySessionResult(
    activityId: activityId,
    startedAt: resolvedStartedAt,
    endedAt: resolvedEndedAt,
    targetDuration: targetDuration,
    actualDuration: actualDuration,
    completedBeforeEnd: completedBeforeEnd,
    completionStatus: resolvedCompletionStatus,
    selectedMarkerIds: selectedMarkerIds,
    receiveSticker: includeStickerDecision
        ? receiveSticker ??
              (ActivityCatalog.findById(activityId).rewardEnabledByDefault &&
                  activityCompletionStatusCanReceiveSticker(
                    resolvedCompletionStatus,
                  ))
        : null,
  );
}

Future<ui.Image> _createTestFootprintImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFF6D8F3A);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(8, 8), width: 12, height: 16),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 16);
  picture.dispose();
  return image;
}

Future<void> _startApp(
  WidgetTester tester,
  Locale locale, {
  bool completeOnboarding = true,
  bool completeChildNameSetup = true,
}) async {
  tester.binding.platformDispatcher.localeTestValue = locale;
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await app.main();
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
  if (completeOnboarding &&
      find
          .byKey(const ValueKey('onboardingSkipButton'))
          .evaluate()
          .isNotEmpty) {
    await tester.tap(find.byKey(const ValueKey('onboardingSkipButton')));
    await tester.pumpAndSettle();
  }
  if (!completeChildNameSetup || find.byType(TextField).evaluate().isEmpty) {
    return;
  }

  await tester.enterText(find.byType(TextField), '지율');
  await tester.pump();
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

Future<void> _openTimerBuilder(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('createTimerButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _selectTimerBuilderActivity(
  WidgetTester tester,
  String activityId,
) async {
  tester
      .widget<ChoiceChip>(
        find.byKey(ValueKey('timerBuilderActivity_$activityId')),
      )
      .onSelected!(true);
  await tester.pump();
}

Future<void> _selectTimerBuilderManualMode(WidgetTester tester) async {
  tester
      .widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('timerBuilderMarkerManual')),
          matching: find.byType(OutlinedButton),
        ),
      )
      .onPressed!();
  await tester.pump();
}

Future<void> _selectTimerBuilderManualMarkers(
  WidgetTester tester,
  List<String> markerIds,
) async {
  await _selectTimerBuilderManualMode(tester);

  for (final markerId in markerIds) {
    tester
        .widget<ChoiceChip>(
          find.byKey(ValueKey('timerBuilderMarker_$markerId')),
        )
        .onSelected!(true);
    await tester.pump();
  }
}

Future<void> _setTimerBuilderMinutes(WidgetTester tester, int minutes) async {
  tester
      .widget<Slider>(find.byKey(const ValueKey('timerBuilderMinuteSlider')))
      .onChanged!(minutes.toDouble());
  await tester.pump();
}

Future<void> _saveTimerBuilderPreset(WidgetTester tester) async {
  tester
      .widget<OutlinedButton>(
        find.byKey(const ValueKey('timerBuilderSavePresetButton')),
      )
      .onPressed!();
  await tester.pump();
}

Future<void> _startTimerBuilder(WidgetTester tester) async {
  tester
      .widget<AppBouncyButton>(
        find.byKey(const ValueKey('timerBuilderStartButton')),
      )
      .onPressed!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpAvatarSetupScreen(
  WidgetTester tester,
  ActivityTimerConfig config, {
  Locale locale = const Locale('ko'),
  ValueChanged<ActivityTimerConfig>? onConfigChanged,
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

Future<void> _pumpHomeAvatarFileCheck(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
  await tester.pump();
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
