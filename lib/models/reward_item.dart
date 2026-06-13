enum RewardType { sticker }

class RewardDefinition {
  const RewardDefinition({
    required this.id,
    required this.type,
    required this.emoji,
  });

  final String id;
  final RewardType type;
  final String emoji;

  String get imageAssetPath => 'assets/images/$id.png';
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
  static const finishFlagStickerId = 'sticker_finish_flag';
  static const twinkleStarStickerId = 'sticker_twinkle_star';
  static const sparklyTeethStickerId = 'sticker_sparkly_teeth';
  static const bookBuddyStickerId = 'sticker_book_buddy';
  static const cleanupChampStickerId = 'sticker_cleanup_champ';
  static const happyClockStickerId = 'sticker_happy_clock';
  static const rainbowCourseStickerId = 'sticker_rainbow_course';
  static const rocketStickerId = 'sticker_rocket';

  static const finishFlagSticker = RewardDefinition(
    id: finishFlagStickerId,
    type: RewardType.sticker,
    emoji: '🏁',
  );

  static const twinkleStarSticker = RewardDefinition(
    id: twinkleStarStickerId,
    type: RewardType.sticker,
    emoji: '⭐',
  );

  static const sparklyTeethSticker = RewardDefinition(
    id: sparklyTeethStickerId,
    type: RewardType.sticker,
    emoji: '✨',
  );

  static const bookBuddySticker = RewardDefinition(
    id: bookBuddyStickerId,
    type: RewardType.sticker,
    emoji: '📚',
  );

  static const cleanupChampSticker = RewardDefinition(
    id: cleanupChampStickerId,
    type: RewardType.sticker,
    emoji: '🧸',
  );

  static const happyClockSticker = RewardDefinition(
    id: happyClockStickerId,
    type: RewardType.sticker,
    emoji: '⏰',
  );

  static const rainbowCourseSticker = RewardDefinition(
    id: rainbowCourseStickerId,
    type: RewardType.sticker,
    emoji: '🌈',
  );

  static const rocketSticker = RewardDefinition(
    id: rocketStickerId,
    type: RewardType.sticker,
    emoji: '🚀',
  );

  static const successStickers = [
    finishFlagSticker,
    twinkleStarSticker,
    sparklyTeethSticker,
    bookBuddySticker,
    cleanupChampSticker,
    happyClockSticker,
    rainbowCourseSticker,
    rocketSticker,
  ];

  static const all = successStickers;

  static RewardDefinition? findById(String id) {
    for (final reward in all) {
      if (reward.id == id) {
        return reward;
      }
    }
    return null;
  }
}
