class MealTimerConfig {
  const MealTimerConfig({
    required this.duration,
    required this.showRemainingTime,
    required this.soundEnabled,
    required this.keepScreenAwake,
    required this.courseId,
    required this.motorcycleId,
  });

  factory MealTimerConfig.defaults() {
    return const MealTimerConfig(
      duration: Duration(minutes: 25),
      showRemainingTime: true,
      soundEnabled: false,
      keepScreenAwake: false,
      courseId: 'park',
      motorcycleId: 'motorcycle',
    );
  }

  final Duration duration;
  final bool showRemainingTime;
  final bool soundEnabled;
  final bool keepScreenAwake;
  final String courseId;
  final String motorcycleId;

  MealTimerConfig copyWith({
    Duration? duration,
    bool? showRemainingTime,
    bool? soundEnabled,
    bool? keepScreenAwake,
    String? courseId,
    String? motorcycleId,
  }) {
    return MealTimerConfig(
      duration: duration ?? this.duration,
      showRemainingTime: showRemainingTime ?? this.showRemainingTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      courseId: courseId ?? this.courseId,
      motorcycleId: motorcycleId ?? this.motorcycleId,
    );
  }
}
