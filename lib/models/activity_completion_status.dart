enum ActivityCompletionStatus {
  completedBeforeEnd,
  completedAtEnd,
  completedAfterEnd,
  timeEnded,
  needsMoreTime,
  canceled,
}

bool activityCompletionStatusIsCompleted(ActivityCompletionStatus status) {
  return switch (status) {
    ActivityCompletionStatus.completedBeforeEnd ||
    ActivityCompletionStatus.completedAtEnd ||
    ActivityCompletionStatus.completedAfterEnd ||
    ActivityCompletionStatus.timeEnded => true,
    ActivityCompletionStatus.needsMoreTime ||
    ActivityCompletionStatus.canceled => false,
  };
}

bool activityCompletionStatusCanReceiveSticker(
  ActivityCompletionStatus status,
) {
  return switch (status) {
    ActivityCompletionStatus.completedBeforeEnd ||
    ActivityCompletionStatus.completedAtEnd ||
    ActivityCompletionStatus.completedAfterEnd => true,
    ActivityCompletionStatus.timeEnded ||
    ActivityCompletionStatus.needsMoreTime ||
    ActivityCompletionStatus.canceled => false,
  };
}

ActivityCompletionStatus activityCompletionStatusFromJson(
  Object? value, {
  required bool completedBeforeEnd,
  bool? activityCompleted,
}) {
  if (value is String) {
    for (final status in ActivityCompletionStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    final legacyStatus = switch (value) {
      'completedBeforeArrival' => ActivityCompletionStatus.completedBeforeEnd,
      'completedAtArrival' => ActivityCompletionStatus.completedAtEnd,
      'completedAfterArrival' => ActivityCompletionStatus.completedAfterEnd,
      'notCompleted' => ActivityCompletionStatus.needsMoreTime,
      _ => null,
    };
    if (legacyStatus != null) {
      return legacyStatus;
    }
  }

  if (activityCompleted == false) {
    return ActivityCompletionStatus.needsMoreTime;
  }
  return completedBeforeEnd
      ? ActivityCompletionStatus.completedBeforeEnd
      : ActivityCompletionStatus.completedAfterEnd;
}
