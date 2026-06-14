import 'activity_timer_config.dart';

enum ActiveActivityTimerSessionState { running, paused, arrived }

const Object _pausedAtUnset = Object();
const Object _lastMotivationVideoShownAtUnset = Object();

class ActiveActivityTimerSession {
  const ActiveActivityTimerSession({
    required this.sessionId,
    required this.startedAt,
    required this.config,
    required this.state,
    this.totalPausedDuration = Duration.zero,
    this.pausedAt,
    this.shownMotivationMilestones = const {},
    this.lastMotivationVideoShownAt,
    this.motivationScheduleStartedAt = Duration.zero,
  });

  factory ActiveActivityTimerSession.fromJson(Map<String, Object?> json) {
    final sessionId = _stringFromJson(json['sessionId']);
    final startedAt = _dateTimeFromJson(json['startedAt']);
    final configJson = json['config'];
    if (sessionId == null ||
        sessionId.trim().isEmpty ||
        startedAt == null ||
        configJson is! Map) {
      throw const FormatException('Invalid active activity timer session.');
    }

    return ActiveActivityTimerSession(
      sessionId: sessionId,
      startedAt: startedAt,
      config: _configFromJson(Map<String, Object?>.from(configJson)),
      state: _stateFromJson(json['state']),
      totalPausedDuration: _durationFromJson(
        json['totalPausedDurationMs'],
        Duration.zero,
      ),
      pausedAt: _dateTimeFromJson(json['pausedAt']),
      shownMotivationMilestones: _intSetFromJson(
        json['shownMotivationMilestones'],
      ),
      lastMotivationVideoShownAt: _nullableDurationFromJson(
        json['lastMotivationVideoShownAtMs'],
      ),
      motivationScheduleStartedAt: _durationFromJson(
        json['motivationScheduleStartedAtMs'],
        Duration.zero,
      ),
    );
  }

  final String sessionId;
  final DateTime startedAt;
  final ActivityTimerConfig config;
  final ActiveActivityTimerSessionState state;
  final Duration totalPausedDuration;
  final DateTime? pausedAt;
  final Set<int> shownMotivationMilestones;
  final Duration? lastMotivationVideoShownAt;
  final Duration motivationScheduleStartedAt;

  Duration get duration => config.duration;

  ActiveActivityTimerSession copyWith({
    ActivityTimerConfig? config,
    ActiveActivityTimerSessionState? state,
    Duration? totalPausedDuration,
    Object? pausedAt = _pausedAtUnset,
    Set<int>? shownMotivationMilestones,
    Object? lastMotivationVideoShownAt = _lastMotivationVideoShownAtUnset,
    Duration? motivationScheduleStartedAt,
  }) {
    return ActiveActivityTimerSession(
      sessionId: sessionId,
      startedAt: startedAt,
      config: config ?? this.config,
      state: state ?? this.state,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      pausedAt: pausedAt == _pausedAtUnset
          ? this.pausedAt
          : pausedAt as DateTime?,
      shownMotivationMilestones:
          shownMotivationMilestones ?? this.shownMotivationMilestones,
      lastMotivationVideoShownAt:
          lastMotivationVideoShownAt == _lastMotivationVideoShownAtUnset
          ? this.lastMotivationVideoShownAt
          : lastMotivationVideoShownAt as Duration?,
      motivationScheduleStartedAt:
          motivationScheduleStartedAt ?? this.motivationScheduleStartedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'startedAt': startedAt.toIso8601String(),
      'config': _configToJson(config),
      'state': state.name,
      'totalPausedDurationMs': totalPausedDuration.inMilliseconds,
      'pausedAt': pausedAt?.toIso8601String(),
      'shownMotivationMilestones': shownMotivationMilestones.toList()..sort(),
      'lastMotivationVideoShownAtMs':
          lastMotivationVideoShownAt?.inMilliseconds,
      'motivationScheduleStartedAtMs':
          motivationScheduleStartedAt.inMilliseconds,
    };
  }
}

Map<String, Object?> _configToJson(ActivityTimerConfig config) {
  return {
    'durationMs': config.duration.inMilliseconds,
    'showRemainingTime': config.showRemainingTime,
    'soundEnabled': config.soundEnabled,
    'motivationVideoEnabled': config.motivationVideoEnabled,
    'motivationVideoUseCustomInterval': config.motivationVideoUseCustomInterval,
    'motivationVideoIntervalMs': config.motivationVideoInterval.inMilliseconds,
    'keepScreenAwake': config.keepScreenAwake,
    'activityId': config.activityId,
    'courseId': config.courseId,
    'vehicleId': config.vehicleId,
    'childName': config.childName,
    'avatarMode': config.avatarMode.name,
    'customAvatarImagePath': config.customAvatarImagePath,
    'customAvatarVehicleId': config.customAvatarVehicleId,
    'avatarScale': config.avatarScale,
    'avatarOffsetX': config.avatarOffsetX,
    'avatarOffsetY': config.avatarOffsetY,
    'avatarRotationDegrees': config.avatarRotationDegrees,
    'customAvatarsByVehicle': config.customAvatarsByVehicle.map(
      (vehicleId, avatarConfig) => MapEntry(vehicleId, avatarConfig.toJson()),
    ),
    'markerMode': config.markerMode.name,
    'markerIds': config.markerIds,
    'selectedMarkerIds': config.selectedMarkerIds,
  };
}

