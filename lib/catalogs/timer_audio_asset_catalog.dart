abstract final class TimerAudioAssetCatalog {
  static const bgmPath = 'assets/audio/timer_bgm/timer_bgm_short.mp3';
  static const markerSfxPath = 'assets/audio/marker/marker_01.mp3';
  static const courseLoadingPath = 'assets/audio/course_loading.mp3';
  static const readyStartBeepPath = 'assets/audio/ready_start_beep_02.mp3';
  static const finishDriveShortAssetPath = 'assets/audio/final_drive_short.mp3';
  static const finishDriveLongAssetPath = 'assets/audio/final_drive_long.mp3';
  static const finishArrivalAssetPath = 'assets/audio/finish_arrival.mp3';

  static const bgmVolume = 0.22;
  static const markerSfxVolume = 0.080;
  static const courseLoadingVolume = 0.20;
  static const readyStartBeepVolume = 0.12;
  static const finishDriveVolume = 0.16;
  static const finishArrivalVolume = 0.24;

  static const runtimeAssetPaths = [
    bgmPath,
    markerSfxPath,
    courseLoadingPath,
    readyStartBeepPath,
    finishDriveShortAssetPath,
    finishDriveLongAssetPath,
    finishArrivalAssetPath,
  ];
}
