import 'activity_completion_status.dart';

class MealHistoryEntry {
  const MealHistoryEntry({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.targetDuration,
    required this.actualDuration,
    required this.completedBeforeArrival,
    required this.rewardIds,
    this.mealCompleted = true,
    this.selectedIngredientIds = const [],
    ActivityCompletionStatus? completionStatus,
  }) : completionStatus =
           completionStatus ??
           (mealCompleted
               ? (completedBeforeArrival
                     ? ActivityCompletionStatus.completedBeforeEnd
                     : ActivityCompletionStatus.completedAfterEnd)
               : ActivityCompletionStatus.needsMoreTime);

  factory MealHistoryEntry.fromJson(Map<String, Object?> json) {
    final rewardIds = json['rewardIds'];
    final selectedIngredientIds = json['selectedIngredientIds'];
    final completedBeforeArrival =
        json['completedBeforeArrival'] as bool? ?? false;
    final completionStatus = activityCompletionStatusFromJson(
      json['completionStatus'],
      completedBeforeEnd: completedBeforeArrival,
      activityCompleted: json['mealCompleted'] as bool?,
    );
    final mealCompleted =
        json['mealCompleted'] as bool? ??
        _activityCompletionStatusIsCompleted(completionStatus);

    return MealHistoryEntry(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      targetDuration: Duration(milliseconds: json['targetMs'] as int),
      actualDuration: Duration(milliseconds: json['actualMs'] as int),
      completedBeforeArrival: completedBeforeArrival,
      mealCompleted: mealCompleted,
      completionStatus: completionStatus,
      rewardIds: rewardIds is List
          ? rewardIds.whereType<String>().toList(growable: false)
          : const [],
      selectedIngredientIds: selectedIngredientIds is List
          ? selectedIngredientIds.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration targetDuration;
  final Duration actualDuration;
  final bool completedBeforeArrival;
  final bool mealCompleted;
  final ActivityCompletionStatus completionStatus;
  final List<String> rewardIds;
  final List<String> selectedIngredientIds;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'targetMs': targetDuration.inMilliseconds,
      'actualMs': actualDuration.inMilliseconds,
      'completedBeforeArrival': completedBeforeArrival,
      'mealCompleted': mealCompleted,
      'completionStatus': completionStatus.name,
      'rewardIds': rewardIds,
      'selectedIngredientIds': selectedIngredientIds,
    };
  }
}

bool _activityCompletionStatusIsCompleted(ActivityCompletionStatus status) {
  return switch (status) {
    ActivityCompletionStatus.completedBeforeEnd ||
    ActivityCompletionStatus.completedAtEnd ||
    ActivityCompletionStatus.completedAfterEnd ||
    ActivityCompletionStatus.timeEnded => true,
    ActivityCompletionStatus.needsMoreTime ||
    ActivityCompletionStatus.canceled => false,
  };
}
