import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/motivation_asset_catalog.dart';
import 'package:timey_rider/screens/timer_screen.dart';

void main() {
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
}
