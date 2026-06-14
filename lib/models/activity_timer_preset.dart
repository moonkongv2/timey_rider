import 'activity.dart';

class ActivityTimerPreset {
  const ActivityTimerPreset({
    required this.activityId,
    required this.duration,
    required this.markerMode,
    required this.updatedAt,
    this.markerIds = const [],
    List<String> selectedMarkerIds = const [],
    String? customName,
  }) : _selectedMarkerIds = selectedMarkerIds,
       _customName = customName;

  factory ActivityTimerPreset.fromJson(Map<String, Object?> json) {
    final activityId = _stringFromJson(json['activityId']);
    final duration = _durationFromJson(json['durationMs']);
    final markerMode = _markerModeFromJson(json['markerMode']);
    final updatedAt = _dateTimeFromJson(json['updatedAt']);

    if (activityId == null ||
        activityId.trim().isEmpty ||
        duration == null ||
        markerMode == null ||
        updatedAt == null) {
      throw const FormatException('Invalid activity timer preset.');
    }

    return ActivityTimerPreset(
      activityId: activityId,
      duration: duration,
      markerMode: markerMode,
      markerIds: _stringListFromJson(json['markerIds']),
      selectedMarkerIds: _stringListFromJson(json['selectedMarkerIds']),
      updatedAt: updatedAt,
      customName: _stringFromJson(json['customName']),
    );
  }

  final String activityId;
  final Duration duration;
  final ActivityMarkerMode markerMode;
  final List<String> markerIds;
  final List<String>? _selectedMarkerIds;
  List<String> get selectedMarkerIds => _selectedMarkerIds ?? const [];
  final DateTime updatedAt;
  final String? _customName;
  String? get customName {
    final value = _customName?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  ActivityTimerPreset copyWith({
    String? activityId,
    Duration? duration,
    ActivityMarkerMode? markerMode,
    List<String>? markerIds,
    List<String>? selectedMarkerIds,
    DateTime? updatedAt,
    String? customName,
  }) {
    return ActivityTimerPreset(
      activityId: activityId ?? this.activityId,
      duration: duration ?? this.duration,
      markerMode: markerMode ?? this.markerMode,
      markerIds: List.unmodifiable(markerIds ?? this.markerIds),
      selectedMarkerIds: List.unmodifiable(
        selectedMarkerIds ?? this.selectedMarkerIds,
      ),
      updatedAt: updatedAt ?? this.updatedAt,
      customName: customName ?? this.customName,
    );
  }

  Map<String, Object?> toJson() {
    final customName = this.customName;
    return {
      'activityId': activityId,
      'durationMs': duration.inMilliseconds,
      'markerMode': markerMode.name,
      'markerIds': markerIds,
      'selectedMarkerIds': selectedMarkerIds,
      'updatedAt': updatedAt.toIso8601String(),
      if (customName != null) 'customName': customName,
    };
  }
}

ActivityMarkerMode? _markerModeFromJson(Object? value) {
  final name = _stringFromJson(value);
  for (final mode in ActivityMarkerMode.values) {
    if (mode.name == name) {
      return mode;
    }
  }
  return null;
}

DateTime? _dateTimeFromJson(Object? value) {
  final rawValue = _stringFromJson(value);
  if (rawValue == null || rawValue.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(rawValue);
}

Duration? _durationFromJson(Object? value) {
  if (value is! int || value <= 0) {
    return null;
  }
  return Duration(milliseconds: value);
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }

  return List.unmodifiable(
    value.whereType<String>().where((id) => id.trim().isNotEmpty),
  );
}

String? _stringFromJson(Object? value) {
  return value is String ? value : null;
}
