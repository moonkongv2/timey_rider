import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity.dart';
import 'package:timey_rider/models/activity_timer_preset.dart';
import 'package:timey_rider/services/local_recent_timer_service.dart';

void main() {
  test(
    'LocalRecentTimerService saves and loads the latest timer preset',
    () async {
      SharedPreferences.setMockInitialValues({});
      const service = LocalRecentTimerService();
      final updatedAt = DateTime.utc(2026, 6, 14, 1, 45);
      final preset = ActivityTimerPreset(
        activityId: 'brushing',
        duration: const Duration(minutes: 3),
        markerMode: ActivityMarkerMode.manual,
        markerIds: const ['top_teeth', 'bottom_teeth'],
        selectedMarkerIds: const ['top_teeth'],
        updatedAt: updatedAt,
      );

      await service.save(preset);

      final preferences = await SharedPreferences.getInstance();
      final rawPreset = preferences.getString('recentActivityTimerPreset');
      expect(rawPreset, isNotNull);
      final decoded = Map<String, Object?>.from(jsonDecode(rawPreset!) as Map);
      expect(decoded['activityId'], 'brushing');
      expect(decoded['durationMs'], const Duration(minutes: 3).inMilliseconds);
      expect(decoded['markerMode'], 'manual');

      final loadedPreset = await service.load();

      expect(loadedPreset, isNotNull);
      expect(loadedPreset!.activityId, 'brushing');
      expect(loadedPreset.duration, const Duration(minutes: 3));
      expect(loadedPreset.markerMode, ActivityMarkerMode.manual);
      expect(loadedPreset.markerIds, ['top_teeth', 'bottom_teeth']);
      expect(loadedPreset.selectedMarkerIds, ['top_teeth']);
      expect(loadedPreset.updatedAt, updatedAt);
    },
  );

  test('LocalRecentTimerService replaces the saved timer preset', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LocalRecentTimerService();

    await service.save(
      ActivityTimerPreset(
        activityId: 'brushing',
        duration: const Duration(minutes: 2),
        markerMode: ActivityMarkerMode.activityDefault,
        updatedAt: DateTime.utc(2026, 6, 14, 1),
      ),
    );
    await service.save(
      ActivityTimerPreset(
        activityId: 'cleanup',
        duration: const Duration(minutes: 5),
        markerMode: ActivityMarkerMode.activityDefault,
        markerIds: const ['blocks', 'books'],
        updatedAt: DateTime.utc(2026, 6, 14, 2),
      ),
    );

    final loadedPreset = await service.load();

    expect(loadedPreset, isNotNull);
    expect(loadedPreset!.activityId, 'cleanup');
    expect(loadedPreset.duration, const Duration(minutes: 5));
    expect(loadedPreset.markerMode, ActivityMarkerMode.activityDefault);
    expect(loadedPreset.markerIds, ['blocks', 'books']);
  });

  test('LocalRecentTimerService ignores malformed saved data', () async {
    SharedPreferences.setMockInitialValues({
      'recentActivityTimerPreset': '{not-json',
    });

    final loadedPreset = await const LocalRecentTimerService().load();

    expect(loadedPreset, isNull);
  });

  test('LocalRecentTimerService ignores invalid timer preset json', () async {
    SharedPreferences.setMockInitialValues({
      'recentActivityTimerPreset': jsonEncode({
        'activityId': '',
        'durationMs': 0,
        'markerMode': 'missing',
        'updatedAt': 'not-a-date',
      }),
    });

    final loadedPreset = await const LocalRecentTimerService().load();

    expect(loadedPreset, isNull);
  });

  test('LocalRecentTimerService clears the saved timer preset', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LocalRecentTimerService();
    await service.save(
      ActivityTimerPreset(
        activityId: 'reading',
        duration: const Duration(minutes: 15),
        markerMode: ActivityMarkerMode.off,
        updatedAt: DateTime.utc(2026, 6, 14, 1),
      ),
    );

    await service.clear();

    expect(await service.load(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('recentActivityTimerPreset'), isNull);
  });
}
