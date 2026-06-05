import 'meal_timer_config.dart';

const Object _imagePathUnset = Object();

class VehicleAvatarPresentation {
  const VehicleAvatarPresentation({
    required this.mode,
    this.imagePath,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotationDegrees = 0.0,
  });

  factory VehicleAvatarPresentation.fromConfig({
    required MealTimerConfig config,
    required String vehicleId,
  }) {
    final mode = config.avatarModeForVehicle(vehicleId);
    final avatarConfig = config.customAvatarConfigForVehicle(vehicleId);
    if (mode != AvatarImageMode.custom || avatarConfig == null) {
      return VehicleAvatarPresentation.defaultImage;
    }

    return VehicleAvatarPresentation(
      mode: mode,
      imagePath: avatarConfig.imagePath,
      scale: avatarConfig.scale,
      offsetX: avatarConfig.offsetX,
      offsetY: avatarConfig.offsetY,
      rotationDegrees: avatarConfig.rotationDegrees,
    );
  }

  static const defaultImage = VehicleAvatarPresentation(
    mode: AvatarImageMode.defaultImage,
  );

  final AvatarImageMode mode;
  final String? imagePath;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotationDegrees;

  bool get hasImagePath => imagePath != null && imagePath!.trim().isNotEmpty;

  bool get isCustom => mode == AvatarImageMode.custom && hasImagePath;

  VehicleAvatarPresentation copyWith({
    AvatarImageMode? mode,
    Object? imagePath = _imagePathUnset,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotationDegrees,
  }) {
    return VehicleAvatarPresentation(
      mode: mode ?? this.mode,
      imagePath: identical(imagePath, _imagePathUnset)
          ? this.imagePath
          : imagePath as String?,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }
}

extension VehicleAvatarPresentationMealTimerConfigX on MealTimerConfig {
  VehicleAvatarPresentation avatarPresentationForVehicle(String vehicleId) {
    return VehicleAvatarPresentation.fromConfig(
      config: this,
      vehicleId: vehicleId,
    );
  }
}
