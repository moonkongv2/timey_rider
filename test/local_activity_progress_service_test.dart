import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/catalogs/vehicle_catalog.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_progress_snapshot.dart';
import 'package:timey_rider/models/activity_session_result.dart';
import 'package:timey_rider/models/reward_goal.dart';
import 'package:timey_rider/models/reward_item.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

void main() {
  test('Fast activity awards the selected vehicle sticker', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 10),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 13),
        completedBeforeEnd: true,
      ),
      vehicleId: VehicleCatalog.fireTruck.id,
    );

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(
      recordedSession.awardedRewards.single.id,
      RewardCatalog.vehicleStickerIdForVehicle(VehicleCatalog.fireTruck.id),
    );
    expect(recordedSession.entry.rewardIds, [
      RewardCatalog.vehicleStickerIdForVehicle(VehicleCatalog.fireTruck.id),
    ]);
  });

  test('Incomplete activity awards no vehicle sticker', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(activityCompleted: false),
      vehicleId: VehicleCatalog.fireTruck.id,
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.rewardIds, isEmpty);
    expect(snapshot.inventory, isEmpty);
  });

  test(
    'Completing same vehicle increments vehicle sticker inventory',
    () async {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      final service = LocalActivityProgressService();
      await _recordActivityResult(
        service,
        _activityResult(endedAt: DateTime(2026, 5, 4, 12, 10)),
        vehicleId: VehicleCatalog.fireTruck.id,
      );
      await _recordActivityResult(
        service,
        _activityResult(endedAt: DateTime(2026, 5, 4, 12, 40)),
        vehicleId: VehicleCatalog.fireTruck.id,
      );

      final snapshot = await service.loadSnapshot();
      final stickerId = RewardCatalog.vehicleStickerIdForVehicle(
        VehicleCatalog.fireTruck.id,
      );

      expect(snapshot.inventory, hasLength(1));
      expect(snapshot.inventory.single.rewardId, stickerId);
      expect(snapshot.inventory.single.count, 2);
    },
  );

  test(
    'Completing different vehicles creates separate inventory items',
    () async {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      final service = LocalActivityProgressService();
      await _recordActivityResult(
        service,
        _activityResult(endedAt: DateTime(2026, 5, 4, 12, 10)),
        vehicleId: VehicleCatalog.fireTruck.id,
      );
      await _recordActivityResult(
        service,
        _activityResult(endedAt: DateTime(2026, 5, 4, 12, 40)),
        vehicleId: VehicleCatalog.policeCar.id,
      );

      final snapshot = await service.loadSnapshot();
      final inventoryByRewardId = {
        for (final item in snapshot.inventory) item.rewardId: item.count,
      };

      expect(snapshot.inventory, hasLength(2));
      expect(
        inventoryByRewardId,
        containsPair(
          RewardCatalog.vehicleStickerIdForVehicle(VehicleCatalog.fireTruck.id),
          1,
        ),
      );
      expect(
        inventoryByRewardId,
        containsPair(
          RewardCatalog.vehicleStickerIdForVehicle(VehicleCatalog.policeCar.id),
          1,
        ),
      );
    },
  );

  test(
    'Completed overtime activity awards the selected vehicle sticker',
    () async {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      final service = LocalActivityProgressService();
      final recordedSession = await _recordActivityResult(
        service,
        _activityResult(
          startedAt: DateTime(2026, 5, 4, 12),
          endedAt: DateTime(2026, 5, 4, 12, 25),
          targetDuration: const Duration(minutes: 20),
          actualDuration: const Duration(minutes: 25),
          completedBeforeEnd: false,
        ),
      );

      expect(recordedSession.awardedRewards, hasLength(1));
      expect(
        recordedSession.awardedRewards.single.vehicleId,
        VehicleCatalog.motorcycle.id,
      );
    },
  );

  test('Activity with disabled rewards does not award stickers', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(activityId: 'play'),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityId, 'play');
  });

  test('Missing selected vehicle sticker does not award stickers', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(),
      vehicleId: 'missing_vehicle',
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.rewardIds, isEmpty);
  });

  test('Time-ended activity does not award stickers', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(completionStatus: ActivityCompletionStatus.timeEnded),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityCompleted, isTrue);
  });

  test('Time-ended activity can award stickers by parent choice', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        activityId: 'play',
        completionStatus: ActivityCompletionStatus.timeEnded,
        receiveSticker: true,
      ),
    );

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(recordedSession.entry.activityId, 'play');
    expect(recordedSession.entry.activityCompleted, isTrue);
  });

  test('Play time ended does not award stickers', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        activityId: 'play',
        completionStatus: ActivityCompletionStatus.timeEnded,
      ),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityId, 'play');
    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.timeEnded,
    );
  });

  test('Brushing completed at end awards one sticker', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        activityId: 'brushing',
        completionStatus: ActivityCompletionStatus.completedAtEnd,
      ),
    );

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(
      RewardCatalog.successStickers,
      contains(recordedSession.awardedRewards.single),
    );
    expect(recordedSession.entry.activityId, 'brushing');
    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.completedAtEnd,
    );
  });

  test('Incomplete activity does not award stickers', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        startedAt: DateTime(2026, 5, 4, 12),
        endedAt: DateTime(2026, 5, 4, 12, 25),
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 25),
        completedBeforeEnd: false,
        activityCompleted: false,
      ),
    );

    expect(recordedSession.awardedRewards, isEmpty);
    expect(recordedSession.entry.activityCompleted, isFalse);
    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.needsMoreTime,
    );
    expect(recordedSession.entry.rewardIds, isEmpty);
  });

  test('Arrival-completed activity records at-arrival status', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        actualDuration: const Duration(minutes: 20),
        completedBeforeEnd: false,
        completionStatus: ActivityCompletionStatus.completedAtEnd,
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(
      recordedSession.entry.completionStatus,
      ActivityCompletionStatus.completedAtEnd,
    );
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.completedAtEnd,
    );
  });

  test('Activity history stores directly selected marker ids', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(selectedMarkerIds: const ['top_teeth', 'bottom_teeth']),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.entry.selectedMarkerIds, [
      'top_teeth',
      'bottom_teeth',
    ]);
    expect(snapshot.history.single.selectedMarkerIds, [
      'top_teeth',
      'bottom_teeth',
    ]);

    final preferences = await SharedPreferences.getInstance();
    final rawHistory = preferences.getStringList('activityHistory');
    final rawInventory = preferences.getStringList('activityRewardInventory');
    expect(rawHistory, isNotNull);
    expect(rawInventory, isNotNull);
    expect(preferences.getStringList('mealHistory'), isNull);
    expect(preferences.getStringList('rewardInventory'), isNull);
    final historyJson = Map<String, Object?>.from(
      jsonDecode(rawHistory!.single) as Map,
    );
    expect(historyJson['activityId'], ActivityCatalog.defaultActivity.id);
    expect(historyJson['completedBeforeEnd'], isFalse);
    expect(historyJson['selectedMarkerIds'], ['top_teeth', 'bottom_teeth']);
    expect(historyJson.containsKey('completedBeforeArrival'), isFalse);
    expect(historyJson.containsKey('mealCompleted'), isFalse);
  });

  test('Local activity progress skips malformed history items', () async {
    final startedAt = DateTime(2026, 5, 4, 12);
    final endedAt = DateTime(2026, 5, 4, 12, 20);
    final vehicleStickerId = RewardCatalog.vehicleStickerIdForVehicle(
      VehicleCatalog.motorcycle.id,
    );
    final validHistory = <String>[
      jsonEncode({
        'id': 'valid-1',
        'activityId': 'brushing',
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'targetMs': const Duration(minutes: 20).inMilliseconds,
        'actualMs': const Duration(minutes: 20).inMilliseconds,
        'completedBeforeEnd': false,
        'completionStatus': ActivityCompletionStatus.completedAtEnd.name,
        'rewardIds': [vehicleStickerId],
        'selectedMarkerIds': ['top_teeth'],
      }),
      'not-json',
      jsonEncode(['not', 'a', 'map']),
      jsonEncode({'id': 'broken'}),
      jsonEncode({
        'id': 'valid-2',
        'activityId': 'play',
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'targetMs': const Duration(minutes: 10).inMilliseconds,
        'actualMs': const Duration(minutes: 11).inMilliseconds,
        'completedBeforeEnd': false,
        'completionStatus': ActivityCompletionStatus.completedAfterEnd.name,
        'rewardIds': <String>[],
        'selectedMarkerIds': ['bottom_teeth'],
      }),
    ];
    SharedPreferences.setMockInitialValues({'activityHistory': validHistory});

    final snapshot = await LocalActivityProgressService().loadSnapshot();

    expect(snapshot.history.map((entry) => entry.id), ['valid-1', 'valid-2']);
    expect(snapshot.history.first.rewardIds, [vehicleStickerId]);
    expect(snapshot.history.first.selectedMarkerIds, ['top_teeth']);
    expect(snapshot.history.last.activityId, 'play');
    expect(snapshot.history.last.selectedMarkerIds, ['bottom_teeth']);
  });

  test('Local activity progress skips malformed inventory items', () async {
    final acquiredAt = DateTime(2026, 5, 4, 12);
    final motorcycleStickerId = RewardCatalog.vehicleStickerIdForVehicle(
      VehicleCatalog.motorcycle.id,
    );
    final fireTruckStickerId = RewardCatalog.vehicleStickerIdForVehicle(
      VehicleCatalog.fireTruck.id,
    );
    final policeCarStickerId = RewardCatalog.vehicleStickerIdForVehicle(
      VehicleCatalog.policeCar.id,
    );
    final validInventory = <String>[
      jsonEncode({
        'rewardId': motorcycleStickerId,
        'acquiredAt': acquiredAt.toIso8601String(),
        'count': 2,
      }),
      'not-json',
      jsonEncode('not-a-map'),
      jsonEncode({'rewardId': fireTruckStickerId}),
      jsonEncode({
        'rewardId': policeCarStickerId,
        'acquiredAt': acquiredAt
            .add(const Duration(minutes: 1))
            .toIso8601String(),
        'count': 1,
      }),
    ];
    SharedPreferences.setMockInitialValues({
      'activityRewardInventory': validInventory,
    });

    final snapshot = await LocalActivityProgressService().loadSnapshot();

    expect(snapshot.inventory.map((item) => item.rewardId), [
      motorcycleStickerId,
      policeCarStickerId,
    ]);
    expect(snapshot.inventory.map((item) => item.count), [2, 1]);
  });

  test('Deleting activity history removes only the saved record', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 2,
      rewardText: '아이스크림',
    );
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(),
    );
    final beforeDelete = await service.loadSnapshot();

    expect(beforeDelete.history, hasLength(1));
    expect(beforeDelete.inventory, isNotEmpty);
    expect(beforeDelete.activeRewardGoals.single.filledCount, 1);

    final deleted = await service.deleteActivityHistoryEntry(
      recordedSession.entry.id,
    );
    final afterDelete = await service.loadSnapshot();

    expect(deleted, isTrue);
    expect(afterDelete.history, isEmpty);
    expect(afterDelete.inventory, hasLength(beforeDelete.inventory.length));
    expect(
      afterDelete.inventory.single.rewardId,
      beforeDelete.inventory.single.rewardId,
    );
    expect(
      afterDelete.inventory.single.count,
      beforeDelete.inventory.single.count,
    );
    expect(afterDelete.activeRewardGoals.single.filledCount, 1);
    expect(
      afterDelete.activeRewardGoals.single.filledSlots.single.activitySessionId,
      recordedSession.entry.id,
    );
  });

  test(
    'Deleting missing activity history entry leaves records unchanged',
    () async {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      final service = LocalActivityProgressService();
      await _recordActivityResult(service, _activityResult());

      final deleted = await service.deleteActivityHistoryEntry('missing');
      final snapshot = await service.loadSnapshot();

      expect(deleted, isFalse);
      expect(snapshot.history, hasLength(1));
    },
  );

  test(
    'Completed activity fills exactly one active reward goal slot',
    () async {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      final service = LocalActivityProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 5,
        rewardText: '아이스크림',
      );

      final recordedSession = await _recordActivityResult(
        service,
        _activityResult(),
      );
      final snapshot = await service.loadSnapshot();

      expect(recordedSession.updatedRewardGoal?.filledCount, 1);
      expect(recordedSession.rewardGoalJustReady, isFalse);
      expect(snapshot.activeRewardGoals.single.filledCount, 1);
    },
  );

  test('Completed activity fills all active reward goals', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );
    await service.createRewardGoal(requiredStickerCount: 7, rewardText: '딸기');

    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.updatedRewardGoals, hasLength(2));
    expect(snapshot.activeRewardGoals, hasLength(2));
    expect(snapshot.activeRewardGoals.map((goal) => goal.filledCount), [1, 1]);
  });

  test(
    'Parent-skipped completed activity does not fill reward goals',
    () async {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      final service = LocalActivityProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 5,
        rewardText: '아이스크림',
      );

      final recordedSession = await _recordActivityResult(
        service,
        _activityResult(
          completionStatus: ActivityCompletionStatus.completedAtEnd,
          receiveSticker: false,
        ),
      );
      final snapshot = await service.loadSnapshot();

      expect(recordedSession.awardedRewards, isEmpty);
      expect(recordedSession.updatedRewardGoal, isNull);
      expect(snapshot.activeRewardGoals.single.filledCount, 0);
      expect(snapshot.history.single.activityCompleted, isTrue);
    },
  );

  test('Parent-awarded time-ended activity fills reward goals', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        activityId: 'play',
        completionStatus: ActivityCompletionStatus.timeEnded,
        receiveSticker: true,
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(recordedSession.updatedRewardGoal?.filledCount, 1);
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.timeEnded,
    );
  });

  test('Only two active reward goals can be created', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );
    await service.createRewardGoal(requiredStickerCount: 7, rewardText: '딸기');

    expect(
      () =>
          service.createRewardGoal(requiredStickerCount: 10, rewardText: '젤리'),
      throwsStateError,
    );
  });

  test(
    'Legacy single reward goal storage loads into list storage shape',
    () async {
      final legacyGoal = RewardGoal(
        id: 'legacy-active',
        rewardText: '아이스크림',
        requiredStickerCount: 5,
        filledSlots: const [],
        createdAt: DateTime(2026, 5, 4, 12),
        status: RewardGoalStatus.active,
      );
      final legacyUsedGoal = RewardGoal(
        id: 'legacy-used',
        rewardText: '딸기',
        requiredStickerCount: 1,
        filledSlots: [
          RewardGoalSlot(
            rewardId: RewardCatalog.vehicleStickerIdForVehicle(
              VehicleCatalog.motorcycle.id,
            ),
            filledAt: DateTime(2026, 5, 4, 12),
            activitySessionId: 'activity-1',
          ),
        ],
        createdAt: DateTime(2026, 5, 4, 12),
        status: RewardGoalStatus.redeemed,
        redeemedAt: DateTime(2026, 5, 5, 12),
      );
      SharedPreferences.setMockInitialValues({
        'activeRewardGoal': jsonEncode(legacyGoal.toJson()),
        'redeemedRewardGoals': [jsonEncode(legacyUsedGoal.toJson())],
      });

      final snapshot = await LocalActivityProgressService().loadSnapshot();

      expect(snapshot.activeRewardGoals, hasLength(1));
      expect(snapshot.activeRewardGoals.first.rewardText, '아이스크림');
      expect(snapshot.usedRewardGoals, hasLength(1));
      expect(snapshot.usedRewardGoals.first.status, RewardGoalStatus.used);
    },
  );

  test('Legacy history key loads with completion status fallback', () async {
    SharedPreferences.setMockInitialValues({
      'mealHistory': [
        jsonEncode({
          'id': 'legacy-meal',
          'startedAt': DateTime(2026, 5, 4, 12).toIso8601String(),
          'endedAt': DateTime(2026, 5, 4, 12, 25).toIso8601String(),
          'targetMs': const Duration(minutes: 20).inMilliseconds,
          'actualMs': const Duration(minutes: 25).inMilliseconds,
          'completedBeforeArrival': false,
          'rewardIds': <String>[],
        }),
      ],
    });

    final snapshot = await LocalActivityProgressService().loadSnapshot();

    expect(snapshot.history.single.activityCompleted, isTrue);
    expect(
      snapshot.history.single.activityId,
      ActivityCatalog.defaultActivity.id,
    );
    expect(
      snapshot.history.single.completionStatus,
      ActivityCompletionStatus.completedAfterEnd,
    );
    expect(snapshot.history.single.selectedMarkerIds, isEmpty);
  });

  test('Fast activity fills only one reward goal slot', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(
        targetDuration: const Duration(minutes: 20),
        actualDuration: const Duration(minutes: 13),
      ),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.awardedRewards, hasLength(1));
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
  });

  test('Incomplete activity does not fill a reward goal slot', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(activityCompleted: false),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.updatedRewardGoal, isNull);
    expect(snapshot.activeRewardGoals.single.filledCount, 0);
  });

  test('Reward goal becomes earned when required count is reached', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 2,
      rewardText: '아이스크림',
    );

    await _recordActivityResult(
      service,
      _activityResult(endedAt: DateTime(2026, 5, 4, 12)),
    );
    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(endedAt: DateTime(2026, 5, 4, 13)),
    );
    final snapshot = await service.loadSnapshot();

    expect(recordedSession.rewardGoalJustReady, isTrue);
    expect(snapshot.activeRewardGoals, isEmpty);
    expect(snapshot.earnedRewardGoals.single.status, RewardGoalStatus.earned);
    expect(snapshot.earnedRewardGoals.single.earnedAt, isNotNull);
  });

  test('Using an earned goal moves it to used history', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 1,
      rewardText: '아이스크림',
    );
    await _recordActivityResult(service, _activityResult());

    final usedGoal = await service.useEarnedRewardGoal();
    final snapshot = await service.loadSnapshot();

    expect(usedGoal?.status, RewardGoalStatus.used);
    expect(usedGoal?.usedAt, isNotNull);
    expect(snapshot.activeRewardGoals, isEmpty);
    expect(snapshot.earnedRewardGoals, isEmpty);
    expect(snapshot.usedRewardGoals, hasLength(1));
    expect(snapshot.usedRewardGoals.first.rewardText, '아이스크림');
  });

  test('Active reward goal can be updated', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final updatedGoal = await service.updateActiveRewardGoal(
      requiredStickerCount: 7,
      rewardText: '딸기',
    );
    final snapshot = await service.loadSnapshot();

    expect(updatedGoal?.rewardText, '딸기');
    expect(updatedGoal?.requiredStickerCount, 7);
    expect(snapshot.activeRewardGoals.single.rewardText, '딸기');
    expect(snapshot.activeRewardGoals.single.requiredStickerCount, 7);
  });

  test(
    'Reducing required count to filled count makes reward goal earned',
    () async {
      SharedPreferences.setMockInitialValues({
        'savedActivityTimerPresetsInitialized': true,
      });

      final service = LocalActivityProgressService();
      await service.createRewardGoal(
        requiredStickerCount: 5,
        rewardText: '아이스크림',
      );
      await _recordActivityResult(service, _activityResult());
      await _recordActivityResult(
        service,
        _activityResult(endedAt: DateTime(2026, 5, 4, 13)),
      );

      final updatedGoal = await service.updateActiveRewardGoal(
        requiredStickerCount: 2,
        rewardText: '아이스크림',
      );

      final snapshot = await service.loadSnapshot();

      expect(updatedGoal?.status, RewardGoalStatus.earned);
      expect(updatedGoal?.earnedAt, isNotNull);
      expect(snapshot.activeRewardGoals, isEmpty);
      expect(snapshot.earnedRewardGoals, hasLength(1));
    },
  );

  test('Active reward goal can be canceled', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final canceledGoal = await service.cancelActiveRewardGoal();
    final snapshot = await service.loadSnapshot();

    expect(canceledGoal?.rewardText, '아이스크림');
    expect(snapshot.activeRewardGoals, isEmpty);
    expect(snapshot.usedRewardGoals, isEmpty);
  });

  test('Existing sticker inventory counts still increase', () async {
    SharedPreferences.setMockInitialValues({
      'savedActivityTimerPresetsInitialized': true,
    });

    final service = LocalActivityProgressService();
    await service.createRewardGoal(
      requiredStickerCount: 5,
      rewardText: '아이스크림',
    );

    final recordedSession = await _recordActivityResult(
      service,
      _activityResult(),
    );
    final snapshot = await service.loadSnapshot();
    final inventoryCount = snapshot.inventory.fold<int>(
      0,
      (total, item) => total + item.count,
    );

    expect(inventoryCount, recordedSession.awardedRewards.length);
    expect(snapshot.activeRewardGoals.single.filledCount, 1);
  });
}

