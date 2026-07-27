import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../catalogs/timer_audio_asset_catalog.dart';

abstract interface class TimerAudioService {
  Future<void> startOrResumeBgm();

  Future<void> pauseBgm();

  Future<void> stopBgm();

  Future<void> playMarkerSfx();

  Future<void> playCourseLoading();

  Future<void> stopCourseLoading();

  Future<void> playReadyStartBeep();

  Future<void> stopReadyStartBeep();

  Future<void> playFinishDriveShortSfx();

  Future<void> playFinishDriveLongSfx();

  Future<void> stopFinishDriveSfx();

  Future<void> playFinishArrivalSfx();

  Future<void> stopAll();

  Future<void> dispose();
}

class NoopTimerAudioService implements TimerAudioService {
  const NoopTimerAudioService();

  @override
  Future<void> startOrResumeBgm() async {}

  @override
  Future<void> pauseBgm() async {}

  @override
  Future<void> stopBgm() async {}

  @override
  Future<void> playMarkerSfx() async {}

  @override
  Future<void> playCourseLoading() async {}

  @override
  Future<void> stopCourseLoading() async {}

  @override
  Future<void> playReadyStartBeep() async {}

  @override
  Future<void> stopReadyStartBeep() async {}

  @override
  Future<void> playFinishDriveShortSfx() async {}

  @override
  Future<void> playFinishDriveLongSfx() async {}

  @override
  Future<void> stopFinishDriveSfx() async {}

  @override
  Future<void> playFinishArrivalSfx() async {}

  @override
  Future<void> stopAll() async {}

  @override
  Future<void> dispose() async {}
}

