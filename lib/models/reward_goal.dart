import 'reward_item.dart';

enum RewardGoalStatus {
  active,
  ready,
  redeemed,
  archived;

  static RewardGoalStatus fromName(String? name) {
    for (final status in RewardGoalStatus.values) {
      if (status.name == name) {
        return status;
      }
    }
    return RewardGoalStatus.active;
  }
}

class RewardGoalSlot {
  const RewardGoalSlot({
    required this.rewardId,
    required this.filledAt,
    required this.mealSessionId,
  });

  factory RewardGoalSlot.fromJson(Map<String, Object?> json) {
    final slot = tryFromJson(json);
    if (slot == null) {
      throw const FormatException('Invalid reward goal slot');
    }
    return slot;
  }

  static RewardGoalSlot? tryFromJson(Map<String, Object?> json) {
    final rewardId = json['rewardId'];
    final filledAt = _tryParseDateTime(json['filledAt']);
    final mealSessionId = json['mealSessionId'];
    if (rewardId is! String ||
        rewardId.isEmpty ||
        filledAt == null ||
        mealSessionId is! String ||
        mealSessionId.isEmpty) {
      return null;
    }

    return RewardGoalSlot(
      rewardId: rewardId,
      filledAt: filledAt,
      mealSessionId: mealSessionId,
    );
  }

  final String rewardId;
  final DateTime filledAt;
  final String mealSessionId;

  RewardDefinition? get reward => RewardCatalog.findById(rewardId);

  RewardGoalSlot copyWith({
    String? rewardId,
    DateTime? filledAt,
    String? mealSessionId,
  }) {
    return RewardGoalSlot(
      rewardId: rewardId ?? this.rewardId,
      filledAt: filledAt ?? this.filledAt,
      mealSessionId: mealSessionId ?? this.mealSessionId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'rewardId': rewardId,
      'filledAt': filledAt.toIso8601String(),
      'mealSessionId': mealSessionId,
    };
  }
}

class RewardGoal {
  const RewardGoal({
    required this.id,
    required this.rewardText,
    required this.requiredStickerCount,
    required this.filledSlots,
    required this.createdAt,
    required this.status,
    this.readyAt,
    this.redeemedAt,
  });

  factory RewardGoal.fromJson(Map<String, Object?> json) {
    final goal = tryFromJson(json);
    if (goal == null) {
      throw const FormatException('Invalid reward goal');
    }
    return goal;
  }

  static RewardGoal? tryFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final rewardText = json['rewardText'];
    final requiredStickerCount = json['requiredStickerCount'];
    final createdAt = _tryParseDateTime(json['createdAt']);
    final rawSlots = json['filledSlots'];
    if (id is! String ||
        id.isEmpty ||
        rewardText is! String ||
        rewardText.trim().isEmpty ||
        requiredStickerCount is! int ||
        requiredStickerCount <= 0 ||
        createdAt == null) {
      return null;
    }

    final filledSlots = <RewardGoalSlot>[];
    if (rawSlots is List) {
      for (final rawSlot in rawSlots) {
        if (rawSlot is Map) {
          final slot = RewardGoalSlot.tryFromJson(
            Map<String, Object?>.from(rawSlot),
          );
          if (slot != null) {
            filledSlots.add(slot);
          }
        }
      }
    }

    final clampedRequiredStickerCount = requiredStickerCount
        .clamp(1, 20)
        .toInt();

    return RewardGoal(
      id: id,
      rewardText: rewardText.trim(),
      requiredStickerCount: clampedRequiredStickerCount,
      filledSlots: filledSlots.take(clampedRequiredStickerCount).toList(),
      createdAt: createdAt,
      status: RewardGoalStatus.fromName(json['status'] as String?),
      readyAt: _tryParseDateTime(json['readyAt']),
      redeemedAt: _tryParseDateTime(json['redeemedAt']),
    );
  }

  static const _unset = Object();

  final String id;
  final String rewardText;
  final int requiredStickerCount;
  final List<RewardGoalSlot> filledSlots;
  final DateTime createdAt;
  final RewardGoalStatus status;
  final DateTime? readyAt;
  final DateTime? redeemedAt;

  int get filledCount => filledSlots.length;
  int get remainingCount =>
      (requiredStickerCount - filledCount).clamp(0, 20).toInt();
  bool get isReady => status == RewardGoalStatus.ready;

  RewardGoal copyWith({
    String? id,
    String? rewardText,
    int? requiredStickerCount,
    List<RewardGoalSlot>? filledSlots,
    DateTime? createdAt,
    RewardGoalStatus? status,
    Object? readyAt = _unset,
    Object? redeemedAt = _unset,
  }) {
    return RewardGoal(
      id: id ?? this.id,
      rewardText: rewardText ?? this.rewardText,
      requiredStickerCount: requiredStickerCount ?? this.requiredStickerCount,
      filledSlots: filledSlots ?? this.filledSlots,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      readyAt: readyAt == _unset ? this.readyAt : readyAt as DateTime?,
      redeemedAt: redeemedAt == _unset
          ? this.redeemedAt
          : redeemedAt as DateTime?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'rewardText': rewardText,
      'requiredStickerCount': requiredStickerCount,
      'filledSlots': filledSlots.map((slot) => slot.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'readyAt': readyAt?.toIso8601String(),
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }
}

DateTime? _tryParseDateTime(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value);
}
