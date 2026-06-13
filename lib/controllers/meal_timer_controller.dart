import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/active_meal_timer_session.dart';
import '../models/meal_completion_status.dart';
import '../models/meal_session_result.dart';
import '../models/activity_timer_config.dart';

enum MealTimerState { idle, running, paused, arrived, completed }

class MealTimerController extends ChangeNotifier {
  static const _tickerInterval = Duration(milliseconds: 16);

  MealTimerController({required this.config, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  MealTimerController.fromSession({
    required ActiveMealTimerSession session,
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
  MealTimerState _state = MealTimerState.idle;

  MealTimerState get state => _state;
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

  bool get isPaused => _state == MealTimerState.paused;
  bool get hasArrived => progress >= 1;

  void start() {
    _startedAt = _now();
    _pausedAt = null;
    _totalPausedDuration = Duration.zero;
    _elapsed = Duration.zero;
    _state = MealTimerState.running;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_state != MealTimerState.running && _state != MealTimerState.arrived) {
      return;
    }
    _updateElapsed();
    _pausedAt = _now();
    _state = MealTimerState.paused;
    notifyListeners();
  }

  void resume() {
    if (_state != MealTimerState.paused || _pausedAt == null) {
      return;
    }
    _totalPausedDuration += _now().difference(_pausedAt!);
    _pausedAt = null;
    _state = hasArrived ? MealTimerState.arrived : MealTimerState.running;
    _startTicker();
    notifyListeners();
  }

  void refreshFromClock() {
    if (_state != MealTimerState.running && _state != MealTimerState.arrived) {
      return;
    }

    _updateElapsed();
    notifyListeners();
  }

  MealSessionResult complete({
    bool mealCompleted = true,
    MealCompletionStatus? completionStatus,
  }) {
    _updateElapsed();
    _state = MealTimerState.completed;
    _ticker?.cancel();

    final endedAt = _now();
    final completedBeforeArrival = progress < 1;
    return MealSessionResult(
      startedAt: _startedAt ?? endedAt,
      endedAt: endedAt,
      targetDuration: config.duration,
      actualDuration: _elapsed,
      completedBeforeArrival: completedBeforeArrival,
      mealCompleted: mealCompleted,
      completionStatus: completionStatus,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickerInterval, (_) {
      if (_state == MealTimerState.running ||
          _state == MealTimerState.arrived) {
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
    // make the motorcycle drift away from the real meal duration.
    _elapsed = _elapsedBetween(
      startedAt: startedAt,
      referenceTime: referenceTime,
      totalPausedDuration: _totalPausedDuration,
    );

    if (_elapsed >= config.duration && _state == MealTimerState.running) {
      _state = MealTimerState.arrived;
    }
  }

  void _restoreFromSession(ActiveMealTimerSession session) {
    _ticker?.cancel();
    _startedAt = session.startedAt;
    _totalPausedDuration = _nonNegativeDuration(session.totalPausedDuration);
    _pausedAt = session.state == ActiveMealTimerSessionState.paused
        ? session.pausedAt ?? _now()
        : null;

    final referenceTime = _pausedAt ?? _now();
    _elapsed = _elapsedBetween(
      startedAt: session.startedAt,
      referenceTime: referenceTime,
      totalPausedDuration: _totalPausedDuration,
    );

    _state = switch (session.state) {
      ActiveMealTimerSessionState.paused => MealTimerState.paused,
      ActiveMealTimerSessionState.arrived => MealTimerState.arrived,
      ActiveMealTimerSessionState.running =>
        _elapsed >= config.duration
            ? MealTimerState.arrived
            : MealTimerState.running,
    };

    if (_state == MealTimerState.arrived && _elapsed < config.duration) {
      _elapsed = config.duration;
    }

    if (_state == MealTimerState.running || _state == MealTimerState.arrived) {
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
