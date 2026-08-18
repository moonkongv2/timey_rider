import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/models/activity_timer_config.dart';

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
}
