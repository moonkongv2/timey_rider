import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../catalogs/timer_audio_asset_catalog.dart';

abstract interface class TimerAudioService {
  Future<void> startOrResumeBgm();

  Future<void> pauseBgm();

  Future<void> stopBgm();

  Future<void> playMarkerSfx();

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
  Future<void> stopAll() async {}

  @override
  Future<void> dispose() async {}
}

class AudioplayersTimerAudioService implements TimerAudioService {
  AudioplayersTimerAudioService()
    : _bgmPlayer = AudioPlayer(),
      _markerPlayer = AudioPlayer(),
      _audioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.gain,
        respectSilence: false,
      ).build();

  final AudioPlayer _bgmPlayer;
  final AudioPlayer _markerPlayer;
  final AudioContext _audioContext;

  bool _bgmSourceLoaded = false;
  bool _bgmPlaying = false;
  Future<void> _bgmOperation = Future.value();

  @override
  Future<void> startOrResumeBgm() {
    _bgmOperation = _bgmOperation.then((_) async {
      if (_bgmPlaying) {
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
      if (!_bgmPlaying) {
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
      if (!_bgmPlaying && !_bgmSourceLoaded) {
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
  Future<void> stopAll() async {
    await Future.wait([stopBgm(), _stopMarkerSfx()]);
  }

  @override
  Future<void> dispose() async {
    await stopAll();
    await Future.wait([
      _disposePlayer(_bgmPlayer, 'Timer BGM player dispose failed'),
      _disposePlayer(_markerPlayer, 'Timer marker player dispose failed'),
    ]);
  }

  Future<void> _stopMarkerSfx() async {
    try {
      await _markerPlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('Timer marker SFX stop failed: $error');
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
