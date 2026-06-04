import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/meal_completion_status.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';

enum MealTimerState { idle, running, paused, arrived, completed }

class MealTimerController extends ChangeNotifier {
  MealTimerController({required this.config, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MealTimerConfig config;
  final DateTime Function() _now;

  Timer? _ticker;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _totalPausedDuration = Duration.zero;
  Duration _elapsed = Duration.zero;
  MealTimerState _state = MealTimerState.idle;

  MealTimerState get state => _state;
  DateTime? get startedAt => _startedAt;
  Duration get elapsed => _elapsed;

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
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
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
    final elapsed = referenceTime.difference(startedAt) - _totalPausedDuration;
    _elapsed = elapsed.isNegative ? Duration.zero : elapsed;

    if (_elapsed >= config.duration && _state == MealTimerState.running) {
      _state = MealTimerState.arrived;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
