import 'reward_item.dart';

enum RewardGoalStatus {
  active,
  earned,
  used,
  ready,
  redeemed,
  archived;

  static RewardGoalStatus fromName(String? name) {
    if (name == 'ready') {
      return RewardGoalStatus.earned;
    }
    if (name == 'redeemed') {
      return RewardGoalStatus.used;
    }

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
    required this.activitySessionId,
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
    final activitySessionId =
        json['activitySessionId'] ?? json['mealSessionId'];
    if (rewardId is! String ||
        rewardId.isEmpty ||
        filledAt == null ||
        activitySessionId is! String ||
        activitySessionId.isEmpty) {
      return null;
    }

    return RewardGoalSlot(
      rewardId: rewardId,
      filledAt: filledAt,
      activitySessionId: activitySessionId,
    );
  }

  final String rewardId;
  final DateTime filledAt;
  final String activitySessionId;

  RewardDefinition? get reward => RewardCatalog.findById(rewardId);

  RewardGoalSlot copyWith({
    String? rewardId,
    DateTime? filledAt,
    String? activitySessionId,
  }) {
    return RewardGoalSlot(
      rewardId: rewardId ?? this.rewardId,
      filledAt: filledAt ?? this.filledAt,
      activitySessionId: activitySessionId ?? this.activitySessionId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'rewardId': rewardId,
      'filledAt': filledAt.toIso8601String(),
      'activitySessionId': activitySessionId,
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
    this.earnedAt,
    this.usedAt,
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
      earnedAt:
          _tryParseDateTime(json['earnedAt']) ??
          _tryParseDateTime(json['readyAt']),
      usedAt:
          _tryParseDateTime(json['usedAt']) ??
          _tryParseDateTime(json['redeemedAt']),
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
  final DateTime? earnedAt;
  final DateTime? usedAt;
  final DateTime? readyAt;
  final DateTime? redeemedAt;

  int get filledCount => filledSlots.length;
  int get remainingCount =>
      (requiredStickerCount - filledCount).clamp(0, 20).toInt();
  bool get isReady =>
      status == RewardGoalStatus.earned || status == RewardGoalStatus.ready;
  bool get isUsed =>
      status == RewardGoalStatus.used || status == RewardGoalStatus.redeemed;

  RewardGoal copyWith({
    String? id,
    String? rewardText,
    int? requiredStickerCount,
    List<RewardGoalSlot>? filledSlots,
    DateTime? createdAt,
    RewardGoalStatus? status,
    Object? earnedAt = _unset,
    Object? usedAt = _unset,
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
      earnedAt: earnedAt == _unset ? this.earnedAt : earnedAt as DateTime?,
      usedAt: usedAt == _unset ? this.usedAt : usedAt as DateTime?,
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
      'earnedAt': earnedAt?.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
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
