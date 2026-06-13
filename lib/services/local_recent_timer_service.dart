import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_timer_preset.dart';

class LocalRecentTimerService {
  const LocalRecentTimerService();

  static const _recentTimerKey = 'recentActivityTimerPreset';

  Future<void> save(ActivityTimerPreset preset) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_recentTimerKey, jsonEncode(preset.toJson()));
  }

  Future<ActivityTimerPreset?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawPreset = preferences.getString(_recentTimerKey);
    if (rawPreset == null || rawPreset.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawPreset);
      if (decoded is! Map) {
        return null;
      }

      return ActivityTimerPreset.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_recentTimerKey);
  }
}
