import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_history_entry.dart';
import '../models/meal_progress_snapshot.dart';
import '../models/meal_session_result.dart';
import '../models/reward_item.dart';

class LocalMealProgressService {
  LocalMealProgressService({Random? random}) : _random = random ?? Random();

  static const _historyKey = 'mealHistory';
  static const _inventoryKey = 'rewardInventory';

  final Random _random;

  Future<MealProgressSnapshot> loadSnapshot() async {
    final preferences = await SharedPreferences.getInstance();

    return MealProgressSnapshot(
      history: _decodeList(
        preferences.getStringList(_historyKey),
        MealHistoryEntry.fromJson,
      ),
      inventory: _decodeList(
        preferences.getStringList(_inventoryKey),
        RewardInventoryItem.fromJson,
      ),
    );
  }

  Future<RecordedMealSession> recordMealResult(MealSessionResult result) async {
    final preferences = await SharedPreferences.getInstance();
    final history = _decodeList(
      preferences.getStringList(_historyKey),
      MealHistoryEntry.fromJson,
    ).toList();
    final inventory = _decodeList(
      preferences.getStringList(_inventoryKey),
      RewardInventoryItem.fromJson,
    ).toList();

    final awardedRewards = _selectRewards(result);
    final entry = MealHistoryEntry(
      id: result.endedAt.microsecondsSinceEpoch.toString(),
      startedAt: result.startedAt,
      endedAt: result.endedAt,
      targetDuration: result.targetDuration,
      actualDuration: result.actualDuration,
      completedBeforeArrival: result.completedBeforeArrival,
      rewardIds: awardedRewards.map((reward) => reward.id).toList(),
    );

    history.insert(0, entry);
    _addRewardsToInventory(inventory, awardedRewards, result.endedAt);

    await preferences.setStringList(
      _historyKey,
      history.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    await preferences.setStringList(
      _inventoryKey,
      inventory.map((item) => jsonEncode(item.toJson())).toList(),
    );

    return RecordedMealSession(entry: entry, awardedRewards: awardedRewards);
  }

  List<RewardDefinition> _selectRewards(MealSessionResult result) {
    if (!result.completedBeforeArrival) {
      return const [];
    }

    final rewards = <RewardDefinition>[_randomSuccessSticker()];
    if (_completedUnderTargetRatio(result, 0.7)) {
      rewards.add(RewardCatalog.lightningYumSticker);
    }
    return rewards;
  }

  RewardDefinition _randomSuccessSticker() {
    final stickerIndex = _random.nextInt(RewardCatalog.successStickers.length);
    return RewardCatalog.successStickers[stickerIndex];
  }

  bool _completedUnderTargetRatio(MealSessionResult result, double ratio) {
    if (result.targetDuration == Duration.zero) {
      return false;
    }

    return result.actualDuration.inMilliseconds <
        result.targetDuration.inMilliseconds * ratio;
  }

  void _addRewardsToInventory(
    List<RewardInventoryItem> inventory,
    List<RewardDefinition> rewards,
    DateTime acquiredAt,
  ) {
    for (final reward in rewards) {
      final index = inventory.indexWhere((item) => item.rewardId == reward.id);
      if (index == -1) {
        inventory.add(
          RewardInventoryItem(
            rewardId: reward.id,
            acquiredAt: acquiredAt,
            count: 1,
          ),
        );
        continue;
      }

      final item = inventory[index];
      inventory[index] = item.copyWith(count: item.count + 1);
    }
  }

  List<T> _decodeList<T>(
    List<String>? rawItems,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    if (rawItems == null) {
      return <T>[];
    }

    final items = <T>[];
    for (final rawItem in rawItems) {
      final decoded = jsonDecode(rawItem);
      if (decoded is Map) {
        items.add(fromJson(Map<String, Object?>.from(decoded)));
      }
    }
    return items;
  }
}
