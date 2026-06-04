import 'meal_completion_status.dart';

class MealSessionResult {
  const MealSessionResult({
    required this.startedAt,
    required this.endedAt,
    required this.targetDuration,
    required this.actualDuration,
    required this.completedBeforeArrival,
    this.mealCompleted = true,
    MealCompletionStatus? completionStatus,
  }) : completionStatus =
           completionStatus ??
           (mealCompleted
               ? (completedBeforeArrival
                     ? MealCompletionStatus.completedBeforeArrival
                     : MealCompletionStatus.completedAfterArrival)
               : MealCompletionStatus.notCompleted);

  final DateTime startedAt;
  final DateTime endedAt;
  final Duration targetDuration;
  final Duration actualDuration;
  final bool completedBeforeArrival;
  final bool mealCompleted;
  final MealCompletionStatus completionStatus;
}
