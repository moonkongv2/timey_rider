import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/models/activity_timer_preset.dart';
import 'package:timey_rider/models/activity.dart';

void main() {
  test('ActivityTimerPreset serializes timer settings', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 1, 30);
    final preset = ActivityTimerPreset(
      activityId: 'brushing',
      duration: const Duration(minutes: 3),
      markerMode: ActivityMarkerMode.manual,
      markerIds: const ['top_teeth', 'bottom_teeth'],
      selectedMarkerIds: const ['top_teeth'],
      updatedAt: updatedAt,
    );

    expect(preset.toJson(), {
      'activityId': 'brushing',
      'durationMs': const Duration(minutes: 3).inMilliseconds,
      'markerMode': 'manual',
      'markerIds': ['top_teeth', 'bottom_teeth'],
      'selectedMarkerIds': ['top_teeth'],
      'updatedAt': updatedAt.toIso8601String(),
    });
  });

  test('ActivityTimerPreset parses timer settings from json', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 1, 30);

    final preset = ActivityTimerPreset.fromJson({
      'activityId': 'cleanup',
      'durationMs': const Duration(minutes: 7).inMilliseconds,
      'markerMode': 'random',
      'markerIds': ['blocks', '', 3, 'books'],
      'selectedMarkerIds': ['blocks', null, 'books'],
      'updatedAt': updatedAt.toIso8601String(),
    });

    expect(preset.activityId, 'cleanup');
    expect(preset.duration, const Duration(minutes: 7));
    expect(preset.markerMode, ActivityMarkerMode.random);
    expect(preset.markerIds, ['blocks', 'books']);
    expect(preset.selectedMarkerIds, ['blocks', 'books']);
    expect(preset.updatedAt, updatedAt);
  });

  test('ActivityTimerPreset stores an optional custom name', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 1, 30);

    final preset = ActivityTimerPreset(
      activityId: 'custom',
      duration: const Duration(minutes: 12),
      markerMode: ActivityMarkerMode.random,
      updatedAt: updatedAt,
      customName: '  Piano  ',
    );

    expect(preset.customName, 'Piano');
    expect(preset.toJson()['customName'], 'Piano');

    final parsed = ActivityTimerPreset.fromJson({
      'activityId': 'custom',
      'durationMs': const Duration(minutes: 12).inMilliseconds,
      'markerMode': 'random',
      'updatedAt': updatedAt.toIso8601String(),
      'customName': 'Piano',
    });

    expect(parsed.customName, 'Piano');
  });

  test('ActivityTimerPreset limits custom name length', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 1, 30);

    final preset = ActivityTimerPreset(
      activityId: 'custom',
      duration: const Duration(minutes: 12),
      markerMode: ActivityMarkerMode.random,
      updatedAt: updatedAt,
      customName: '123456789012345',
    );

    expect(preset.customName, '123456789012');
    expect(preset.toJson()['customName'], '123456789012');
  });

  test('ActivityTimerPreset stores optional home favorite state', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 1, 30);

    final preset = ActivityTimerPreset(
      activityId: 'cleanup',
      duration: const Duration(minutes: 5),
      markerMode: ActivityMarkerMode.random,
      updatedAt: updatedAt,
      isFavorite: true,
    );

    expect(preset.isFavorite, isTrue);
    expect(preset.toJson()['isFavorite'], isTrue);

    final parsedFavorite = ActivityTimerPreset.fromJson({
      'activityId': 'cleanup',
      'durationMs': const Duration(minutes: 5).inMilliseconds,
      'markerMode': 'random',
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': true,
    });
    final parsedLegacy = ActivityTimerPreset.fromJson({
      'activityId': 'cleanup',
      'durationMs': const Duration(minutes: 5).inMilliseconds,
      'markerMode': 'random',
      'updatedAt': updatedAt.toIso8601String(),
    });

    expect(parsedFavorite.isFavorite, isTrue);
    expect(parsedLegacy.isFavorite, isFalse);
    expect(parsedLegacy.toJson().containsKey('isFavorite'), isFalse);
  });

  test('ActivityTimerPreset copyWith updates settings immutably', () {
    final updatedAt = DateTime.utc(2026, 6, 14, 1, 30);
    final preset = ActivityTimerPreset(
      activityId: 'reading',
      duration: const Duration(minutes: 15),
      markerMode: ActivityMarkerMode.activityDefault,
      markerIds: const ['cover'],
      updatedAt: updatedAt,
    );

    final copied = preset.copyWith(
      duration: const Duration(minutes: 20),
      markerMode: ActivityMarkerMode.off,
      markerIds: const [],
      selectedMarkerIds: const ['ignored'],
      updatedAt: updatedAt.add(const Duration(minutes: 1)),
      isFavorite: true,
    );

    expect(preset.duration, const Duration(minutes: 15));
    expect(preset.markerMode, ActivityMarkerMode.activityDefault);
    expect(preset.markerIds, ['cover']);
    expect(preset.selectedMarkerIds, isEmpty);
    expect(copied.activityId, 'reading');
    expect(copied.duration, const Duration(minutes: 20));
    expect(copied.markerMode, ActivityMarkerMode.off);
    expect(copied.markerIds, isEmpty);
    expect(copied.selectedMarkerIds, ['ignored']);
    expect(copied.updatedAt, updatedAt.add(const Duration(minutes: 1)));
    expect(copied.isFavorite, isTrue);
  });

  test('ActivityTimerPreset rejects invalid required json fields', () {
    expect(
      () => ActivityTimerPreset.fromJson({
        'activityId': ' ',
        'durationMs': 0,
        'markerMode': 'missing',
        'updatedAt': 'not-a-date',
      }),
      throwsFormatException,
    );
  });
}
