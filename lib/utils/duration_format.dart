String formatDuration(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

Duration capDuration(Duration duration, Duration max) {
  if (duration.isNegative) {
    return Duration.zero;
  }
  return duration > max ? max : duration;
}

Duration overrunDuration(Duration duration, Duration target) {
  final value = duration - target;
  return value.isNegative ? Duration.zero : value;
}
