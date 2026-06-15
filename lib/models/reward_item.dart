enum RewardType { sticker }

class RewardDefinition {
  const RewardDefinition({
    required this.id,
    required this.type,
    required this.emoji,
    required this.imageAssetPath,
    required this.labelKo,
    required this.labelEn,
    this.vehicleId,
  });

  final String id;
  final RewardType type;
  final String emoji;
  final String imageAssetPath;
  final String labelKo;
  final String labelEn;
  final String? vehicleId;

  String labelForLanguage(String languageCode) {
    return languageCode == 'ko' ? labelKo : labelEn;
  }
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
    imageAssetPath: 'assets/images/sticker_finish_flag.png',
    labelKo: '도착 깃발 스티커',
    labelEn: 'Finish Flag Sticker',
  );

  static const twinkleStarSticker = RewardDefinition(
    id: twinkleStarStickerId,
    type: RewardType.sticker,
    emoji: '⭐',
    imageAssetPath: 'assets/images/sticker_twinkle_star.png',
    labelKo: '반짝 별 스티커',
    labelEn: 'Twinkle Star Sticker',
  );

  static const sparklyTeethSticker = RewardDefinition(
    id: sparklyTeethStickerId,
    type: RewardType.sticker,
    emoji: '✨',
    imageAssetPath: 'assets/images/sticker_sparkly_teeth.png',
    labelKo: '반짝 양치 스티커',
    labelEn: 'Sparkly Teeth Sticker',
  );

  static const bookBuddySticker = RewardDefinition(
    id: bookBuddyStickerId,
    type: RewardType.sticker,
    emoji: '📚',
    imageAssetPath: 'assets/images/sticker_book_buddy.png',
    labelKo: '책 친구 스티커',
    labelEn: 'Book Buddy Sticker',
  );

  static const cleanupChampSticker = RewardDefinition(
    id: cleanupChampStickerId,
    type: RewardType.sticker,
    emoji: '🧸',
    imageAssetPath: 'assets/images/sticker_cleanup_champ.png',
    labelKo: '정리 챔피언 스티커',
    labelEn: 'Cleanup Champ Sticker',
  );

  static const happyClockSticker = RewardDefinition(
    id: happyClockStickerId,
    type: RewardType.sticker,
    emoji: '⏰',
    imageAssetPath: 'assets/images/sticker_happy_clock.png',
    labelKo: '해피 시계 스티커',
    labelEn: 'Happy Clock Sticker',
  );

  static const rainbowCourseSticker = RewardDefinition(
    id: rainbowCourseStickerId,
    type: RewardType.sticker,
    emoji: '🌈',
    imageAssetPath: 'assets/images/sticker_rainbow_course.png',
    labelKo: '무지개 코스 스티커',
    labelEn: 'Rainbow Ride Sticker',
  );

  static const rocketSticker = RewardDefinition(
    id: rocketStickerId,
    type: RewardType.sticker,
    emoji: '🚀',
    imageAssetPath: 'assets/images/sticker_rocket.png',
    labelKo: '로켓 스티커',
    labelEn: 'Rocket Sticker',
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
