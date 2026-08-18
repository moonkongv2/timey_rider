import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/result_audio_asset_catalog.dart';
import 'package:timey_rider/catalogs/timer_audio_asset_catalog.dart';

void main() {
  test('Timer audio and result audio asset catalogs have playable files', () {
    expect(
      TimerAudioAssetCatalog.runtimeAssetPaths,
      unorderedEquals({
        'assets/audio/timer_bgm/timer_bgm_short.mp3',
        'assets/audio/marker/marker_01.mp3',
        'assets/audio/course_loading.mp3',
        'assets/audio/ready_start_beep_02.mp3',
        'assets/audio/final_drive_short.mp3',
        'assets/audio/final_drive_long.mp3',
        'assets/audio/finish_arrival.mp3',
      }),
    );
    expect(
      ResultAudioAssetCatalog.runtimeAssetPaths,
      unorderedEquals({
        'assets/audio/crowd_cheering.mp3',
        'assets/audio/sticker_collect.mp3',
      }),
    );
    expect(TimerAudioAssetCatalog.bgmVolume, 0.22);
    expect(TimerAudioAssetCatalog.markerSfxVolume, 0.080);
    expect(TimerAudioAssetCatalog.courseLoadingVolume, 0.20);
    expect(TimerAudioAssetCatalog.readyStartBeepVolume, 0.12);
    expect(TimerAudioAssetCatalog.finishDriveVolume, 0.16);
    expect(TimerAudioAssetCatalog.finishArrivalVolume, 0.24);
    expect(ResultAudioAssetCatalog.crowdCheeringVolume, 0.70);
    expect(ResultAudioAssetCatalog.stickerCollectVolume, 0.55);

    for (final path in [
      ...TimerAudioAssetCatalog.runtimeAssetPaths,
      ...ResultAudioAssetCatalog.runtimeAssetPaths,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('Timer audio playable validation ignores non-audio evidence files', () {
    final playableFilesByDirectory = {
      'assets/audio/timer_bgm': ['timer_bgm_short.mp3'],
      'assets/audio/marker': ['marker_01.mp3'],
    };

    for (final entry in playableFilesByDirectory.entries) {
      final playableFilenames = Directory(entry.key)
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((filename) => filename.endsWith('.mp3'))
          .toList();

      expect(playableFilenames, unorderedEquals(entry.value));
    }
  });

  test('Timer audio playable validation ignores dot store files', () {
    final dotStoreFiles = Directory('assets/audio')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.uri.pathSegments.last == '.DS_Store')
        .toList();
    expect(dotStoreFiles, isNotEmpty);

    final playableFiles = Directory('assets/audio')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.mp3'))
        .where(
          (path) =>
              path.startsWith('assets/audio/timer_bgm/') ||
              path.startsWith('assets/audio/marker/') ||
              path == TimerAudioAssetCatalog.courseLoadingPath ||
              path == TimerAudioAssetCatalog.readyStartBeepPath ||
              path == TimerAudioAssetCatalog.finishDriveShortAssetPath ||
              path == TimerAudioAssetCatalog.finishDriveLongAssetPath ||
              path == TimerAudioAssetCatalog.finishArrivalAssetPath ||
              path == ResultAudioAssetCatalog.crowdCheeringAssetPath ||
              path == ResultAudioAssetCatalog.stickerCollectAssetPath,
        )
        .toList();

    expect(
      playableFiles,
      unorderedEquals([
        ...TimerAudioAssetCatalog.runtimeAssetPaths,
        ...ResultAudioAssetCatalog.runtimeAssetPaths,
      ]),
    );
  });

  test('Timer audio pubspec entries include only runtime files', () {
    final assetEntries = File('pubspec.yaml')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.startsWith('- '))
        .map((line) => line.substring(2))
        .toSet();

    for (final path in TimerAudioAssetCatalog.runtimeAssetPaths) {
      expect(assetEntries, contains(path), reason: path);
    }
    for (final path in ResultAudioAssetCatalog.runtimeAssetPaths) {
      expect(assetEntries, contains(path), reason: path);
    }

    expect(assetEntries, isNot(contains('assets/audio/')));
    expect(assetEntries, isNot(contains('assets/audio/timer_bgm/')));
    expect(assetEntries, isNot(contains('assets/audio/marker/')));

    final timerAudioEntries = assetEntries.where(
      (path) =>
          path.startsWith('assets/audio/timer_bgm/') ||
          path.startsWith('assets/audio/marker/') ||
          path == TimerAudioAssetCatalog.courseLoadingPath ||
          path == TimerAudioAssetCatalog.readyStartBeepPath ||
          path == TimerAudioAssetCatalog.finishDriveShortAssetPath ||
          path == TimerAudioAssetCatalog.finishDriveLongAssetPath ||
          path == TimerAudioAssetCatalog.finishArrivalAssetPath ||
          path == ResultAudioAssetCatalog.crowdCheeringAssetPath ||
          path == ResultAudioAssetCatalog.stickerCollectAssetPath,
    );
    expect(
      timerAudioEntries,
      unorderedEquals([
        ...TimerAudioAssetCatalog.runtimeAssetPaths,
        ...ResultAudioAssetCatalog.runtimeAssetPaths,
      ]),
    );
    expect(
      assetEntries.any(
        (path) =>
            path.contains('/_licenses/') ||
            path.endsWith('metadata.yaml') ||
            path.endsWith('.pdf'),
      ),
      isFalse,
    );
  });

  test('Timer audio metadata points at catalog runtime paths', () {
    final metadataByAssetPath = {
      TimerAudioAssetCatalog.bgmPath: File(
        'assets/audio/timer_bgm/_licenses/timer_bgm_01/metadata.yaml',
      ).readAsStringSync(),
      TimerAudioAssetCatalog.markerSfxPath: File(
        'assets/audio/marker/_licenses/marker_01/metadata.yaml',
      ).readAsStringSync(),
    };

    for (final entry in metadataByAssetPath.entries) {
      expect(entry.value, contains('app_asset_path: ${entry.key}'));
    }
  });
}
