import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/services/local_activity_progress_service.dart';

import 'support/activity_result_test_data.dart';
import 'support/pending_activity_result_test_data.dart';
import 'support/progress_preferences_store.dart';

const historyKey = 'activityHistory';
const inventoryKey = 'activityRewardInventory';
const activeKey = 'activityActiveRewardGoals';
const earnedKey = 'activityEarnedRewardGoals';
const usedKey = 'activityUsedRewardGoals';
const deletedKey = 'deletedActivitySessionIds';
const journalKey = 'activityRecordTransaction';

Map<String, Object?> goal(
  String id,
  String status,
  List<String> sessions, {
  int required = 2,
}) => {
  'id': id,
  'rewardText': 'Park',
  'requiredStickerCount': required,
  'createdAt': '2026-10-01T00:00:00.000',
  'status': status,
  'earnedAt': status == 'active' ? null : '2026-10-02T00:00:00.000',
  'readyAt': status == 'active' ? null : '2026-10-02T00:00:00.000',
  'extension': {'keep': true},
  'filledSlots': sessions
      .map(
        (id) => {
          'rewardId': 'unknown-sticker',
          'filledAt': '2026-10-02T00:00:00.000',
          'mealSessionId': id,
          'extension': 7,
        },
      )
      .toList(),
};

