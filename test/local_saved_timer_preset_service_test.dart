import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity.dart';
import 'package:timey_rider/models/activity_timer_preset.dart';
import 'package:timey_rider/services/local_saved_timer_preset_service.dart';

void main() {
  test('LocalSavedTimerPresetService saves and loads presets', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LocalSavedTimerPresetService();

    await service.save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: const Duration(minutes: 18),
        markerMode: ActivityMarkerMode.manual,
        markerIds: const ['cover', 'bookmark'],
        selectedMarkerIds: const ['cover', 'bookmark'],
        updatedAt: DateTime.utc(2026, 6, 14, 1),
      ),
    );

    final presets = await service.load();

    expect(presets, hasLength(1));
    expect(presets.first.activityId, 'reading');
    expect(presets.first.duration, const Duration(minutes: 18));
    expect(presets.first.markerMode, ActivityMarkerMode.manual);
    expect(presets.first.selectedMarkerIds, ['cover', 'bookmark']);
  });

  test(
    'LocalSavedTimerPresetService moves duplicate presets to the top',
    () async {
      SharedPreferences.setMockInitialValues({});
      const service = LocalSavedTimerPresetService();

      await service.save(
        ActivityTimerPreset(
          activityId: 'brushing',
          duration: const Duration(minutes: 2),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, 1),
        ),
      );
      await service.save(
        ActivityTimerPreset(
          activityId: 'reading',
          duration: const Duration(minutes: 15),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, 2),
        ),
      );
      await service.save(
        ActivityTimerPreset(
          activityId: 'brushing',
          duration: const Duration(minutes: 2),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, 3),
        ),
      );

      final presets = await service.load();

      expect(presets, hasLength(2));
      expect(presets.first.activityId, 'brushing');
      expect(presets.first.updatedAt, DateTime.utc(2026, 6, 14, 3));
      expect(presets.last.activityId, 'reading');
    },
  );

  test(
    'LocalSavedTimerPresetService keeps custom presets with different names',
    () async {
      SharedPreferences.setMockInitialValues({});
      const service = LocalSavedTimerPresetService();

      await service.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: const Duration(minutes: 12),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, 1),
          customName: 'Piano',
        ),
      );
      await service.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: const Duration(minutes: 12),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, 2),
          customName: 'Blocks',
        ),
      );

      final presets = await service.load();

      expect(presets, hasLength(2));
      expect(presets.first.customName, 'Blocks');
      expect(presets.last.customName, 'Piano');
    },
  );

  test('LocalSavedTimerPresetService caps saved presets', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LocalSavedTimerPresetService();

    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxSavedPresets + 1;
      index += 1
    ) {
      await service.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: Duration(minutes: index + 1),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, index),
        ),
      );
    }

    final presets = await service.load();

    expect(presets, hasLength(LocalSavedTimerPresetService.maxSavedPresets));
    expect(presets.first.duration, const Duration(minutes: 6));
    expect(presets.last.duration, const Duration(minutes: 2));
  });

  test('LocalSavedTimerPresetService removes a preset by index', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LocalSavedTimerPresetService();

    await service.save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: const Duration(minutes: 15),
        markerMode: ActivityMarkerMode.random,
        updatedAt: DateTime.utc(2026, 6, 14, 1),
      ),
    );
    await service.save(
      ActivityTimerPreset(
        activityId: 'cleanup',
        duration: const Duration(minutes: 5),
        markerMode: ActivityMarkerMode.random,
        updatedAt: DateTime.utc(2026, 6, 14, 2),
      ),
    );

    final presets = await service.removeAt(0);

    expect(presets, hasLength(1));
    expect(presets.first.activityId, 'reading');
  });

  test('LocalSavedTimerPresetService toggles favorite presets', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LocalSavedTimerPresetService();

    await service.save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: const Duration(minutes: 15),
        markerMode: ActivityMarkerMode.random,
        updatedAt: DateTime.utc(2026, 6, 14, 1),
      ),
    );

    final favorited = await service.toggleFavoriteAt(0);
    final unfavorited = await service.toggleFavoriteAt(0);

    expect(favorited.didUpdate, isTrue);
    expect(favorited.isLimitReached, isFalse);
    expect(favorited.presets.first.isFavorite, isTrue);
    expect(unfavorited.didUpdate, isTrue);
    expect(unfavorited.presets.first.isFavorite, isFalse);
    expect((await service.load()).first.isFavorite, isFalse);
  });

  test('LocalSavedTimerPresetService limits home favorite presets', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LocalSavedTimerPresetService();

    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxFavoritePresets + 1;
      index += 1
    ) {
      await service.save(
        ActivityTimerPreset(
          activityId: 'custom',
          duration: Duration(minutes: 10 + index),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, index),
          customName: 'Timer $index',
        ),
      );
    }

    for (
      var index = 0;
      index < LocalSavedTimerPresetService.maxFavoritePresets;
      index += 1
    ) {
      final result = await service.toggleFavoriteAt(index);
      expect(result.didUpdate, isTrue);
      expect(result.isLimitReached, isFalse);
    }

    final blocked = await service.toggleFavoriteAt(
      LocalSavedTimerPresetService.maxFavoritePresets,
    );

    expect(blocked.didUpdate, isFalse);
    expect(blocked.isLimitReached, isTrue);
    expect(
      blocked.presets.where((preset) => preset.isFavorite),
      hasLength(LocalSavedTimerPresetService.maxFavoritePresets),
    );
  });

  test(
    'LocalSavedTimerPresetService keeps favorite state when saving duplicate',
    () async {
      SharedPreferences.setMockInitialValues({});
      const service = LocalSavedTimerPresetService();

      await service.save(
        ActivityTimerPreset(
          activityId: 'brushing',
          duration: const Duration(minutes: 2),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, 1),
        ),
      );
      await service.toggleFavoriteAt(0);

      final presets = await service.save(
        ActivityTimerPreset(
          activityId: 'brushing',
          duration: const Duration(minutes: 2),
          markerMode: ActivityMarkerMode.random,
          updatedAt: DateTime.utc(2026, 6, 14, 2),
        ),
      );

      expect(presets, hasLength(1));
      expect(presets.first.updatedAt, DateTime.utc(2026, 6, 14, 2));
      expect(presets.first.isFavorite, isTrue);
    },
  );

  test('LocalSavedTimerPresetService ignores malformed saved data', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresets': jsonEncode([
        {
          'activityId': 'reading',
          'durationMs': const Duration(minutes: 15).inMilliseconds,
          'markerMode': 'random',
          'updatedAt': DateTime.utc(2026, 6, 14, 1).toIso8601String(),
        },
        {'activityId': '', 'durationMs': 0},
        'not-a-map',
      ]),
    });

    final presets = await const LocalSavedTimerPresetService().load();

    expect(presets, hasLength(1));
    expect(presets.first.activityId, 'reading');
  });
}
