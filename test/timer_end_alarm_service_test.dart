import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/services/timer_audio_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('xyz.luan/audioplayers');
  final calls = <MethodCall>[];
  final playerIds = <String>[];
  Completer<void>? releaseModeBlocked;
  Completer<void>? releaseModeEntered;
  bool failPlayback = false;
  late AudioplayersTimerAudioService service;

  setUp(() {
    calls.clear();
    playerIds.clear();
    releaseModeBlocked = null;
    releaseModeEntered = null;
    failPlayback = false;
    AudioCache.instance.loadedFiles['audio/timer_end.mp3'] = File(
      'assets/audio/timer_end.mp3',
    ).absolute.uri;
    AudioCache.instance.loadedFiles['audio/timer_bgm/timer_bgm_short.mp3'] =
        File('assets/audio/timer_bgm/timer_bgm_short.mp3').absolute.uri;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      final args = call.arguments as Map;
      final id = args['playerId'] as String;
      if (call.method == 'create') {
        playerIds.add(id);
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers/events/$id'),
          (_) async => null,
        );
      }
      if (call.method == 'setReleaseMode' && releaseModeBlocked != null) {
        releaseModeEntered!.complete();
        await releaseModeBlocked!.future;
      }
      if (call.method == 'setPlayerMode' && failPlayback) {
        throw PlatformException(code: 'test-playback-failure');
      }
      if (call.method == 'setSourceUrl') {
        binding.channelBuffers.push(
          'xyz.luan/audioplayers/events/$id',
          const StandardMethodCodec().encodeSuccessEnvelope({
            'event': 'audio.onPrepared',
            'value': true,
          }),
          (_) {},
        );
      }
      return null;
    });
    service = AudioplayersTimerAudioService();
  });

  tearDown(() async {
    await service.dispose();
    for (final id in playerIds) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel('xyz.luan/audioplayers/events/$id'),
        null,
      );
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    AudioCache.instance.loadedFiles.clear();
  });

  test('Alarm uses loop/mediaPlayer once and stops before disposal', () async {
    await service.startTimerEndAlarm();
    await service.startTimerEndAlarm();
    expect(calls.where((c) => c.method == 'resume'), hasLength(1));
    expect(
      calls.singleWhere((c) => c.method == 'setReleaseMode').arguments,
      containsPair('releaseMode', 'ReleaseMode.loop'),
    );
    expect(
      calls.singleWhere((c) => c.method == 'setPlayerMode').arguments,
      containsPair('playerMode', 'PlayerMode.mediaPlayer'),
    );
    final alarmId =
        (calls.singleWhere((c) => c.method == 'resume').arguments
            as Map)['playerId'];
    await service.stopAll();
    expect(
      calls
          .where((c) => c.method == 'stop')
          .map((c) => (c.arguments as Map)['playerId']),
      contains(alarmId),
    );
    await service.dispose();
    expect(
      calls
          .where((c) => c.method == 'dispose')
          .map((c) => (c.arguments as Map)['playerId']),
      contains(alarmId),
    );
    final count = calls.length;
    await service.startTimerEndAlarm();
    expect(calls, hasLength(count));
  });

  for (final dispose in [false, true]) {
    test(
      'Pending start is cancelled by ${dispose ? 'dispose' : 'stop'}',
      () async {
        releaseModeBlocked = Completer<void>();
        releaseModeEntered = Completer<void>();
        final starting = service.startTimerEndAlarm();
        await releaseModeEntered!.future;
        final stopping = dispose
            ? service.dispose()
            : service.stopTimerEndAlarm();
        releaseModeBlocked!.complete();
        await Future.wait([starting, stopping]);
        expect(calls.where((c) => c.method == 'resume'), isEmpty);
      },
    );
  }

  test(
    'Rapid start-stop-start finishes playing, final stop finishes stopped',
    () async {
      final start = service.startTimerEndAlarm();
      final stop = service.stopTimerEndAlarm();
      final restart = service.startTimerEndAlarm();
      await Future.wait([start, stop, restart]);
      final playback = calls
          .where((c) => ['resume', 'stop'].contains(c.method))
          .toList();
      expect(playback.last.method, 'resume');
      await service.stopTimerEndAlarm();
      expect(
        calls.where((c) => ['resume', 'stop'].contains(c.method)).last.method,
        'stop',
      );
    },
  );

  test('BGM stops before alarm playback starts', () async {
    await service.startOrResumeBgm();
    final bgmId =
        (calls.singleWhere((c) => c.method == 'resume').arguments
            as Map)['playerId'];
    calls.clear();
    await service.startTimerEndAlarm();
    final stopped = calls.indexWhere(
      (c) => c.method == 'stop' && (c.arguments as Map)['playerId'] == bgmId,
    );
    final resumed = calls.indexWhere((c) => c.method == 'resume');
    expect(stopped, greaterThanOrEqualTo(0));
    expect(resumed, greaterThan(stopped));
  });

  test('Playback failure does not break stop or later restart', () async {
    failPlayback = true;
    await service.startTimerEndAlarm();
    await service.stopTimerEndAlarm();
    failPlayback = false;
    await service.startTimerEndAlarm();
    expect(calls.where((c) => c.method == 'resume'), hasLength(1));
    await service.stopAll();
  });
}
