import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_timer_config.dart';

class LocalSettingsService {
  static const _durationMinutesKey = 'durationMinutes';
  static const _showRemainingTimeKey = 'showRemainingTime';
  static const _soundEnabledKey = 'soundEnabled';
  static const _motivationVideoEnabledKey = 'motivationVideoEnabled';
  static const _motivationVideoUseCustomIntervalKey =
      'motivationVideoUseCustomInterval';
  static const _motivationVideoIntervalMinutesKey =
      'motivationVideoIntervalMinutes';
  static const _keepScreenAwakeKey = 'keepScreenAwake';
  static const _activityIdKey = 'activityId';
  static const _vehicleIdKey = 'vehicleId';
  static const _childNameKey = 'childName';
  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';
  static const _avatarModeKey = 'avatarMode';
  static const _customAvatarImagePathKey = 'customAvatarImagePath';
  static const _customAvatarVehicleIdKey = 'customAvatarVehicleId';
  static const _avatarScaleKey = 'avatarScale';
  static const _avatarOffsetXKey = 'avatarOffsetX';
  static const _avatarOffsetYKey = 'avatarOffsetY';
  static const _avatarRotationDegreesKey = 'avatarRotationDegrees';
  static const _customAvatarsByVehicleKey = 'customAvatarsByVehicle';
  static const _markerModeKey = 'markerMode';

  Future<ActivityTimerConfig> loadConfig() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = ActivityTimerConfig.defaults();
    final vehicleId =
        preferences.getString(_vehicleIdKey) ?? defaults.vehicleId;
    final avatarMode = _avatarModeFromString(
      preferences.getString(_avatarModeKey),
    );
    final customAvatarImagePath = preferences.getString(
      _customAvatarImagePathKey,
    );
    final avatarScale =
        preferences.getDouble(_avatarScaleKey) ?? defaults.avatarScale;
    final avatarOffsetX =
        preferences.getDouble(_avatarOffsetXKey) ?? defaults.avatarOffsetX;
    final avatarOffsetY =
        preferences.getDouble(_avatarOffsetYKey) ?? defaults.avatarOffsetY;
    final avatarRotationDegrees =
        preferences.getDouble(_avatarRotationDegreesKey) ??
        defaults.avatarRotationDegrees;
    final customAvatarVehicleId =
        preferences.getString(_customAvatarVehicleIdKey) ??
        (avatarMode == AvatarImageMode.custom &&
                customAvatarImagePath != null &&
                customAvatarImagePath.trim().isNotEmpty
            ? vehicleId
            : null);
    final customAvatarsByVehicle = _loadCustomAvatarsByVehicle(
      preferences,
      legacyAvatarMode: avatarMode,
      legacyImagePath: customAvatarImagePath,
      legacyVehicleId: customAvatarVehicleId,
      legacyScale: avatarScale,
      legacyOffsetX: avatarOffsetX,
      legacyOffsetY: avatarOffsetY,
      legacyRotationDegrees: avatarRotationDegrees,
    );
    final activeAvatarVehicleId = customAvatarsByVehicle.containsKey(vehicleId)
        ? vehicleId
        : customAvatarVehicleId;
    final activeAvatarConfig = activeAvatarVehicleId == null
        ? null
        : customAvatarsByVehicle[activeAvatarVehicleId];