ActivitySessionResult _activityResult({
  String activityId = 'brushing',
  DateTime? startedAt,
  DateTime? endedAt,
  Duration targetDuration = const Duration(minutes: 20),
  Duration actualDuration = const Duration(minutes: 25),
  bool completedBeforeEnd = false,
  bool activityCompleted = true,
  ActivityCompletionStatus? completionStatus,
  List<String> selectedMarkerIds = const [],
  bool includeStickerDecision = true,
  bool? receiveSticker,
}) {
  final resolvedStartedAt = startedAt ?? DateTime(2026, 5, 4, 12);
  final resolvedEndedAt = endedAt ?? resolvedStartedAt.add(actualDuration);
  final resolvedCompletionStatus =
      completionStatus ??
      (activityCompleted
          ? (completedBeforeEnd
                ? ActivityCompletionStatus.completedBeforeEnd
                : ActivityCompletionStatus.completedAfterEnd)
          : ActivityCompletionStatus.needsMoreTime);

  return ActivitySessionResult(
    activityId: activityId,
    startedAt: resolvedStartedAt,
    endedAt: resolvedEndedAt,
    targetDuration: targetDuration,
    actualDuration: actualDuration,
    completedBeforeEnd: completedBeforeEnd,
    completionStatus: resolvedCompletionStatus,
    selectedMarkerIds: selectedMarkerIds,
    receiveSticker: includeStickerDecision
        ? receiveSticker ??
              (ActivityCatalog.findById(activityId).rewardEnabledByDefault &&
                  activityCompletionStatusCanReceiveSticker(
                    resolvedCompletionStatus,
                  ))
        : null,
  );
}

Future<RecordedActivitySession> _recordActivityResult(
  LocalActivityProgressService service,
  ActivitySessionResult result, {
  String vehicleId = 'motorcycle',
}) {
  return service.recordActivityResult(result, vehicleId: vehicleId);
}
