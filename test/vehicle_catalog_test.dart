import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/models/vehicle.dart';
import 'package:timey_rider/screens/result_screen.dart';

void main() {
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
}
