abstract final class MotivationAssetCatalog {
  static const fallbackVideoPath =
      'assets/videos/motivation/motivation_fallback.mp4';

  static const _videoPathsByVehicleId = {
    'motorcycle': [
      'assets/videos/motivation/motivation_motorcycle_1.mp4',
      'assets/videos/motivation/motivation_motorcycle_2.mp4',
      'assets/videos/motivation/motivation_motorcycle_3.mp4',
    ],
    'fire_truck': ['assets/videos/motivation/motivation_fire_truck_1.mp4'],
    'police_car': [
      'assets/videos/motivation/motivation_police_car_1.mp4',
      'assets/videos/motivation/motivation_police_car_2.mp4',
    ],
    'excavator': [
      'assets/videos/motivation/motivation_excavator_1.mp4',
      'assets/videos/motivation/motivation_excavator_2.mp4',
    ],
    'airplane': ['assets/videos/motivation/motivation_airplane_1.mp4'],
    'bus': ['assets/videos/motivation/motivation_bus_1.mp4'],
    'supercar': ['assets/videos/motivation/motivation_supercar_1.mp4'],
    'train': ['assets/videos/motivation/motivation_train_1.mp4'],
    't_rex': ['assets/videos/motivation/motivation_t_rex_1.mp4'],
    'shark': ['assets/videos/motivation/motivation_shark_1.mp4'],
  };

  static const _voicePathsByLanguageCode = {
    'ko': [
      'assets/audio/motivation/ko_1.mp3',
      'assets/audio/motivation/ko_2.mp3',
    ],
    'en': [
      'assets/audio/motivation/en_1.mp3',
      'assets/audio/motivation/en_2.mp3',
    ],
  };

  static const _voicePathOverridesByVehicleId =
      <String, Map<String, List<String>>>{};

  static Iterable<String> get vehicleVideoIds => _videoPathsByVehicleId.keys;

  static List<String> videoPathsForVehicle(String vehicleId) {
    return _videoPathsByVehicleId[vehicleId] ?? const [fallbackVideoPath];
  }

  static String videoPathForVehicle(
    String vehicleId, {
    int Function(int max)? nextInt,
  }) {
    final paths = videoPathsForVehicle(vehicleId);
    final index = nextInt == null ? 0 : nextInt(paths.length);
    return paths[index.clamp(0, paths.length - 1)];
  }

  static List<String> voicePathsForLanguage(String languageCode) {
    return _voicePathsByLanguageCode[languageCode] ??
        _voicePathsByLanguageCode['en']!;
  }

  static List<String> voicePathsForVehicle({
    required String vehicleId,
    required String languageCode,
  }) {
    return _voicePathOverridesByVehicleId[vehicleId]?[languageCode] ??
        voicePathsForLanguage(languageCode);
  }

  static String voicePathForVehicle({
    required String vehicleId,
    required String languageCode,
    int Function(int max)? nextInt,
  }) {
    final paths = voicePathsForVehicle(
      vehicleId: vehicleId,
      languageCode: languageCode,
    );
    final index = nextInt == null ? 0 : nextInt(paths.length);
    return paths[index.clamp(0, paths.length - 1)];
  }
}
