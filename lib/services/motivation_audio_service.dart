import 'package:audioplayers/audioplayers.dart';

abstract interface class MotivationAudioService {
  Future<void> playAsset(String assetPath);

  Future<void> stop();

  Future<void> dispose();
}

class AudioplayersMotivationAudioService implements MotivationAudioService {
  AudioplayersMotivationAudioService() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.stop();
    await _player.play(AssetSource(_assetSourcePath(assetPath)));
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
