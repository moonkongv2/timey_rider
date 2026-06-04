enum MealCompletionStatus {
  completedBeforeArrival,
  completedAtArrival,
  completedAfterArrival,
  notCompleted,
}

MealCompletionStatus mealCompletionStatusFromJson(
  Object? value, {
  required bool completedBeforeArrival,
  bool? mealCompleted,
}) {
  if (value is String) {
    for (final status in MealCompletionStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
  }

  if (mealCompleted == false) {
    return MealCompletionStatus.notCompleted;
  }
  return completedBeforeArrival
      ? MealCompletionStatus.completedBeforeArrival
      : MealCompletionStatus.completedAfterArrival;
}
