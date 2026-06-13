import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ticky_rider/models/active_activity_timer_session.dart';
import 'package:ticky_rider/models/activity_timer_config.dart';
import 'package:ticky_rider/services/active_activity_timer_session_store.dart';

void main() {
  test(
    'Active activity timer session store saves and loads a running session',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = ActiveActivityTimerSessionStore();
      final startedAt = DateTime.utc(2026, 6, 10, 1, 30);
      final config = ActivityTimerConfig.defaults().copyWith(
        duration: const Duration(minutes: 35),
        childName: '지율',
        vehicleId: 'bus',
        motivationVideoUseCustomInterval: true,
        motivationVideoInterval: const Duration(minutes: 3),
        markerMode: ActivityMarkerMode.manual,
        markerIds: const ['egg', 'tofu'],
        selectedMarkerIds: const ['egg', 'tofu'],
        customAvatarsByVehicle: const {
          'bus': VehicleAvatarConfig(
            imagePath: '/local/bus.png',
            scale: 1.1,
            offsetX: 0.05,
            offsetY: -0.02,
            rotationDegrees: 3.0,
          ),
        },
      );

      await store.save(
        ActiveActivityTimerSession(
          sessionId: 'session-1',
          startedAt: startedAt,
          config: config,
          state: ActiveActivityTimerSessionState.running,
          totalPausedDuration: const Duration(minutes: 2),
          shownMotivationMilestones: const {10, 20},
          lastMotivationVideoShownAt: const Duration(minutes: 6),
          motivationScheduleStartedAt: const Duration(minutes: 1),
        ),
      );

      final preferences = await SharedPreferences.getInstance();
      final rawSession = preferences.getString('activeActivityTimerSession');
      expect(rawSession, isNotNull);
      expect(preferences.getString('activeMealTimerSession'), isNull);
      final decoded = Map<String, Object?>.from(jsonDecode(rawSession!) as Map);
      final configJson = Map<String, Object?>.from(decoded['config'] as Map);
      expect(configJson['markerMode'], 'manual');
      expect(configJson['markerIds'], ['egg', 'tofu']);
      expect(configJson['selectedMarkerIds'], ['egg', 'tofu']);
      expect(configJson.containsKey('courseIngredientMode'), isFalse);
      expect(configJson.containsKey('courseIngredientIds'), isFalse);
      expect(configJson.containsKey('selectedCourseIngredientIds'), isFalse);

      final loadedSession = await store.load();

      expect(loadedSession, isNotNull);
      expect(loadedSession!.sessionId, 'session-1');
      expect(loadedSession.startedAt, startedAt);
      expect(loadedSession.duration, const Duration(minutes: 35));
      expect(loadedSession.config.childName, '지율');
      expect(loadedSession.config.vehicleId, 'bus');
      expect(loadedSession.config.motivationVideoUseCustomInterval, isTrue);
      expect(
        loadedSession.config.motivationVideoInterval,
        const Duration(minutes: 3),
      );
      expect(loadedSession.config.markerMode, ActivityMarkerMode.manual);
      expect(loadedSession.config.markerIds, ['egg', 'tofu']);
      expect(loadedSession.config.selectedMarkerIds, ['egg', 'tofu']);
      expect(
        loadedSession.config.customAvatarConfigForVehicle('bus')?.imagePath,
        '/local/bus.png',
      );
      expect(loadedSession.state, ActiveActivityTimerSessionState.running);
      expect(loadedSession.totalPausedDuration, const Duration(minutes: 2));
      expect(loadedSession.pausedAt, isNull);
      expect(loadedSession.shownMotivationMilestones, {10, 20});
      expect(
        loadedSession.lastMotivationVideoShownAt,
        const Duration(minutes: 6),
      );
      expect(
        loadedSession.motivationScheduleStartedAt,
        const Duration(minutes: 1),
      );
    },
  );

  test(
    'Active activity timer session store saves and loads a paused session',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = ActiveActivityTimerSessionStore();
      final pausedAt = DateTime.utc(2026, 6, 10, 1, 40);

      await store.save(
        ActiveActivityTimerSession(
          sessionId: 'session-2',
          startedAt: DateTime.utc(2026, 6, 10, 1, 30),
          config: ActivityTimerConfig.defaults(),
          state: ActiveActivityTimerSessionState.paused,
          totalPausedDuration: const Duration(minutes: 1),
          pausedAt: pausedAt,
        ),
      );

      final loadedSession = await store.load();

      expect(loadedSession, isNotNull);
      expect(loadedSession!.state, ActiveActivityTimerSessionState.paused);
      expect(loadedSession.pausedAt, pausedAt);
      expect(loadedSession.totalPausedDuration, const Duration(minutes: 1));
    },
  );

  test('Active activity timer session copyWith can clear nullable fields', () {
    final session = ActiveActivityTimerSession(
      sessionId: 'session-3',
      startedAt: DateTime.utc(2026, 6, 10, 1, 30),
      config: ActivityTimerConfig.defaults(),
      state: ActiveActivityTimerSessionState.paused,
      pausedAt: DateTime.utc(2026, 6, 10, 1, 35),
      lastMotivationVideoShownAt: const Duration(minutes: 3),
    );

    final resumedSession = session.copyWith(
      state: ActiveActivityTimerSessionState.running,
      pausedAt: null,
      lastMotivationVideoShownAt: null,
    );

    expect(resumedSession.state, ActiveActivityTimerSessionState.running);
    expect(resumedSession.pausedAt, isNull);
    expect(resumedSession.lastMotivationVideoShownAt, isNull);
  });

  test('Active activity timer session store ignores malformed data', () async {
    SharedPreferences.setMockInitialValues({
      'activeActivityTimerSession': '{not-json',
    });

    final loadedSession = await ActiveActivityTimerSessionStore().load();

    expect(loadedSession, isNull);
  });

  test(
    'Active activity timer session store reads legacy meal session key',
    () async {
      final session = ActiveActivityTimerSession(
        sessionId: 'legacy-session',
        startedAt: DateTime.utc(2026, 6, 10, 1, 30),
        config: ActivityTimerConfig.defaults().copyWith(
          markerMode: ActivityMarkerMode.manual,
          markerIds: const ['legacy-a', 'legacy-b'],
          selectedMarkerIds: const ['legacy-a'],
        ),
        state: ActiveActivityTimerSessionState.running,
      );
      SharedPreferences.setMockInitialValues({
        'activeMealTimerSession': jsonEncode(session.toJson()),
      });

      final loadedSession = await const ActiveActivityTimerSessionStore()
          .load();

      expect(loadedSession, isNotNull);
      expect(loadedSession!.sessionId, 'legacy-session');
      expect(loadedSession.config.markerMode, ActivityMarkerMode.manual);
      expect(loadedSession.config.markerIds, ['legacy-a', 'legacy-b']);
      expect(loadedSession.config.selectedMarkerIds, ['legacy-a']);
    },
  );

  test('Active activity timer session store clears saved data', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ActiveActivityTimerSessionStore();
    await store.save(
      ActiveActivityTimerSession(
        sessionId: 'session-4',
        startedAt: DateTime.utc(2026, 6, 10, 1, 30),
        config: ActivityTimerConfig.defaults(),
        state: ActiveActivityTimerSessionState.running,
      ),
    );

    await store.clear();

    expect(await store.load(), isNull);
  });
}
