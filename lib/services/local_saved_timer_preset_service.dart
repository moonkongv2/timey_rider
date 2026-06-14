import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../models/activity_timer_preset.dart';

class LocalSavedTimerPresetService {
  const LocalSavedTimerPresetService();

  static const maxSavedPresets = 5;
  static const _savedTimerPresetsKey = 'savedActivityTimerPresets';

  Future<List<ActivityTimerPreset>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawPresets = preferences.getString(_savedTimerPresetsKey);
    if (rawPresets == null || rawPresets.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(rawPresets);
      if (decoded is! List) {
        return const [];
      }

      final presets = <ActivityTimerPreset>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        try {
          presets.add(
            ActivityTimerPreset.fromJson(Map<String, Object?>.from(item)),
          );
        } catch (_) {
          continue;
        }
      }
      return List.unmodifiable(presets.take(maxSavedPresets));
    } catch (_) {
      return const [];
    }
  }

  Future<List<ActivityTimerPreset>> save(ActivityTimerPreset preset) async {
    final existingPresets = await load();
    final updatedPresets = [
      preset,
      for (final existingPreset in existingPresets)
        if (!_matchesTimerSettings(existingPreset, preset)) existingPreset,
    ].take(maxSavedPresets).toList(growable: false);

    await _write(updatedPresets);
    return List.unmodifiable(updatedPresets);
  }

  Future<List<ActivityTimerPreset>> removeAt(int index) async {
    final existingPresets = await load();
    if (index < 0 || index >= existingPresets.length) {
      return existingPresets;
    }

    final updatedPresets = [...existingPresets]..removeAt(index);
    await _write(updatedPresets);
    return List.unmodifiable(updatedPresets);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_savedTimerPresetsKey);
  }

  Future<void> _write(List<ActivityTimerPreset> presets) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savedTimerPresetsKey,
      jsonEncode([for (final preset in presets) preset.toJson()]),
    );
  }
}

bool _matchesTimerSettings(ActivityTimerPreset a, ActivityTimerPreset b) {
  if (a.activityId != b.activityId ||
      a.duration != b.duration ||
      a.markerMode != b.markerMode ||
      a.customName != b.customName) {
    return false;
  }

  if (a.markerMode != ActivityMarkerMode.manual) {
    return true;
  }

  return _sameStringList(a.selectedMarkerIds, b.selectedMarkerIds) &&
      _sameStringList(a.markerIds, b.markerIds);
}

bool _sameStringList(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
