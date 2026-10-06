import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/active_activity_timer_session.dart';
import '../models/pending_activity_result.dart';

class ActiveActivityTimerSessionStore {
  const ActiveActivityTimerSessionStore();

  static Future<void>? _operation;
  static SharedPreferences? _operationPreferences;
  static const _pendingResultKey = 'pendingActivityResult';

  static Future<T> _serialized<T>(
    Future<T> Function(SharedPreferences) operation,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    if (!identical(_operationPreferences, preferences)) {
      _operationPreferences = preferences;
      _operation = null;
    }
    final previous = _operation;
    final completed = Completer<void>();
    _operation = completed.future;
    try {
      if (previous != null) await previous;
      return await operation(preferences);
    } finally {
      completed.complete();
      if (identical(_operation, completed.future)) _operation = null;
    }
  }

  static const _sessionKey = 'activeActivityTimerSession';
  // Migration fallback: read an old paused/running session, then save only the
  // activeActivityTimerSession key.
  static const _legacySessionKey = 'activeMealTimerSession';

  Future<void> save(ActiveActivityTimerSession session) =>
      _serialized((preferences) async {
        if (preferences.containsKey(_pendingResultKey)) return;
        await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
        await preferences.remove(_legacySessionKey);
      });

  Future<ActiveActivityTimerSession?> load() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(_pendingResultKey)) return null;
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

  Future<void> clear() => _serialized((preferences) async {
    await preferences.remove(_sessionKey);
    await preferences.remove(_legacySessionKey);
  });

  Future<void> savePendingResult(PendingActivityResult result) =>
      _serialized((preferences) async {
        if (!await preferences.setString(
          _pendingResultKey,
          jsonEncode(result.toJson()),
        )) {
          throw StateError('Unable to persist completed activity.');
        }
        await preferences.remove(_sessionKey);
        await preferences.remove(_legacySessionKey);
      });

  Future<PendingActivityResult?> loadPendingResult() =>
      _serialized((preferences) async {
        final raw = preferences.getString(_pendingResultKey);
        if (raw == null) return null;
        try {
          return PendingActivityResult.fromJson(
            Map<String, Object?>.from(jsonDecode(raw) as Map),
          );
        } catch (_) {
          return null;
        }
      });

  Future<void> clearPendingResult(String sessionId) =>
      _serialized((preferences) async {
        final raw = preferences.getString(_pendingResultKey);
        if (raw == null) return;
        final pending = PendingActivityResult.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map),
        );
        if (pending.session.sessionId == sessionId) {
          if (!await preferences.remove(_pendingResultKey)) {
            throw StateError('Unable to clear completed activity.');
          }
        }
      });
}
