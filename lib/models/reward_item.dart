import '../catalogs/vehicle_catalog.dart';

enum RewardType { sticker }

class RewardDefinition {
  const RewardDefinition({
    required this.id,
    required this.type,
    required this.emoji,
    required this.imageAssetPath,
    required this.labelKo,
    required this.labelEn,
    required this.labelJa,
    required this.labelEs,
    required this.labelPtBr,
    this.vehicleId,
  });

  final String id;
  final RewardType type;
  final String emoji;
  final String imageAssetPath;
  final String labelKo;
  final String labelEn;
  final String labelJa;
  final String labelEs;
  final String labelPtBr;
  final String? vehicleId;

  String labelForLanguage(String languageCode) {
    return switch (languageCode) {
      'ko' => labelKo,
      'ja' => labelJa,
      'es' => labelEs,
      'pt' => labelPtBr,
      _ => labelEn,
    };
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
  static final List<RewardDefinition> all = List.unmodifiable(
    VehicleCatalog.all.map(
      (vehicle) => RewardDefinition(
        id: vehicleStickerIdForVehicle(vehicle.id),
        type: RewardType.sticker,
        emoji: vehicle.emoji,
        imageAssetPath: vehicle.assetPath,
        labelKo: '${vehicle.labelKo} 스티커',
        labelEn: '${vehicle.labelEn} Sticker',
        labelJa: '${vehicle.labelJa}ステッカー',
        labelEs: 'Pegatina de ${vehicle.labelEs}',
        labelPtBr: 'Adesivo de ${vehicle.labelPtBr}',
        vehicleId: vehicle.id,
      ),
    ),
  );

  static final List<RewardDefinition> successStickers = all;

  static String vehicleStickerIdForVehicle(String vehicleId) {
    return 'sticker_vehicle_$vehicleId';
  }

  static RewardDefinition? findVehicleStickerByVehicleId(String vehicleId) {
    for (final reward in all) {
      if (reward.vehicleId == vehicleId) {
        return reward;
      }
    }
    return null;
  }

  static RewardDefinition? findById(String id) {
    for (final reward in all) {
      if (reward.id == id) {
        return reward;
      }
    }
    return null;
  }
}
