import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/active_activity_timer_session.dart';
import '../models/activity_completion_status.dart';
import '../models/activity_session_result.dart';
import '../models/activity_timer_config.dart';

enum ActivityTimerState { idle, running, paused, arrived, completed }

class ActivityTimerController extends ChangeNotifier {
  static const _tickerInterval = Duration(milliseconds: 16);

  ActivityTimerController({required this.config, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  ActivityTimerController.fromSession({
    required ActiveActivityTimerSession session,
    DateTime Function()? now,
  }) : config = session.config,
       _now = now ?? DateTime.now {
    _restoreFromSession(session);
  }

  final ActivityTimerConfig config;
  final DateTime Function() _now;

  Timer? _ticker;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _totalPausedDuration = Duration.zero;
  Duration _elapsed = Duration.zero;
  ActivityTimerState _state = ActivityTimerState.idle;

  ActivityTimerState get state => _state;
  DateTime? get startedAt => _startedAt;
  DateTime? get pausedAt => _pausedAt;
  Duration get elapsed => _elapsed;
  Duration get totalPausedDuration => _totalPausedDuration;

  Duration get remaining {
    final value = config.duration - _elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  double get progress {
    if (config.duration == Duration.zero) {
      return 1;
    }
    final ratio = _elapsed.inMilliseconds / config.duration.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }

  bool get isPaused => _state == ActivityTimerState.paused;
  bool get hasArrived => progress >= 1;

  void start() {
    _startedAt = _now();
    _pausedAt = null;
    _totalPausedDuration = Duration.zero;
    _elapsed = Duration.zero;
    _state = ActivityTimerState.running;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_state != ActivityTimerState.running &&
        _state != ActivityTimerState.arrived) {
      return;
    }
    _updateElapsed();
    _pausedAt = _now();
    _state = ActivityTimerState.paused;
    notifyListeners();
  }

  void resume() {
    if (_state != ActivityTimerState.paused || _pausedAt == null) {
      return;
    }
    _totalPausedDuration += _now().difference(_pausedAt!);
    _pausedAt = null;
    _state = hasArrived
        ? ActivityTimerState.arrived
        : ActivityTimerState.running;
    _startTicker();
    notifyListeners();
  }

  void refreshFromClock() {
    if (_state != ActivityTimerState.running &&
        _state != ActivityTimerState.arrived) {
      return;
    }

    _updateElapsed();
    notifyListeners();
  }

  ActivitySessionResult complete({
    ActivityCompletionStatus? completionStatus,
    DateTime? endedAt,
    Duration? actualDuration,
  }) {
    _updateElapsed();
    _state = ActivityTimerState.completed;
    _ticker?.cancel();

    final resolvedEndedAt = endedAt ?? _now();
    final resolvedActualDuration = actualDuration ?? _elapsed;
    final completedBeforeEnd = resolvedActualDuration < config.duration;
    final resolvedCompletionStatus =
        completionStatus ??
        (completedBeforeEnd
            ? ActivityCompletionStatus.completedBeforeEnd
            : ActivityCompletionStatus.completedAfterEnd);
    return ActivitySessionResult(
      activityId: config.activityId,
      startedAt: _startedAt ?? resolvedEndedAt,
      endedAt: resolvedEndedAt,
      targetDuration: config.duration,
      actualDuration: resolvedActualDuration,
      completedBeforeEnd: completedBeforeEnd,
      completionStatus: resolvedCompletionStatus,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickerInterval, (_) {
      if (_state == ActivityTimerState.running ||
          _state == ActivityTimerState.arrived) {
        _updateElapsed();
        notifyListeners();
      }
    });
  }

  void _updateElapsed() {
    final startedAt = _startedAt;
    if (startedAt == null) {
      return;
    }

    final referenceTime = _pausedAt ?? _now();
    // Elapsed time is derived from wall-clock time so small ticker delays do not
    // make the motorcycle drift away from the real timer duration.
    _elapsed = _elapsedBetween(
      startedAt: startedAt,
      referenceTime: referenceTime,
      totalPausedDuration: _totalPausedDuration,
    );

    if (_elapsed >= config.duration && _state == ActivityTimerState.running) {
      _state = ActivityTimerState.arrived;
      _ticker?.cancel();
    }
  }

  void _restoreFromSession(ActiveActivityTimerSession session) {
    _ticker?.cancel();
    _startedAt = session.startedAt;
    _totalPausedDuration = _nonNegativeDuration(session.totalPausedDuration);
    _pausedAt = session.state == ActiveActivityTimerSessionState.paused
        ? session.pausedAt ?? _now()
        : null;

    final referenceTime = _pausedAt ?? _now();
    _elapsed = _elapsedBetween(
      startedAt: session.startedAt,
      referenceTime: referenceTime,
      totalPausedDuration: _totalPausedDuration,
    );

    _state = switch (session.state) {
      ActiveActivityTimerSessionState.paused => ActivityTimerState.paused,
      ActiveActivityTimerSessionState.arrived => ActivityTimerState.arrived,
      ActiveActivityTimerSessionState.running =>
        _elapsed >= config.duration
            ? ActivityTimerState.arrived
            : ActivityTimerState.running,
    };

    if (_state == ActivityTimerState.arrived && _elapsed < config.duration) {
      _elapsed = config.duration;
    }

    if (_state == ActivityTimerState.running) {
      _startTicker();
    }
  }

  Duration _elapsedBetween({
    required DateTime startedAt,
    required DateTime referenceTime,
    required Duration totalPausedDuration,
  }) {
    final elapsed =
        referenceTime.difference(startedAt) -
        _nonNegativeDuration(totalPausedDuration);
    return _nonNegativeDuration(elapsed);
  }

  Duration _nonNegativeDuration(Duration duration) {
    return duration.isNegative ? Duration.zero : duration;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
