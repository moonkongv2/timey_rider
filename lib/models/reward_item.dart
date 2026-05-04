enum RewardType { sticker }

class RewardDefinition {
  const RewardDefinition({
    required this.id,
    required this.type,
    required this.name,
    required this.emoji,
  });

  final String id;
  final RewardType type;
  final String name;
  final String emoji;

  String get displayLabel => '$emoji $name';
}

class RewardInventoryItem {
  const RewardInventoryItem({
    required this.rewardId,
    required this.acquiredAt,
    required this.count,
  });

  factory RewardInventoryItem.fromJson(Map<String, Object?> json) {
    return RewardInventoryItem(
      rewardId: json['rewardId'] as String,
      acquiredAt: DateTime.parse(json['acquiredAt'] as String),
      count: json['count'] as int,
    );
  }

  final String rewardId;
  final DateTime acquiredAt;
  final int count;

  RewardInventoryItem copyWith({DateTime? acquiredAt, int? count}) {
    return RewardInventoryItem(
      rewardId: rewardId,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      count: count ?? this.count,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'rewardId': rewardId,
      'acquiredAt': acquiredAt.toIso8601String(),
      'count': count,
    };
  }
}

class RewardCatalog {
  static const finishFlagSticker = RewardDefinition(
    id: 'sticker_finish_flag',
    type: RewardType.sticker,
    name: '도착 깃발 스티커',
    emoji: '🏁',
  );

  static const twinkleStarSticker = RewardDefinition(
    id: 'sticker_twinkle_star',
    type: RewardType.sticker,
    name: '반짝 별 스티커',
    emoji: '⭐',
  );

  static const riderHelmetSticker = RewardDefinition(
    id: 'sticker_rider_helmet',
    type: RewardType.sticker,
    name: '멋진 헬멧 스티커',
    emoji: '🪖',
  );

  static const riceBowlSticker = RewardDefinition(
    id: 'sticker_rice_bowl',
    type: RewardType.sticker,
    name: '든든 밥그릇 스티커',
    emoji: '🍚',
  );

  static const yumSpoonSticker = RewardDefinition(
    id: 'sticker_yum_spoon',
    type: RewardType.sticker,
    name: '냠냠 숟가락 스티커',
    emoji: '🥄',
  );

  static const crunchyCarrotSticker = RewardDefinition(
    id: 'sticker_crunchy_carrot',
    type: RewardType.sticker,
    name: '아삭 당근 스티커',
    emoji: '🥕',
  );

  static const sunnyMealSticker = RewardDefinition(
    id: 'sticker_sunny_meal',
    type: RewardType.sticker,
    name: '햇살 식사 스티커',
    emoji: '🌞',
  );

  static const rainbowCourseSticker = RewardDefinition(
    id: 'sticker_rainbow_course',
    type: RewardType.sticker,
    name: '무지개 코스 스티커',
    emoji: '🌈',
  );

  static const rocketBiteSticker = RewardDefinition(
    id: 'sticker_rocket_bite',
    type: RewardType.sticker,
    name: '로켓 한입 스티커',
    emoji: '🚀',
  );

  static const happyRiderSticker = RewardDefinition(
    id: 'sticker_happy_rider',
    type: RewardType.sticker,
    name: '신나는 라이더 스티커',
    emoji: '🏍️',
  );

  static const lightningYumSticker = RewardDefinition(
    id: 'sticker_lightning_yum',
    type: RewardType.sticker,
    name: '번개 냠냠 스티커',
    emoji: '⚡',
  );

  static const successStickers = [
    finishFlagSticker,
    twinkleStarSticker,
    riderHelmetSticker,
    riceBowlSticker,
    yumSpoonSticker,
    crunchyCarrotSticker,
    sunnyMealSticker,
    rainbowCourseSticker,
    rocketBiteSticker,
    happyRiderSticker,
  ];

  static const all = [...successStickers, lightningYumSticker];

  static RewardDefinition? findById(String id) {
    for (final reward in all) {
      if (reward.id == id) {
        return reward;
      }
    }
    return null;
  }
}