Future<Map<String, Object>> rawState() async {
  final preferences = await SharedPreferences.getInstance();
  return {for (final key in preferences.getKeys()) key: preferences.get(key)!};
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final linked in [false, true]) {
    test(
      'delete linked=$linked is idempotent and blocks stale result after restart',
      () async {
        final service = LocalActivityProgressService();
        final result = pendingResult(receiveSticker: true).result;
        await service.recordActivityResult(result, vehicleId: 'motorcycle');
        expect(
          await service.deleteActivityHistoryEntry(
            result.sessionId!,
            deleteLinkedRewards: linked,
          ),
          isTrue,
        );
        expect(
          await LocalActivityProgressService().deleteActivityHistoryEntry(
            result.sessionId!,
            deleteLinkedRewards: linked,
          ),
          isFalse,
        );
        await expectLater(
          service.recordActivityResult(result, vehicleId: 'motorcycle'),
          throwsA(isA<DeletedActivitySessionException>()),
        );
        final snapshot = await service.loadSnapshot();
        expect(snapshot.history, isEmpty);
        expect(snapshot.inventory.length, linked ? 0 : 1);
      },
    );
  }

  for (final status in ActivityCompletionStatus.values) {
    for (final choice in [null, false, true]) {
      test('uses actual award for ${status.name}/$choice', () async {
        final service = LocalActivityProgressService();
        final result = activityResult(
          completionStatus: status,
          includeStickerDecision: false,
        ).copyWith(receiveSticker: choice);
        final recorded = await service.recordActivityResult(
          result,
          vehicleId: 'motorcycle',
        );
        await service.deleteActivityHistoryEntry(
          recorded.entry.id,
          deleteLinkedRewards: true,
        );
        expect((await service.loadSnapshot()).inventory, isEmpty);
      });
    }
  }

  test(
    'raw history-only deletion preserves corrupt and legacy reward data',
    () async {
      final service = LocalActivityProgressService();
      final entry = (await service.recordActivityResult(
        activityResult(),
        vehicleId: 'motorcycle',
      )).entry;
      SharedPreferences.setMockInitialValues({
        'mealHistory': [
          jsonEncode(entry.toJson()),
          '{"id":"other","unknown":9}',
        ],
        'rewardInventory': ['corrupt'],
        'activeRewardGoal': 'corrupt',
        'earnedRewardGoals': ['corrupt'],
        'redeemedRewardGoals': ['corrupt'],
      });
      final before = await rawState();
      await service.deleteActivityHistoryEntry(entry.id);
      final after = await rawState();
      for (final key in before.keys.where((key) => key != 'mealHistory')) {
        expect(after[key], before[key], reason: key);
      }
      expect(after[historyKey], ['{"id":"other","unknown":9}']);
    },
  );

  test(
    'duplicate or unidentifiable history aborts both deletes without writes',
    () async {
      final service = LocalActivityProgressService();
      final entry = (await service.recordActivityResult(
        activityResult(),
        vehicleId: 'motorcycle',
      )).entry;
      for (final other in [jsonEncode(entry.toJson()), 'broken', '{}']) {
        SharedPreferences.setMockInitialValues({
          historyKey: [jsonEncode(entry.toJson()), other],
        });
        final before = await rawState();
        for (final linked in [false, true]) {
          await expectLater(
            service.deleteActivityHistoryEntry(
              entry.id,
              deleteLinkedRewards: linked,
            ),
            throwsA(isA<ActivityProgressDataException>()),
          );
          expect(await rawState(), before);
        }
      }
    },
  );

  test(
    'unknown duplicate reward IDs subtract frequency; unused boards return in order, used bytes stay',
    () async {
      final service = LocalActivityProgressService();
      final entry = (await service.recordActivityResult(
        activityResult(),
        vehicleId: 'motorcycle',
      )).entry;
      final rawHistory = entry.toJson()
        ..['rewardIds'] = ['unknown-sticker', 'unknown-sticker', 'missing'];
      final used = jsonEncode(goal('used', 'used', [entry.id], required: 1));
      SharedPreferences.setMockInitialValues({
        historyKey: [jsonEncode(rawHistory)],
        inventoryKey: [
          jsonEncode({
            'rewardId': 'unknown-sticker',
            'count': 5,
            'acquiredAt': '2026-10-01',
            'extra': 1,
          }),
        ],
        activeKey: [
          jsonEncode(
            goal('active', 'active', [entry.id, 'other'], required: 4),
          ),
        ],
        earnedKey: [
          jsonEncode(goal('earned1', 'earned', [entry.id, 'other'])),
          jsonEncode(goal('earned2', 'ready', [entry.id, 'other'])),
        ],
        usedKey: [used],
        'usedRewardGoals': ['broken'],
        'redeemedRewardGoals': [used],
      });
      expect(await service.hasLinkedRewards(entry.id), isTrue);
      await service.deleteActivityHistoryEntry(
        entry.id,
        deleteLinkedRewards: true,
      );
      final state = await rawState();
      expect(
        jsonDecode((state[inventoryKey] as List).single),
        containsPair('count', 3),
      );
      expect(
        jsonDecode((state[inventoryKey] as List).single),
        containsPair('extra', 1),
      );
      final boards = (state[activeKey] as List)
          .map((raw) => jsonDecode(raw as String))
          .toList();
      expect(boards.map((board) => board['id']), [
        'active',
        'earned1',
        'earned2',
      ]);
      for (final board in boards) {
        expect(board['filledSlots'], hasLength(1));
        expect(board['filledSlots'].single['extension'], 7);
        expect(board['extension'], {'keep': true});
        expect(board['earnedAt'], isNull);
        expect(board['readyAt'], isNull);
      }
      expect(state[usedKey], [used]);
      expect(state['usedRewardGoals'], ['broken']);
      expect(state['redeemedRewardGoals'], [used]);
      expect(await service.loadActiveRewardGoals(), hasLength(3));
      await expectLater(
        service.createRewardGoal(requiredStickerCount: 3, rewardText: 'New'),
        throwsStateError,
      );
      await service.recordActivityResult(
        activityResult(endedAt: DateTime(2026, 10, 10)),
        vehicleId: 'motorcycle',
      );
      final snapshot = await service.loadSnapshot();
      expect(snapshot.activeRewardGoals.single.filledCount, 2);
      expect(snapshot.earnedRewardGoals, hasLength(2));
    },
  );

  test(
    'full excess slots survive deletion, editing, completion and use',
    () async {
      final service = LocalActivityProgressService();
      final first = (await service.recordActivityResult(
        activityResult(),
        vehicleId: 'motorcycle',
      )).entry;
      final second = (await service.recordActivityResult(
        activityResult(endedAt: DateTime(2026, 10, 9)),
        vehicleId: 'motorcycle',
      )).entry;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(earnedKey, [
        jsonEncode(
          goal('excess', 'earned', [
            first.id,
            second.id,
            'a',
            'b',
            'c',
            'd',
          ], required: 5),
        ),
      ]);
      await service.deleteActivityHistoryEntry(
        first.id,
        deleteLinkedRewards: true,
      );
      expect(
        (await service.loadSnapshot()).earnedRewardGoals.single.filledCount,
        5,
      );
      await service.deleteActivityHistoryEntry(
        second.id,
        deleteLinkedRewards: true,
      );
      expect(
        (await service.loadSnapshot()).activeRewardGoals.single.filledCount,
        4,
      );
      await service.updateActiveRewardGoal(
        goalId: 'excess',
        requiredStickerCount: 2,
        rewardText: 'Changed',
      );
      expect(
        (await service.loadSnapshot()).earnedRewardGoals.single.filledCount,
        4,
      );
      await service.useEarnedRewardGoal(goalId: 'excess');
      final used = jsonDecode(preferences.getStringList(usedKey)!.single);
      expect(used['filledSlots'], hasLength(4));
      expect(used['filledSlots'].first['extension'], 7);
      expect(used['extension'], {'keep': true});
    },
  );

  test(
    'no rewardIds still removes linked slots and migrates legacy earned by status',
    () async {
      final service = LocalActivityProgressService();
      final entry = (await service.recordActivityResult(
        activityResult(receiveSticker: false),
        vehicleId: 'motorcycle',
      )).entry;
      SharedPreferences.setMockInitialValues({
        historyKey: [jsonEncode(entry.toJson())],
        'activeRewardGoal': jsonEncode(
          goal('legacy', 'ready', [entry.id], required: 1),
        ),
      });
      expect(await service.hasLinkedRewards(entry.id), isTrue);
      await service.deleteActivityHistoryEntry(
        entry.id,
        deleteLinkedRewards: true,
      );
      expect(
        (await service.loadSnapshot()).activeRewardGoals.single.filledCount,
        0,
      );
      expect((await rawState()).containsKey('activeRewardGoal'), isFalse);
    },
  );

  for (final corrupt in [
    {
      'filledSlots': [
        {'rewardId': 'x'},
      ],
    },
    {'status': 'unknown'},
    {'status': 3},
    {'requiredStickerCount': 0},
    {'earnedAt': 3},
  ]) {
    test(
      'invalid reward ${corrupt.keys.first} aborts linked deletion and leaves queue usable',
      () async {
        final service = LocalActivityProgressService();
        final entry = (await service.recordActivityResult(
          activityResult(),
          vehicleId: 'motorcycle',
        )).entry;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setStringList(activeKey, [
          jsonEncode({...goal('bad', 'active', []), ...corrupt}),
        ]);
        final before = await rawState();
        await expectLater(
          service.deleteActivityHistoryEntry(
            entry.id,
            deleteLinkedRewards: true,
          ),
          throwsA(isA<ActivityProgressDataException>()),
        );
        expect(await rawState(), before);
        expect(await service.deleteActivityHistoryEntry(entry.id), isTrue);
      },
    );
  }

  for (final invalid in [
    'bad',
    <String>[''],
    <String>[' ', 'good'],
  ]) {
    test(
      'bad deleted IDs $invalid block changes but permit snapshot reads',
      () async {
        final service = LocalActivityProgressService();
        final preferences = await SharedPreferences.getInstance();
        if (invalid is String) {
          await preferences.setString(deletedKey, invalid);
        } else {
          await preferences.setStringList(deletedKey, invalid as List<String>);
        }
        expect((await service.loadSnapshot()).history, isEmpty);
        await expectLater(
          service.recordActivityResult(
            activityResult(),
            vehicleId: 'motorcycle',
          ),
          throwsA(isA<ActivityProgressDataException>()),
        );
      },
    );
  }

  test(
    'journal validates every field before first write and retains original',
    () async {
      final raw = jsonEncode({
        historyKey: <String>[],
        inventoryKey: [3],
      });
      SharedPreferences.setMockInitialValues({
        historyKey: ['original'],
        journalKey: raw,
      });
      await expectLater(
        LocalActivityProgressService().loadSnapshot(),
        throwsA(isA<ActivityProgressDataException>()),
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getStringList(historyKey), ['original']);
      expect(preferences.getString(journalKey), raw);
    },
  );

  test(
    'old partial journal preserves unrelated legacy rewards and tombstones',
    () async {
      SharedPreferences.setMockInitialValues({
        'activeRewardGoal': jsonEncode(goal('legacy', 'earned', ['a'])),
        'earnedRewardGoals': [
          jsonEncode(goal('earned', 'earned', ['b'])),
        ],
        deletedKey: ['old'],
        journalKey: jsonEncode({
          historyKey: <String>[],
          inventoryKey: <String>[],
        }),
      });
      final before = await rawState();
      await LocalActivityProgressService().loadSnapshot();
      final after = await rawState();
      for (final key in ['activeRewardGoal', 'earnedRewardGoals', deletedKey]) {
        expect(after[key], before[key]);
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        journalKey,
        jsonEncode({activeKey: <String>[]}),
      );
      await LocalActivityProgressService().loadSnapshot();
      expect(preferences.get('activeRewardGoal'), before['activeRewardGoal']);
      expect(preferences.get('earnedRewardGoals'), before['earnedRewardGoals']);
    },
  );

  for (final failKey in [
    journalKey,
    deletedKey,
    historyKey,
    inventoryKey,
    activeKey,
    earnedKey,
    'mealHistory',
    'rewardInventory',
    'activeRewardGoal',
    'activeRewardGoals',
    'earnedRewardGoals',
    'finishJournal',
  ]) {
    for (final throws in [false, true]) {
      test('recover $failKey / throw=$throws exactly once', () async {
        final store = installProgressPreferencesStore();
        final service = LocalActivityProgressService();
        final result = pendingResult(receiveSticker: true).result;
        final entry = (await service.recordActivityResult(
          result,
          vehicleId: 'motorcycle',
        )).entry;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setStringList('mealHistory', [
          jsonEncode(entry.toJson()),
        ]);
        await preferences.setStringList(
          'rewardInventory',
          preferences.getStringList(inventoryKey)!,
        );
        await preferences.setString(
          'activeRewardGoal',
          jsonEncode(goal('single', 'active', [], required: 3)),
        );
        await preferences.setStringList('activeRewardGoals', [
          jsonEncode(goal('active', 'active', [entry.id], required: 3)),
        ]);
        await preferences.setStringList('earnedRewardGoals', [
          jsonEncode(goal('earned', 'earned', [entry.id], required: 1)),
        ]);
        store.failKey = failKey == 'finishJournal' ? journalKey : failKey;
        store.throwFailure = throws;
        // For journal removal hold the first history write, then arm journal failure.
        if (failKey == 'finishJournal') {
          store.failKey = null;
          store.holdKey = deletedKey;
          final deletion = service.deleteActivityHistoryEntry(
            entry.id,
            deleteLinkedRewards: true,
          );
          await store.entered.future;
          store.failKey = journalKey;
          store.release.complete();
          await expectLater(
            deletion,
            throwsA(isA<ActivityProgressStorageException>()),
          );
        } else {
          await expectLater(
            service.deleteActivityHistoryEntry(
              entry.id,
              deleteLinkedRewards: true,
            ),
            throwsA(isA<ActivityProgressStorageException>()),
          );
        }
        final snapshot = await LocalActivityProgressService().loadSnapshot();
        if (failKey == journalKey) {
          expect(snapshot.history, hasLength(1));
          expect(snapshot.inventory.single.count, 1);
        } else {
          expect(snapshot.history, isEmpty);
          expect(snapshot.inventory, isEmpty);
          expect(snapshot.activeRewardGoals, hasLength(2));
          expect(
            await service.deleteActivityHistoryEntry(
              entry.id,
              deleteLinkedRewards: true,
            ),
            isFalse,
          );
          await expectLater(
            service.recordActivityResult(result, vehicleId: 'motorcycle'),
            throwsA(isA<DeletedActivitySessionException>()),
          );
        }
      });
    }
  }

  test(
    'failure after disk write survives reload without double subtraction',
    () async {
      final store = installProgressPreferencesStore();
      final service = LocalActivityProgressService();
      final entry = (await service.recordActivityResult(
        activityResult(),
        vehicleId: 'motorcycle',
      )).entry;
      store
        ..failKey = inventoryKey
        ..throwFailure = true
        ..failAfterWrite = true;
      await expectLater(
        service.deleteActivityHistoryEntry(entry.id, deleteLinkedRewards: true),
        throwsA(isA<ActivityProgressStorageException>()),
      );
      final snapshot = await LocalActivityProgressService().loadSnapshot();
      expect(snapshot.history, isEmpty);
      expect(snapshot.inventory, isEmpty);
    },
  );

  test(
    'queue serializes in-flight completion and deletion across service instances',
    () async {
      final store = installProgressPreferencesStore();
      final service = LocalActivityProgressService();
      final result = pendingResult(receiveSticker: true).result;
      store.holdKey = historyKey;
      final record = service.recordActivityResult(
        result,
        vehicleId: 'motorcycle',
      );
      await store.entered.future;
      final delete = LocalActivityProgressService().deleteActivityHistoryEntry(
        result.sessionId!,
        deleteLinkedRewards: true,
      );
      store.release.complete();
      await record;
      expect(await delete, isTrue);
      expect((await service.loadSnapshot()).inventory, isEmpty);
    },
  );

  test('10000 deleted IDs remain intact in mock storage', () async {
    final ids = List.generate(10000, (index) => 'deleted-$index');
    SharedPreferences.setMockInitialValues({deletedKey: ids});
    final service = LocalActivityProgressService();
    final entry = (await service.recordActivityResult(
      activityResult(),
      vehicleId: 'motorcycle',
    )).entry;
    await service.deleteActivityHistoryEntry(entry.id);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList(deletedKey), [...ids, entry.id]);
  });
  for (final selected in [usedKey, 'usedRewardGoals', 'redeemedRewardGoals']) {
    for (final empty in [false, true]) {
      test(
        'used source $selected empty=$empty respects fallback priority and raw preservation',
        () async {
          final old = jsonEncode(
            goal(
              'old',
              selected == 'redeemedRewardGoals' ? 'redeemed' : 'used',
              ['a', 'b', 'c'],
              required: 1,
            ),
          );
          final selectedList = empty ? <String>[] : [old];
          final initial = <String, Object>{
            earnedKey: [
              jsonEncode(goal('earned', 'earned', ['a'], required: 1)),
            ],
            'redeemedRewardGoals': [old],
            if (selected != 'redeemedRewardGoals')
              'usedRewardGoals': selectedList,
            if (selected == usedKey) usedKey: selectedList,
          };
          if (selected == 'redeemedRewardGoals') {
            initial['redeemedRewardGoals'] = selectedList;
          }
          SharedPreferences.setMockInitialValues(initial);
          await LocalActivityProgressService().useEarnedRewardGoal(
            goalId: 'earned',
          );
          final state = await rawState();
          final used = state[usedKey] as List;
          expect(used, hasLength(empty ? 1 : 2));
          if (!empty) {
            if (selected == 'redeemedRewardGoals') {
              final json = jsonDecode(used.last as String);
              expect(json['status'], 'used');
              expect(json['filledSlots'], hasLength(3));
              expect(json['extension'], {'keep': true});
            } else {
              expect(used.last, old);
            }
          }
          if (selected != usedKey) expect(state.containsKey(selected), isFalse);
          if (selected == usedKey) {
            expect(state['usedRewardGoals'], selectedList);
          }
          if (selected != 'redeemedRewardGoals') {
            expect(state['redeemedRewardGoals'], [old]);
          }
        },
      );
    }
  }

  for (final source in ['usedRewardGoals', 'redeemedRewardGoals']) {
    for (final failed in [earnedKey, usedKey, source, 'journalRemoval']) {
      test(
        'reward use migration recovers $source after failure at $failed',
        () async {
          final store = installProgressPreferencesStore();
          final preferences = await SharedPreferences.getInstance();
          final old = jsonEncode(goal('old', 'used', ['old'], required: 1));
          await preferences.setStringList(source, [old]);
          await preferences.setStringList(earnedKey, [
            jsonEncode(goal('earned', 'earned', ['a'], required: 1)),
          ]);
          final service = LocalActivityProgressService();
          if (failed == 'journalRemoval') {
            store.holdKey = earnedKey;
            final use = service.useEarnedRewardGoal();
            await store.entered.future;
            store.failKey = journalKey;
            store.release.complete();
            await expectLater(
              use,
              throwsA(isA<ActivityProgressStorageException>()),
            );
          } else {
            store.failKey = failed;
            await expectLater(
              service.useEarnedRewardGoal(),
              throwsA(isA<ActivityProgressStorageException>()),
            );
          }
          final snapshot = await LocalActivityProgressService().loadSnapshot();
          expect(snapshot.earnedRewardGoals, isEmpty);
          expect(snapshot.usedRewardGoals, hasLength(2));
          expect(preferences.containsKey(source), isFalse);
          expect(await service.useEarnedRewardGoal(), isNull);
        },
      );
    }
  }

  test(
    'invalid selected used source blocks reward use without normalizing data',
    () async {
      SharedPreferences.setMockInitialValues({
        earnedKey: [
          jsonEncode(goal('earned', 'earned', ['a'], required: 1)),
        ],
        usedKey: ['{"id":"bad"}'],
      });
      final before = await rawState();
      await expectLater(
        LocalActivityProgressService().useEarnedRewardGoal(),
        throwsA(isA<ActivityProgressDataException>()),
      );
      expect(await rawState(), before);
    },
  );

  test('empty new active/earned lists override hidden legacy lists', () async {
    final service = LocalActivityProgressService();
    final entry = (await service.recordActivityResult(
      activityResult(),
      vehicleId: 'motorcycle',
    )).entry;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(activeKey, []);
    await preferences.setStringList(earnedKey, []);
    await preferences.setStringList('activeRewardGoals', [
      jsonEncode(goal('hidden', 'active', [entry.id])),
    ]);
    await preferences.setStringList('earnedRewardGoals', [
      jsonEncode(goal('hiddenEarned', 'earned', [entry.id])),
    ]);
    await service.deleteActivityHistoryEntry(
      entry.id,
      deleteLinkedRewards: true,
    );
    expect((await service.loadSnapshot()).activeRewardGoals, isEmpty);
    expect((await service.loadSnapshot()).earnedRewardGoals, isEmpty);
  });

  for (final status in ['used', 'redeemed', 'archived', 'unknown']) {
    test(
      'unsupported single legacy status $status is preserved on failed linked delete',
      () async {
        final service = LocalActivityProgressService();
        final entry = (await service.recordActivityResult(
          activityResult(),
          vehicleId: 'motorcycle',
        )).entry;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          'activeRewardGoal',
          jsonEncode(goal('single', status, [entry.id])),
        );
        final before = await rawState();
        await expectLater(
          service.deleteActivityHistoryEntry(
            entry.id,
            deleteLinkedRewards: true,
          ),
          throwsA(isA<ActivityProgressDataException>()),
        );
        expect(await rawState(), before);
      },
    );
  }

  test(
    'duplicate inventory and goal IDs block linked delete before journal creation',
    () async {
      final service = LocalActivityProgressService();
      final entry = (await service.recordActivityResult(
        activityResult(),
        vehicleId: 'motorcycle',
      )).entry;
      final preferences = await SharedPreferences.getInstance();
      final inventory = preferences.getStringList(inventoryKey)!;
      await preferences.setStringList(inventoryKey, [
        ...inventory,
        ...inventory,
      ]);
      var before = await rawState();
      await expectLater(
        service.deleteActivityHistoryEntry(entry.id, deleteLinkedRewards: true),
        throwsA(isA<ActivityProgressDataException>()),
      );
      expect(await rawState(), before);
      await preferences.setStringList(inventoryKey, inventory);
      await preferences.setStringList(activeKey, [
        jsonEncode(goal('same', 'active', [])),
      ]);
      await preferences.setStringList(earnedKey, [
        jsonEncode(goal('same', 'earned', ['a'])),
      ]);
      before = await rawState();
      await expectLater(
        service.deleteActivityHistoryEntry(entry.id, deleteLinkedRewards: true),
        throwsA(isA<ActivityProgressDataException>()),
      );
      expect(await rawState(), before);
    },
  );

  for (final operation in ['edit', 'cancel', 'clear', 'use', 'create']) {
    test(
      'serializes deletion then $operation against current lossless data',
      () async {
        final store = installProgressPreferencesStore();
        final service = LocalActivityProgressService();
        final entry = (await service.recordActivityResult(
          activityResult(),
          vehicleId: 'motorcycle',
        )).entry;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setStringList(activeKey, [
          jsonEncode(goal('active', 'active', [entry.id], required: 3)),
        ]);
        await preferences.setStringList(earnedKey, [
          jsonEncode(goal('earned', 'earned', [entry.id], required: 1)),
        ]);
        store.holdKey = deletedKey;
        final deletion = service.deleteActivityHistoryEntry(
          entry.id,
          deleteLinkedRewards: true,
        );
        await store.entered.future;
        final secondService = LocalActivityProgressService();
        final Future<Object?> change = switch (operation) {
          'edit' => secondService.updateActiveRewardGoal(
            goalId: 'active',
            requiredStickerCount: 4,
            rewardText: 'Edited',
          ),
          'cancel' => secondService.cancelActiveRewardGoal(goalId: 'active'),
          'clear' => secondService.clearActiveRewardGoal(),
          'use' => secondService.useEarnedRewardGoal(goalId: 'earned'),
          _ => secondService.createRewardGoal(
            requiredStickerCount: 3,
            rewardText: 'New',
          ),
        };
        // After deletion two boards are active, so new creation must fail.
        final checkedChange = operation == 'create'
            ? expectLater(change, throwsStateError)
            : change;
        store.release.complete();
        await deletion;
        await checkedChange;
        final snapshot = await service.loadSnapshot();
        expect(snapshot.history, isEmpty);
        expect(snapshot.inventory, isEmpty);
        expect(snapshot.usedRewardGoals, isEmpty);
        expect(
          snapshot.activeRewardGoals.every((goal) => goal.filledCount == 0),
          isTrue,
        );
        if (operation == 'edit') {
          expect(snapshot.activeRewardGoals.first.rewardText, 'Edited');
        }
      },
    );
  }
  test(
    'later completion refuses corrupt inventory rather than overwriting it',
    () async {
      SharedPreferences.setMockInitialValues({
        inventoryKey: ['{"rewardId":"unknown","count":"broken"}'],
      });
      final before = await rawState();
      final service = LocalActivityProgressService();
      await expectLater(
        service.recordActivityResult(activityResult(), vehicleId: 'motorcycle'),
        throwsA(isA<ActivityProgressDataException>()),
      );
      expect(await rawState(), before);
      expect((await service.loadSnapshot()).inventory, isEmpty);
    },
  );
}
