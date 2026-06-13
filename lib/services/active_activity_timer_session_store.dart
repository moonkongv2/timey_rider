import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/active_activity_timer_session.dart';

class ActiveActivityTimerSessionStore {
  const ActiveActivityTimerSessionStore();

  static const _sessionKey = 'activeActivityTimerSession';
  static const _legacySessionKey = 'activeMealTimerSession';

  Future<void> save(ActiveActivityTimerSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    await preferences.remove(_legacySessionKey);
  }

  Future<ActiveActivityTimerSession?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession =
        preferences.getString(_sessionKey) ??
        preferences.getString(_legacySessionKey);
    if (rawSession == null || rawSession.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is! Map) {
        return null;
      }

      return ActiveActivityTimerSession.fromJson(
        Map<String, Object?>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    await preferences.remove(_legacySessionKey);
  }
}
