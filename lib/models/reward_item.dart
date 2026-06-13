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
  static const riceBowlStickerId = 'sticker_rice_bowl';
  static const yumSpoonStickerId = 'sticker_yum_spoon';
  static const crunchyCarrotStickerId = 'sticker_crunchy_carrot';
  static const sunnyMissionStickerId = 'sticker_sunny_meal';
  static const rainbowCourseStickerId = 'sticker_rainbow_course';
  static const rocketBiteStickerId = 'sticker_rocket_bite';

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

  static const riceBowlSticker = RewardDefinition(
    id: riceBowlStickerId,
    type: RewardType.sticker,
    emoji: '🍚',
  );

  static const yumSpoonSticker = RewardDefinition(
    id: yumSpoonStickerId,
    type: RewardType.sticker,
    emoji: '🥄',
  );

  static const crunchyCarrotSticker = RewardDefinition(
    id: crunchyCarrotStickerId,
    type: RewardType.sticker,
    emoji: '🥕',
  );

  static const sunnyMissionSticker = RewardDefinition(
    id: sunnyMissionStickerId,
    type: RewardType.sticker,
    emoji: '🌞',
  );

  static const rainbowCourseSticker = RewardDefinition(
    id: rainbowCourseStickerId,
    type: RewardType.sticker,
    emoji: '🌈',
  );

  static const rocketBiteSticker = RewardDefinition(
    id: rocketBiteStickerId,
    type: RewardType.sticker,
    emoji: '🚀',
  );

  static const successStickers = [
    finishFlagSticker,
    twinkleStarSticker,
    riceBowlSticker,
    yumSpoonSticker,
    crunchyCarrotSticker,
    sunnyMissionSticker,
    rainbowCourseSticker,
    rocketBiteSticker,
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
