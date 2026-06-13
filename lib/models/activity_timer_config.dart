import '../catalogs/activity_catalog.dart';
import 'activity.dart';

export 'activity.dart' show ActivityMarkerMode;

enum AvatarImageMode { defaultImage, custom }

const Object _customAvatarImagePathUnset = Object();
const Object _customAvatarVehicleIdUnset = Object();

class VehicleAvatarConfig {
  const VehicleAvatarConfig({
    required this.imagePath,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.rotationDegrees,
  });

  factory VehicleAvatarConfig.fromJson(Map<String, Object?> json) {
    return VehicleAvatarConfig(
      imagePath: json['imagePath'] as String? ?? '',
      scale: _doubleFromJson(json['scale'], 1.0),
      offsetX: _doubleFromJson(json['offsetX'], 0.0),
      offsetY: _doubleFromJson(json['offsetY'], 0.0),
      rotationDegrees: _doubleFromJson(json['rotationDegrees'], 0.0),
    );
  }

  final String imagePath;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotationDegrees;

  Map<String, Object> toJson() {
    return {
      'imagePath': imagePath,
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'rotationDegrees': rotationDegrees,
    };
  }

  bool get hasImagePath => imagePath.trim().isNotEmpty;
}

class ActivityTimerConfig {
  const ActivityTimerConfig({
    required this.activityId,
    required this.duration,
    required this.showRemainingTime,
    required this.soundEnabled,
    required this.motivationVideoEnabled,
    required this.motivationVideoUseCustomInterval,
    required this.motivationVideoInterval,
    required this.keepScreenAwake,
    required this.courseId,
    required this.vehicleId,
    required this.childName,
    required this.avatarMode,
    required this.customAvatarImagePath,
    required this.customAvatarVehicleId,
    required this.avatarScale,
    required this.avatarOffsetX,
    required this.avatarOffsetY,
    required this.avatarRotationDegrees,
    required this.customAvatarsByVehicle,
    required this.markerMode,
    this.markerIds = const [],
    List<String> selectedMarkerIds = const [],
  }) : _selectedMarkerIds = selectedMarkerIds;

  factory ActivityTimerConfig.defaults() {
    const defaultActivity = ActivityCatalog.defaultActivity;
    return ActivityTimerConfig(
      activityId: defaultActivity.id,
      duration: defaultActivity.defaultDuration,
      showRemainingTime: true,
      soundEnabled: true,
      motivationVideoEnabled: true,
      motivationVideoUseCustomInterval: false,
      motivationVideoInterval: Duration(minutes: 3),
      keepScreenAwake: false,
      courseId: 'park',
      vehicleId: 'motorcycle',
      childName: '',
      avatarMode: AvatarImageMode.defaultImage,
      customAvatarImagePath: null,
      customAvatarVehicleId: null,
      avatarScale: 1.0,
      avatarOffsetX: 0.0,
      avatarOffsetY: 0.0,
      avatarRotationDegrees: 0.0,
      customAvatarsByVehicle: {},
      markerMode: ActivityMarkerMode.activityDefault,
      markerIds: defaultActivity.markerIds,
      selectedMarkerIds: const [],
    );
  }

  final String activityId;
  final Duration duration;
  final bool showRemainingTime;
  final bool soundEnabled;
  final bool motivationVideoEnabled;
  final bool motivationVideoUseCustomInterval;
  final Duration motivationVideoInterval;
  final bool keepScreenAwake;
  final String courseId;
  final String vehicleId;
  final String childName;
  final AvatarImageMode avatarMode;
  final String? customAvatarImagePath;
  final String? customAvatarVehicleId;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
  final Map<String, VehicleAvatarConfig> customAvatarsByVehicle;
  final ActivityMarkerMode markerMode;
  final List<String> markerIds;
  final List<String>? _selectedMarkerIds;
  List<String> get selectedMarkerIds => _selectedMarkerIds ?? const [];