ActivityTimerConfig _configFromJson(Map<String, Object?> json) {
  final defaults = ActivityTimerConfig.defaults();
  return defaults.copyWith(
    duration: _durationFromJson(json['durationMs'], defaults.duration),
    showRemainingTime:
        json['showRemainingTime'] as bool? ?? defaults.showRemainingTime,
    soundEnabled: json['soundEnabled'] as bool? ?? defaults.soundEnabled,
    motivationVideoEnabled:
        json['motivationVideoEnabled'] as bool? ??
        defaults.motivationVideoEnabled,
    motivationVideoUseCustomInterval:
        json['motivationVideoUseCustomInterval'] as bool? ??
        defaults.motivationVideoUseCustomInterval,
    motivationVideoInterval: _durationFromJson(
      json['motivationVideoIntervalMs'],
      defaults.motivationVideoInterval,
    ),
    keepScreenAwake:
        json['keepScreenAwake'] as bool? ?? defaults.keepScreenAwake,
    courseId: _stringFromJson(json['courseId']) ?? defaults.courseId,
    vehicleId: _stringFromJson(json['vehicleId']) ?? defaults.vehicleId,
    childName: _stringFromJson(json['childName']) ?? defaults.childName,
    avatarMode: _avatarModeFromJson(json['avatarMode']),
    customAvatarImagePath: _stringFromJson(json['customAvatarImagePath']),
    customAvatarVehicleId: _stringFromJson(json['customAvatarVehicleId']),
    avatarScale: _doubleFromJson(json['avatarScale'], defaults.avatarScale),
    avatarOffsetX: _doubleFromJson(
      json['avatarOffsetX'],
      defaults.avatarOffsetX,
    ),
    avatarOffsetY: _doubleFromJson(
      json['avatarOffsetY'],
      defaults.avatarOffsetY,
    ),
    avatarRotationDegrees: _doubleFromJson(
      json['avatarRotationDegrees'],
      defaults.avatarRotationDegrees,
    ),
    customAvatarsByVehicle: _avatarMapFromJson(json['customAvatarsByVehicle']),
    markerMode: _markerModeFromJson(
      json['markerMode'],
      fallback: defaults.markerMode,
    ),
    activityId: _stringFromJson(json['activityId']) ?? defaults.activityId,
    markerIds: _stringListFromJson(json['markerIds']),
    selectedMarkerIds: _stringListFromJson(json['selectedMarkerIds']),
  );
}

ActiveActivityTimerSessionState _stateFromJson(Object? value) {
  final name = _stringFromJson(value);
  for (final state in ActiveActivityTimerSessionState.values) {
    if (state.name == name) {
      return state;
    }
  }
  return ActiveActivityTimerSessionState.running;
}

AvatarImageMode _avatarModeFromJson(Object? value) {
  final name = _stringFromJson(value);
  for (final mode in AvatarImageMode.values) {
    if (mode.name == name) {
      return mode;
    }
  }
  return AvatarImageMode.defaultImage;
}

ActivityMarkerMode _markerModeFromJson(
  Object? value, {
  required ActivityMarkerMode fallback,
}) {
  final name = _stringFromJson(value);
  for (final mode in ActivityMarkerMode.values) {
    if (mode.name == name) {
      return mode;
    }
  }
  return fallback;
}

Map<String, VehicleAvatarConfig> _avatarMapFromJson(Object? value) {
  if (value is! Map) {
    return const {};
  }

  final avatars = <String, VehicleAvatarConfig>{};
  for (final entry in value.entries) {
    final vehicleId = entry.key;
    final avatarJson = entry.value;
    if (vehicleId is! String || avatarJson is! Map) {
      continue;
    }
    final avatarConfig = VehicleAvatarConfig.fromJson(
      Map<String, Object?>.from(avatarJson),
    );
    if (vehicleId.trim().isNotEmpty && avatarConfig.hasImagePath) {
      avatars[vehicleId] = avatarConfig;
    }
  }
  return Map.unmodifiable(avatars);
}

Set<int> _intSetFromJson(Object? value) {
  if (value is! List) {
    return const {};
  }

  return Set.unmodifiable(value.whereType<int>());
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }

  return List.unmodifiable(
    value.whereType<String>().where((id) => id.trim().isNotEmpty),
  );
}

DateTime? _dateTimeFromJson(Object? value) {
  final rawValue = _stringFromJson(value);
  if (rawValue == null || rawValue.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(rawValue);
}

Duration? _nullableDurationFromJson(Object? value) {
  if (value is! int || value < 0) {
    return null;
  }
  return Duration(milliseconds: value);
}

Duration _durationFromJson(Object? value, Duration fallback) {
  if (value is! int || value < 0) {
    return fallback;
  }
  return Duration(milliseconds: value);
}

double _doubleFromJson(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

String? _stringFromJson(Object? value) {
  return value is String ? value : null;
}
