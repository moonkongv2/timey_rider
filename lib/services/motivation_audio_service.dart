import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract interface class MotivationAudioService {
  Future<void> playAsset(String assetPath);

  Future<void> stop();

  Future<void> dispose();
}

class AudioplayersMotivationAudioService implements MotivationAudioService {
  AudioplayersMotivationAudioService()
    : _player = AudioPlayer(),
      _audioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.gain,
        respectSilence: false,
      ).build();

  final AudioPlayer _player;
  final AudioContext _audioContext;

  @override
  Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(
        AssetSource(_assetSourcePath(assetPath)),
        volume: 1,
        ctx: _audioContext,
      );
    } catch (error, stackTrace) {
      debugPrint('Motivation audio playback failed for $assetPath: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> stop() {
    return _player.stop();
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }
}

String _assetSourcePath(String assetPath) {
  const assetPrefix = 'assets/';
  return assetPath.startsWith(assetPrefix)
      ? assetPath.substring(assetPrefix.length)
      : assetPath;
}