  ActivityTimerConfig copyWith({
    String? activityId,
    Duration? duration,
    bool? showRemainingTime,
    bool? soundEnabled,
    bool? motivationVideoEnabled,
    bool? motivationVideoUseCustomInterval,
    Duration? motivationVideoInterval,
    bool? keepScreenAwake,
    String? courseId,
    String? vehicleId,
    String? childName,
    AvatarImageMode? avatarMode,
    Object? customAvatarImagePath = _customAvatarImagePathUnset,
    Object? customAvatarVehicleId = _customAvatarVehicleIdUnset,
    double? avatarScale,
    double? avatarOffsetX,
    double? avatarOffsetY,
    double? avatarRotationDegrees,
    Map<String, VehicleAvatarConfig>? customAvatarsByVehicle,
    ActivityMarkerMode? markerMode,
    List<String>? markerIds,
    List<String>? selectedMarkerIds,
  }) {
    final nextAvatarMode = avatarMode ?? this.avatarMode;
    final nextCustomAvatarImagePath =
        customAvatarImagePath == _customAvatarImagePathUnset
        ? this.customAvatarImagePath
        : customAvatarImagePath as String?;
    final nextCustomAvatarVehicleId =
        customAvatarVehicleId == _customAvatarVehicleIdUnset
        ? this.customAvatarVehicleId
        : customAvatarVehicleId as String?;
    final nextAvatarScale = avatarScale ?? this.avatarScale;
    final nextAvatarOffsetX = avatarOffsetX ?? this.avatarOffsetX;
    final nextAvatarOffsetY = avatarOffsetY ?? this.avatarOffsetY;
    final nextAvatarRotationDegrees =
        avatarRotationDegrees ?? this.avatarRotationDegrees;
    final nextCustomAvatarsByVehicle = _updatedCustomAvatarsByVehicle(
      customAvatarsByVehicle ?? this.customAvatarsByVehicle,
      avatarMode: nextAvatarMode,
      imagePath: nextCustomAvatarImagePath,
      vehicleId: nextCustomAvatarVehicleId,
      scale: nextAvatarScale,
      offsetX: nextAvatarOffsetX,
      offsetY: nextAvatarOffsetY,
      rotationDegrees: nextAvatarRotationDegrees,
      imagePathWasSet: customAvatarImagePath != _customAvatarImagePathUnset,
      vehicleIdWasSet: customAvatarVehicleId != _customAvatarVehicleIdUnset,
      adjustmentWasSet:
          avatarScale != null ||
          avatarOffsetX != null ||
          avatarOffsetY != null ||
          avatarRotationDegrees != null,
    );

    return ActivityTimerConfig(
      activityId: activityId ?? this.activityId,
      duration: duration ?? this.duration,
      showRemainingTime: showRemainingTime ?? this.showRemainingTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      motivationVideoEnabled:
          motivationVideoEnabled ?? this.motivationVideoEnabled,
      motivationVideoUseCustomInterval:
          motivationVideoUseCustomInterval ??
          this.motivationVideoUseCustomInterval,
      motivationVideoInterval:
          motivationVideoInterval ?? this.motivationVideoInterval,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      courseId: courseId ?? this.courseId,
      vehicleId: vehicleId ?? this.vehicleId,
      childName: childName ?? this.childName,
      avatarMode: nextAvatarMode,
      customAvatarImagePath: nextCustomAvatarImagePath,
      customAvatarVehicleId: nextCustomAvatarVehicleId,
      avatarScale: nextAvatarScale,
      avatarOffsetX: nextAvatarOffsetX,
      avatarOffsetY: nextAvatarOffsetY,
      avatarRotationDegrees: nextAvatarRotationDegrees,
      customAvatarsByVehicle: Map.unmodifiable(nextCustomAvatarsByVehicle),
      markerMode: markerMode ?? this.markerMode,
      markerIds: List.unmodifiable(markerIds ?? this.markerIds),
      selectedMarkerIds: List.unmodifiable(
        selectedMarkerIds ?? this.selectedMarkerIds,
      ),
    );
  }

  bool hasCustomAvatarForVehicle(String vehicleId) {
    return avatarMode == AvatarImageMode.custom &&
        customAvatarConfigForVehicle(vehicleId) != null;
  }

  AvatarImageMode avatarModeForVehicle(String vehicleId) {
    return hasCustomAvatarForVehicle(vehicleId)
        ? AvatarImageMode.custom
        : AvatarImageMode.defaultImage;
  }

  String? customAvatarImagePathForVehicle(String vehicleId) {
    return hasCustomAvatarForVehicle(vehicleId)
        ? customAvatarConfigForVehicle(vehicleId)?.imagePath
        : null;
  }

  VehicleAvatarConfig? customAvatarConfigForVehicle(String vehicleId) {
    final avatarConfig = customAvatarsByVehicle[vehicleId];
    if (avatarConfig != null && avatarConfig.hasImagePath) {
      return avatarConfig;
    }

    final avatarPath = customAvatarImagePath?.trim();
    final avatarVehicleId = customAvatarVehicleId?.trim();
    if (avatarPath != null &&
        avatarPath.isNotEmpty &&
        avatarVehicleId != null &&
        avatarVehicleId.isNotEmpty &&
        avatarVehicleId == vehicleId) {
      return VehicleAvatarConfig(
        imagePath: avatarPath,
        scale: avatarScale,
        offsetX: avatarOffsetX,
        offsetY: avatarOffsetY,
        rotationDegrees: avatarRotationDegrees,
      );
    }

    return null;
  }
}

double _doubleFromJson(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

Map<String, VehicleAvatarConfig> _updatedCustomAvatarsByVehicle(
  Map<String, VehicleAvatarConfig> current, {
  required AvatarImageMode avatarMode,
  required String? imagePath,
  required String? vehicleId,
  required double scale,
  required double offsetX,
  required double offsetY,
  required double rotationDegrees,
  required bool imagePathWasSet,
  required bool vehicleIdWasSet,
  required bool adjustmentWasSet,
}) {
  final next = Map<String, VehicleAvatarConfig>.from(current);
  final normalizedVehicleId = vehicleId?.trim();
  final normalizedImagePath = imagePath?.trim();
  final legacyAvatarChanged =
      imagePathWasSet || vehicleIdWasSet || adjustmentWasSet;

  if (!legacyAvatarChanged || normalizedVehicleId == null) {
    return next;
  }

  if (imagePathWasSet &&
      (normalizedImagePath == null || normalizedImagePath.isEmpty)) {
    next.remove(normalizedVehicleId);
    return next;
  }

  if (avatarMode == AvatarImageMode.custom &&
      normalizedVehicleId.isNotEmpty &&
      normalizedImagePath != null &&
      normalizedImagePath.isNotEmpty) {
    next[normalizedVehicleId] = VehicleAvatarConfig(
      imagePath: normalizedImagePath,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
      rotationDegrees: rotationDegrees,
    );
  }

  return next;
}
