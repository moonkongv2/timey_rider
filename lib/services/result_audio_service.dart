import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../catalogs/result_audio_asset_catalog.dart';

abstract interface class ResultAudioService {
  Future<void> playCrowdCheering();

  Future<void> playStickerCollect();

  Future<void> stop();

  Future<void> dispose();
}

class NoopResultAudioService implements ResultAudioService {
  const NoopResultAudioService();

  @override
  Future<void> playCrowdCheering() async {}

  @override
  Future<void> playStickerCollect() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class AudioplayersResultAudioService implements ResultAudioService {
  AudioplayersResultAudioService()
    : _crowdCheeringPlayer = AudioPlayer(),
      _stickerCollectPlayer = AudioPlayer(),
      _audioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.gain,
        respectSilence: false,
      ).build();

  final AudioPlayer _crowdCheeringPlayer;
  final AudioPlayer _stickerCollectPlayer;
  final AudioContext _audioContext;

  bool _disposed = false;

  @override
  Future<void> playCrowdCheering() async {
    if (_disposed) {
      return;
    }
    try {
      await _crowdCheeringPlayer.stop();
      await _crowdCheeringPlayer.setReleaseMode(ReleaseMode.stop);
      await _crowdCheeringPlayer.play(
        AssetSource(
          _assetSourcePath(ResultAudioAssetCatalog.crowdCheeringAssetPath),
        ),
        volume: ResultAudioAssetCatalog.crowdCheeringVolume,
        ctx: _audioContext,
        mode: PlayerMode.lowLatency,
      );
    } catch (error, stackTrace) {
      debugPrint('Result crowd cheering playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> playStickerCollect() async {
    if (_disposed) {
      return;
    }
    try {
      await _stickerCollectPlayer.stop();
      await _stickerCollectPlayer.setReleaseMode(ReleaseMode.stop);
      await _stickerCollectPlayer.play(
        AssetSource(
          _assetSourcePath(ResultAudioAssetCatalog.stickerCollectAssetPath),
        ),
        volume: ResultAudioAssetCatalog.stickerCollectVolume,
        ctx: _audioContext,
        mode: PlayerMode.lowLatency,
      );
    } catch (error, stackTrace) {
      debugPrint('Result sticker collect playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    await Future.wait([
      _stopPlayer(_crowdCheeringPlayer, 'Result crowd cheering stop failed'),
      _stopPlayer(_stickerCollectPlayer, 'Result sticker collect stop failed'),
    ]);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await stop();
    await Future.wait([
      _disposePlayer(
        _crowdCheeringPlayer,
        'Result crowd cheering player dispose failed',
      ),
      _disposePlayer(
        _stickerCollectPlayer,
        'Result sticker collect player dispose failed',
      ),
    ]);
    _disposed = true;
  }

  Future<void> _stopPlayer(AudioPlayer player, String message) async {
    try {
      await player.stop();
    } catch (error, stackTrace) {
      debugPrint('$message: $error');
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
