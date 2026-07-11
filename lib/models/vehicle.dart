class VehicleAvatarSlot {
  const VehicleAvatarSlot({
    required this.centerX,
    required this.centerY,
    required this.sizeRatio,
    this.rotationDegrees = 0.0,
  });

  final double centerX;
  final double centerY;
  final double sizeRatio;
  final double rotationDegrees;
}

class VehicleRoadAnchorOffset {
  const VehicleRoadAnchorOffset({
    this.portraitDxRatio = 0.0,
    this.portraitDyRatio = 0.0,
    this.landscapeDxRatio = 0.0,
    this.landscapeDyRatio = 0.0,
  });

  static const zero = VehicleRoadAnchorOffset();

  final double portraitDxRatio;
  final double portraitDyRatio;
  final double landscapeDxRatio;
  final double landscapeDyRatio;
}

enum VehicleCourseKind { road, sky, water, rail, field }

class VehicleDefinition {
  const VehicleDefinition({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.labelJa,
    required this.labelEs,
    required this.labelPtBr,
    required this.emoji,
    required this.assetPath,
    this.selectionAssetPath,
    this.avatarSlot,
    this.roadAnchorOffset = VehicleRoadAnchorOffset.zero,
    this.courseKind = VehicleCourseKind.road,
  });

  final String id;
  final String labelKo;
  final String labelEn;
  final String labelJa;
  final String labelEs;
  final String labelPtBr;
  final String emoji;
  final String assetPath;
  final String? selectionAssetPath;
  final VehicleAvatarSlot? avatarSlot;
  final VehicleRoadAnchorOffset roadAnchorOffset;
  final VehicleCourseKind courseKind;

  String get selectionImagePath => selectionAssetPath ?? assetPath;

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
