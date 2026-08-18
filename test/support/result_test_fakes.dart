import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:timey_rider/services/orientation_service.dart';
import 'package:timey_rider/services/result_audio_service.dart';

class TestOrientationService implements OrientationService {
  final List<String> calls = [];

  @override
  Future<void> lockPortrait() async {
    calls.add('lockPortrait');
  }

  @override
  Future<void> allowTimerOrientations() async {
    calls.add('allowTimerOrientations');
  }
}

class TestResultAudioService implements ResultAudioService {
  final List<String> calls = [];

  @override
  Future<void> playCrowdCheering() async {
    calls.add('playCrowdCheering');
  }

  @override
  Future<void> playStickerCollect() async {
    calls.add('playStickerCollect');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }
}

class TestVideoPlayerPlatform extends VideoPlayerPlatform {
  final List<String> calls = [];
  final Map<int, StreamController<VideoEvent>> streams = {};
  int _nextPlayerId = 0;

  @override
  Future<int?> create(DataSource dataSource) async {
    return _create();
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    return _create();
  }

  Future<int> _create() async {
    calls.add('create');
    final playerId = _nextPlayerId;
    _nextPlayerId += 1;
    final stream = StreamController<VideoEvent>();
    streams[playerId] = stream;
    Future<void>.microtask(() {
      stream.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: const Size(100, 100),
          duration: const Duration(seconds: 1),
        ),
      );
    });
    return playerId;
  }

  void complete(int playerId) {
    streams[playerId]?.add(VideoEvent(eventType: VideoEventType.completed));
  }

  @override
  Future<void> init() async {
    calls.add('init');
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return streams[playerId]!.stream;
  }

  @override
  Future<void> play(int playerId) async {
    calls.add('play');
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause');
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    calls.add('setLooping');
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    calls.add('setVolume');
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    calls.add('setPlaybackSpeed');
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    calls.add('seekTo');
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    calls.add('position');
    return Duration.zero;
  }

  @override
  Widget buildView(int playerId) {
    return Texture(textureId: playerId);
  }

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose');
    await streams.remove(playerId)?.close();
  }

  Future<void> close() async {
    final remainingStreams = streams.values.toList();
    streams.clear();
    for (final stream in remainingStreams) {
      await stream.close();
    }
  }
}

TestVideoPlayerPlatform installTestVideoPlayerPlatform() {
  final originalPlatform = VideoPlayerPlatform.instance;
  final platform = TestVideoPlayerPlatform();
  VideoPlayerPlatform.instance = platform;
  addTearDown(() async {
    await platform.close();
    VideoPlayerPlatform.instance = originalPlatform;
  });
  return platform;
}