    return defaults.copyWith(
      duration: Duration(
        minutes:
            preferences.getInt(_durationMinutesKey) ??
            defaults.duration.inMinutes,
      ),
      showRemainingTime:
          preferences.getBool(_showRemainingTimeKey) ??
          defaults.showRemainingTime,
      soundEnabled:
          preferences.getBool(_soundEnabledKey) ?? defaults.soundEnabled,
      motivationVideoEnabled:
          preferences.getBool(_motivationVideoEnabledKey) ??
          defaults.motivationVideoEnabled,
      motivationVideoUseCustomInterval:
          preferences.getBool(_motivationVideoUseCustomIntervalKey) ??
          defaults.motivationVideoUseCustomInterval,
      motivationVideoInterval: _durationFromMinutePreference(
        preferences.getInt(_motivationVideoIntervalMinutesKey),
        defaults.motivationVideoInterval,
      ),
      keepScreenAwake:
          preferences.getBool(_keepScreenAwakeKey) ?? defaults.keepScreenAwake,
      activityId: preferences.getString(_activityIdKey) ?? defaults.activityId,
      vehicleId: vehicleId,
      childName: preferences.getString(_childNameKey) ?? defaults.childName,
      avatarMode: avatarMode,
      customAvatarImagePath:
          activeAvatarConfig?.imagePath ?? customAvatarImagePath,
      customAvatarVehicleId: activeAvatarVehicleId,
      avatarScale: activeAvatarConfig?.scale ?? avatarScale,
      avatarOffsetX: activeAvatarConfig?.offsetX ?? avatarOffsetX,
      avatarOffsetY: activeAvatarConfig?.offsetY ?? avatarOffsetY,
      avatarRotationDegrees:
          activeAvatarConfig?.rotationDegrees ?? avatarRotationDegrees,
      customAvatarsByVehicle: customAvatarsByVehicle,
      markerMode: _markerModeFromString(
        preferences.getString(_markerModeKey),
        fallback: defaults.markerMode,
      ),
    );
  }

  Future<void> saveConfig(ActivityTimerConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_durationMinutesKey, config.duration.inMinutes);
    await preferences.setBool(_showRemainingTimeKey, config.showRemainingTime);
    await preferences.setBool(_soundEnabledKey, config.soundEnabled);
    await preferences.setBool(
      _motivationVideoEnabledKey,
      config.motivationVideoEnabled,
    );
    await preferences.setBool(
      _motivationVideoUseCustomIntervalKey,
      config.motivationVideoUseCustomInterval,
    );
    await preferences.setInt(
      _motivationVideoIntervalMinutesKey,
      config.motivationVideoInterval.inMinutes,
    );
    await preferences.setBool(_keepScreenAwakeKey, config.keepScreenAwake);
    await preferences.setString(_activityIdKey, config.activityId);
    await preferences.setString(_vehicleIdKey, config.vehicleId);
    await preferences.setString(_childNameKey, config.childName);
    await preferences.setString(
      _avatarModeKey,
      _avatarModeToString(config.avatarMode),
    );
    final customAvatarsByVehicle = _customAvatarsForSaving(config);

    final customAvatarImagePath = config.customAvatarImagePath?.trim();
    if (customAvatarImagePath == null || customAvatarImagePath.isEmpty) {
      await preferences.remove(_customAvatarImagePathKey);
    } else {
      await preferences.setString(
        _customAvatarImagePathKey,
        customAvatarImagePath,
      );
    }

    final customAvatarVehicleId = config.customAvatarVehicleId?.trim();
    if (customAvatarVehicleId == null || customAvatarVehicleId.isEmpty) {
      await preferences.remove(_customAvatarVehicleIdKey);
    } else {
      await preferences.setString(
        _customAvatarVehicleIdKey,
        customAvatarVehicleId,
      );
    }

    await preferences.setDouble(_avatarScaleKey, config.avatarScale);
    await preferences.setDouble(_avatarOffsetXKey, config.avatarOffsetX);
    await preferences.setDouble(_avatarOffsetYKey, config.avatarOffsetY);
    await preferences.setDouble(
      _avatarRotationDegreesKey,
      config.avatarRotationDegrees,
    );
    if (customAvatarsByVehicle.isEmpty) {
      await preferences.remove(_customAvatarsByVehicleKey);
    } else {
      await preferences.setString(
        _customAvatarsByVehicleKey,
        jsonEncode(
          customAvatarsByVehicle.map(
            (vehicleId, avatarConfig) =>
                MapEntry(vehicleId, avatarConfig.toJson()),
          ),
        ),
      );
    }
    await preferences.setString(
      _markerModeKey,
      _markerModeToString(config.markerMode),
    );
  }

  Future<bool> loadHasSeenOnboarding({String? childName}) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(_hasSeenOnboardingKey)) {
      return preferences.getBool(_hasSeenOnboardingKey) ?? false;
    }
    return childName?.trim().isNotEmpty ?? false;
  }

  Future<void> saveHasSeenOnboarding(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hasSeenOnboardingKey, value);
  }

  AvatarImageMode _avatarModeFromString(String? value) {
    return switch (value) {
      'custom' => AvatarImageMode.custom,
      _ => AvatarImageMode.defaultImage,
    };
  }

  String _avatarModeToString(AvatarImageMode mode) {
    return switch (mode) {
      AvatarImageMode.defaultImage => 'defaultImage',
      AvatarImageMode.custom => 'custom',
    };
  }

  ActivityMarkerMode _markerModeFromString(
    String? value, {
    required ActivityMarkerMode fallback,
  }) {
    return switch (value) {
      'off' => ActivityMarkerMode.off,
      'manual' => ActivityMarkerMode.manual,
      'activityDefault' => ActivityMarkerMode.activityDefault,
      _ => fallback,
    };
  }

  String _markerModeToString(ActivityMarkerMode mode) {
    return switch (mode) {
      ActivityMarkerMode.off => 'off',
      ActivityMarkerMode.manual => 'manual',
      ActivityMarkerMode.activityDefault => 'activityDefault',
    };
  }

  Map<String, VehicleAvatarConfig> _loadCustomAvatarsByVehicle(
    SharedPreferences preferences, {
    required AvatarImageMode legacyAvatarMode,
    required String? legacyImagePath,
    required String? legacyVehicleId,
    required double legacyScale,
    required double legacyOffsetX,
    required double legacyOffsetY,
    required double legacyRotationDegrees,
  }) {
    final avatarsByVehicle = <String, VehicleAvatarConfig>{};
    final rawAvatars = preferences.getString(_customAvatarsByVehicleKey);
    if (rawAvatars != null && rawAvatars.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAvatars);
        if (decoded is Map<String, Object?>) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is Map<String, Object?>) {
              final avatarConfig = VehicleAvatarConfig.fromJson(value);
              if (entry.key.trim().isNotEmpty && avatarConfig.hasImagePath) {
                avatarsByVehicle[entry.key] = avatarConfig;
              }
            }
          }
        }
      } catch (_) {
        // Ignore malformed avatar maps and fall back to legacy single-avatar keys.
      }
    }

    final legacyVehicleIdValue = legacyVehicleId?.trim();
    final legacyImagePathValue = legacyImagePath?.trim();
    if (legacyAvatarMode == AvatarImageMode.custom &&
        legacyVehicleIdValue != null &&
        legacyVehicleIdValue.isNotEmpty &&
        legacyImagePathValue != null &&
        legacyImagePathValue.isNotEmpty) {
      avatarsByVehicle.putIfAbsent(
        legacyVehicleIdValue,
        () => VehicleAvatarConfig(
          imagePath: legacyImagePathValue,
          scale: legacyScale,
          offsetX: legacyOffsetX,
          offsetY: legacyOffsetY,
          rotationDegrees: legacyRotationDegrees,
        ),
      );
    }

    return Map.unmodifiable(avatarsByVehicle);
  }

  Map<String, VehicleAvatarConfig> _customAvatarsForSaving(
    ActivityTimerConfig config,
  ) {
    final avatarsByVehicle = Map<String, VehicleAvatarConfig>.from(
      config.customAvatarsByVehicle,
    );
    final legacyVehicleId = config.customAvatarVehicleId?.trim();
    final legacyImagePath = config.customAvatarImagePath?.trim();
    if (config.avatarMode == AvatarImageMode.custom &&
        legacyVehicleId != null &&
        legacyVehicleId.isNotEmpty &&
        legacyImagePath != null &&
        legacyImagePath.isNotEmpty) {
      avatarsByVehicle[legacyVehicleId] = VehicleAvatarConfig(
        imagePath: legacyImagePath,
        scale: config.avatarScale,
        offsetX: config.avatarOffsetX,
        offsetY: config.avatarOffsetY,
        rotationDegrees: config.avatarRotationDegrees,
      );
    }

    return avatarsByVehicle;
  }

  Duration _durationFromMinutePreference(int? minutes, Duration fallback) {
    if (minutes == null || minutes <= 0) {
      return fallback;
    }

    return Duration(minutes: minutes);
  }
}
