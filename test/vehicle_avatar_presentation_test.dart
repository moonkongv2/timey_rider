import 'package:flutter_test/flutter_test.dart';
import 'package:ticky_rider/models/meal_timer_config.dart';
import 'package:ticky_rider/models/vehicle_avatar_presentation.dart';

void main() {
  test(
    'Default presentation uses default image mode without an image path',
    () {
      const avatar = VehicleAvatarPresentation.defaultImage;

      expect(avatar.mode, AvatarImageMode.defaultImage);
      expect(avatar.imagePath, isNull);
      expect(avatar.hasImagePath, isFalse);
      expect(avatar.isCustom, isFalse);
    },
  );

  test('fromConfig returns custom presentation for a vehicle avatar', () {
    final config = MealTimerConfig.defaults().copyWith(
      avatarMode: AvatarImageMode.custom,
      customAvatarsByVehicle: const {
        'bus': VehicleAvatarConfig(
          imagePath: '/local/bus.png',
          scale: 1.2,
          offsetX: 0.05,
          offsetY: -0.04,
          rotationDegrees: 6.0,
        ),
      },
    );

    final avatar = config.avatarPresentationForVehicle('bus');

    expect(avatar.mode, AvatarImageMode.custom);
    expect(avatar.imagePath, '/local/bus.png');
    expect(avatar.scale, 1.2);
    expect(avatar.offsetX, 0.05);
    expect(avatar.offsetY, -0.04);
    expect(avatar.rotationDegrees, 6.0);
    expect(avatar.isCustom, isTrue);
  });

  test('fromConfig returns default presentation without a vehicle avatar', () {
    final config = MealTimerConfig.defaults().copyWith(
      avatarMode: AvatarImageMode.custom,
      customAvatarsByVehicle: const {
        'bus': VehicleAvatarConfig(
          imagePath: '/local/bus.png',
          scale: 1.2,
          offsetX: 0.05,
          offsetY: -0.04,
          rotationDegrees: 6.0,
        ),
      },
    );

    final avatar = config.avatarPresentationForVehicle('train');

    expect(avatar, same(VehicleAvatarPresentation.defaultImage));
    expect(avatar.mode, AvatarImageMode.defaultImage);
    expect(avatar.hasImagePath, isFalse);
  });
}
