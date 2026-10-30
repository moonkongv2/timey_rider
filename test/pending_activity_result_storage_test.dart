import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/services/active_activity_timer_session_store.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';
import 'support/progress_preferences_store.dart';
import 'package:timey_rider/models/pending_activity_result.dart';

import 'support/pending_activity_result_test_data.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final id in [null, '', '   ']) {
    test('pending parser rejects missing or blank session ID: $id', () {
      final json = pendingResult().toJson();
      (json['session'] as Map)['sessionId'] = id;
      expect(() => PendingActivityResult.fromJson(json), throwsFormatException);
    });
  }

  test(
    'conditional choice update and cleanup of A preserve newer pending and active B',
    () async {
      const store = ActiveActivityTimerSessionStore();
      final a = pendingResult();
      final bJson = a.toJson();
      (bJson['session'] as Map)['sessionId'] = 'B';
      final b = PendingActivityResult.fromJson(bJson);
      await store.savePendingResult(b);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'activeActivityTimerSession',
        jsonEncode(b.session.toJson()),
      );
      expect(
        await store.updatePendingResultIfSessionMatches(
          a.session.sessionId,
          a.result.copyWith(receiveSticker: true),
        ),
        isFalse,
      );
      await store.clearPendingResult(a.session.sessionId);
      expect((await store.loadPendingResult())!.session.sessionId, 'B');
      expect(
        jsonDecode(
          preferences.getString('activeActivityTimerSession')!,
        )['sessionId'],
        'B',
      );
      await store.clearPendingResult('B');
      expect(await store.loadPendingResult(), isNull);
      expect(await store.load(), isNull);
    },
  );

  test(
    'conditional update persists choice without recreating absent pending or removing active',
    () async {
      const store = ActiveActivityTimerSessionStore();
      final pending = pendingResult();
      await store.savePendingResult(pending);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'activeActivityTimerSession',
        jsonEncode(pending.session.toJson()),
      );
      final original = preferences.getString('activeActivityTimerSession');
      expect(
        await store.updatePendingResultIfSessionMatches(
          pending.session.sessionId,
          pending.result.copyWith(receiveSticker: false),
        ),
        isTrue,
      );
      expect((await store.loadPendingResult())!.result.receiveSticker, isFalse);
      expect(preferences.getString('activeActivityTimerSession'), original);
      await store.clearPendingResult(pending.session.sessionId);
      expect(
        await store.updatePendingResultIfSessionMatches(
          pending.session.sessionId,
          pending.result.copyWith(receiveSticker: true),
        ),
        isFalse,
      );
      expect(await store.loadPendingResult(), isNull);
    },
  );

  test(
    'pending persisted but residual active removal failure is reported and can be retried',
    () async {
      final disk = installProgressPreferencesStore();
      const store = ActiveActivityTimerSessionStore();
      final pending = pendingResult();
      await store.save(pending.session);
      disk.failKey = 'activeActivityTimerSession';
      await expectLater(store.savePendingResult(pending), throwsStateError);
      expect(await store.loadPendingResult(), isNotNull);
      await store.clearPendingResult(pending.session.sessionId);
      expect(await store.load(), isNull);
    },
  );

  test(
    'completed result survives store recreation and stale timer saves',
    () async {
      const store = ActiveActivityTimerSessionStore();
      final pending = pendingResult();
      await store.save(pending.session);
      await store.savePendingResult(pending);
      await store.save(pending.session);
      const restoredStore = ActiveActivityTimerSessionStore();
      expect(await restoredStore.load(), isNull);
      final restored = await restoredStore.loadPendingResult();
      expect(restored!.result.receiveSticker, isNull);
      expect(restored.result.sessionId, 'finished-session');
      expect(restored.result.selectedMarkerIds, ['book']);
      await restoredStore.clearPendingResult('other-session');
      expect(await restoredStore.loadPendingResult(), isNotNull);
    },
  );

  test(
    'concurrent and replayed result awards record sticker and goal once',
    () async {
      final service = LocalActivityProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 3,
        rewardText: 'Park',
      );
      final result = pendingResult(receiveSticker: true).result;
      await Future.wait([
        service.recordActivityResult(result, vehicleId: 'motorcycle'),
        LocalActivityProgressService().recordActivityResult(
          result,
          vehicleId: 'motorcycle',
        ),
      ]);
      final snapshot = await service.loadSnapshot();
      expect(snapshot.history, hasLength(1));
      expect(snapshot.inventory.single.count, 1);
      expect(snapshot.activeRewardGoals.single.filledCount, 1);
    },
  );

  test(
    'unfinished multi-key record transaction replays before duplicate result',
    () async {
      final service = LocalActivityProgressService();
      final result = pendingResult(receiveSticker: true).result;
      await service.recordActivityResult(result, vehicleId: 'motorcycle');
      final preferences = await SharedPreferences.getInstance();
      final history = preferences.getStringList('activityHistory')!;
      final inventory = preferences.getStringList('activityRewardInventory')!;
      // Simulate death after history was written but before inventory was written.
      SharedPreferences.setMockInitialValues({
        'activityHistory': history,
        'activityRecordTransaction': jsonEncode({
          'activityHistory': history,
          'activityRewardInventory': inventory,
        }),
      });
      await LocalActivityProgressService().recordActivityResult(
        result,
        vehicleId: 'motorcycle',
      );
      final restored = await LocalActivityProgressService().loadSnapshot();
      expect(restored.history, hasLength(1));
      expect(restored.inventory.single.count, 1);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'activityRecordTransaction',
        ),
        isFalse,
      );
    },
  );
}