class AudioplayersTimerAudioService implements TimerAudioService {
  AudioplayersTimerAudioService()
    : _bgmPlayer = AudioPlayer(),
      _markerPlayer = AudioPlayer(),
      _courseLoadingPlayer = AudioPlayer(),
      _readyStartBeepPlayer = AudioPlayer(),
      _finishDrivePlayer = AudioPlayer(),
      _finishArrivalPlayer = AudioPlayer(),
      _audioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.gain,
        respectSilence: false,
      ).build();

  final AudioPlayer _bgmPlayer;
  final AudioPlayer _markerPlayer;
  final AudioPlayer _courseLoadingPlayer;
  final AudioPlayer _readyStartBeepPlayer;
  final AudioPlayer _finishDrivePlayer;
  final AudioPlayer _finishArrivalPlayer;
  final AudioContext _audioContext;

  bool _bgmSourceLoaded = false;
  bool _bgmPlaying = false;
  bool _disposed = false;
  Future<void> _bgmOperation = Future.value();

  @override
  Future<void> startOrResumeBgm() {
    _bgmOperation = _bgmOperation.then((_) async {
      if (_disposed || _bgmPlaying) {
        return;
      }
      try {
        if (_bgmSourceLoaded) {
          await _bgmPlayer.resume();
        } else {
          await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
          await _bgmPlayer.play(
            AssetSource(_assetSourcePath(TimerAudioAssetCatalog.bgmPath)),
            volume: TimerAudioAssetCatalog.bgmVolume,
            ctx: _audioContext,
            mode: PlayerMode.mediaPlayer,
          );
          _bgmSourceLoaded = true;
        }
        _bgmPlaying = true;
      } catch (error, stackTrace) {
        debugPrint('Timer BGM playback failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
    return _bgmOperation;
  }

  @override
  Future<void> pauseBgm() {
    _bgmOperation = _bgmOperation.then((_) async {
      if (_disposed || !_bgmPlaying) {
        return;
      }
      try {
        await _bgmPlayer.pause();
        _bgmPlaying = false;
      } catch (error, stackTrace) {
        debugPrint('Timer BGM pause failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
    return _bgmOperation;
  }

  @override
  Future<void> stopBgm() {
    _bgmOperation = _bgmOperation.then((_) async {
      if (_disposed || (!_bgmPlaying && !_bgmSourceLoaded)) {
        return;
      }
      try {
        await _bgmPlayer.stop();
        _bgmPlaying = false;
        _bgmSourceLoaded = false;
      } catch (error, stackTrace) {
        debugPrint('Timer BGM stop failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
    return _bgmOperation;
  }

  @override
  Future<void> playMarkerSfx() async {
    if (_disposed) {
      return;
    }
    try {
      await _markerPlayer.stop();
      await _markerPlayer.setReleaseMode(ReleaseMode.stop);
      await _markerPlayer.play(
        AssetSource(_assetSourcePath(TimerAudioAssetCatalog.markerSfxPath)),
        volume: TimerAudioAssetCatalog.markerSfxVolume,
        ctx: _audioContext,
        mode: PlayerMode.lowLatency,
      );
    } catch (error, stackTrace) {
      debugPrint('Timer marker SFX playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> playCourseLoading() async {
    if (_disposed) {
      return;
    }
    try {
      await _courseLoadingPlayer.stop();
      await _courseLoadingPlayer.setReleaseMode(ReleaseMode.stop);
      await _courseLoadingPlayer.play(
        AssetSource(_assetSourcePath(TimerAudioAssetCatalog.courseLoadingPath)),
        volume: TimerAudioAssetCatalog.courseLoadingVolume,
        ctx: _audioContext,
        mode: PlayerMode.mediaPlayer,
      );
    } catch (error, stackTrace) {
      debugPrint('Timer course loading playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> stopCourseLoading() async {
    if (_disposed) {
      return;
    }
    try {
      await _courseLoadingPlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('Timer course loading stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> playReadyStartBeep() async {
    if (_disposed) {
      return;
    }
    try {
      await _readyStartBeepPlayer.stop();
      await _readyStartBeepPlayer.setReleaseMode(ReleaseMode.stop);
      await _readyStartBeepPlayer.play(
        AssetSource(
          _assetSourcePath(TimerAudioAssetCatalog.readyStartBeepPath),
        ),
        volume: TimerAudioAssetCatalog.readyStartBeepVolume,
        ctx: _audioContext,
        mode: PlayerMode.lowLatency,
      );
    } catch (error, stackTrace) {
      debugPrint('Timer ready/start beep playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> stopReadyStartBeep() async {
    if (_disposed) {
      return;
    }
    try {
      await _readyStartBeepPlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('Timer ready/start beep stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> playFinishDriveShortSfx() {
    return _playFinishDriveSfx(
      TimerAudioAssetCatalog.finishDriveShortAssetPath,
      'Timer finish-drive short SFX playback failed',
    );
  }

  @override
  Future<void> playFinishDriveLongSfx() {
    return _playFinishDriveSfx(
      TimerAudioAssetCatalog.finishDriveLongAssetPath,
      'Timer finish-drive long SFX playback failed',
    );
  }

  @override
  Future<void> stopFinishDriveSfx() async {
    if (_disposed) {
      return;
    }
    try {
      await _finishDrivePlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('Timer finish-drive SFX stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> playFinishArrivalSfx() async {
    if (_disposed) {
      return;
    }
    try {
      await _finishArrivalPlayer.stop();
      await _finishArrivalPlayer.setReleaseMode(ReleaseMode.stop);
      await _finishArrivalPlayer.play(
        AssetSource(
          _assetSourcePath(TimerAudioAssetCatalog.finishArrivalAssetPath),
        ),
        volume: TimerAudioAssetCatalog.finishArrivalVolume,
        ctx: _audioContext,
        mode: PlayerMode.lowLatency,
      );
    } catch (error, stackTrace) {
      debugPrint('Timer finish-arrival SFX playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> stopAll() async {
    await Future.wait([
      stopBgm(),
      _stopMarkerSfx(),
      stopCourseLoading(),
      stopReadyStartBeep(),
      stopFinishDriveSfx(),
      _stopFinishArrivalSfx(),
    ]);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await stopAll();
    await Future.wait([
      _disposePlayer(_bgmPlayer, 'Timer BGM player dispose failed'),
      _disposePlayer(_markerPlayer, 'Timer marker player dispose failed'),
      _disposePlayer(
        _courseLoadingPlayer,
        'Timer course loading player dispose failed',
      ),
      _disposePlayer(
        _readyStartBeepPlayer,
        'Timer ready/start beep player dispose failed',
      ),
      _disposePlayer(
        _finishDrivePlayer,
        'Timer finish-drive player dispose failed',
      ),
      _disposePlayer(
        _finishArrivalPlayer,
        'Timer finish-arrival player dispose failed',
      ),
    ]);
    _disposed = true;
  }

  Future<void> _playFinishDriveSfx(String assetPath, String message) async {
    if (_disposed) {
      return;
    }
    try {
      await _finishDrivePlayer.stop();
      await _finishDrivePlayer.setReleaseMode(ReleaseMode.stop);
      await _finishDrivePlayer.play(
        AssetSource(_assetSourcePath(assetPath)),
        volume: TimerAudioAssetCatalog.finishDriveVolume,
        ctx: _audioContext,
        mode: PlayerMode.lowLatency,
      );
    } catch (error, stackTrace) {
      debugPrint('$message: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _stopMarkerSfx() async {
    if (_disposed) {
      return;
    }
    try {
      await _markerPlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('Timer marker SFX stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _stopFinishArrivalSfx() async {
    if (_disposed) {
      return;
    }
    try {
      await _finishArrivalPlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('Timer finish-arrival SFX stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _disposePlayer(AudioPlayer player, String message) async {
    try {
      await player.dispose();
    } catch (error, stackTrace) {
      debugPrint('$message: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

String _assetSourcePath(String assetPath) {
  const assetPrefix = 'assets/';
  return assetPath.startsWith(assetPrefix)
      ? assetPath.substring(assetPrefix.length)
      : assetPath;
}
