class MealTimerConfig {
  const MealTimerConfig({
    required this.duration,
    required this.showRemainingTime,
    required this.soundEnabled,
    required this.keepScreenAwake,
    required this.courseId,
    required this.motorcycleId,
    required this.childName,
  });

  factory MealTimerConfig.defaults() {
    return const MealTimerConfig(
      duration: Duration(minutes: 25),
      showRemainingTime: true,
      soundEnabled: false,
      keepScreenAwake: false,
      courseId: 'park',
      motorcycleId: 'motorcycle',
      childName: '',
    );
  }

  final Duration duration;
  final bool showRemainingTime;
  final bool soundEnabled;
  final bool keepScreenAwake;
  final String courseId;
  final String motorcycleId;
  final String childName;

  MealTimerConfig copyWith({
    Duration? duration,
    bool? showRemainingTime,
    bool? soundEnabled,
    bool? keepScreenAwake,
    String? courseId,
    String? motorcycleId,
    String? childName,
  }) {
    return MealTimerConfig(
      duration: duration ?? this.duration,
      showRemainingTime: showRemainingTime ?? this.showRemainingTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      courseId: courseId ?? this.courseId,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      childName: childName ?? this.childName,
    );
  }
}
