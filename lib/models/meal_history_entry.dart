import 'meal_completion_status.dart';

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
    MealCompletionStatus? completionStatus,
  }) : completionStatus =
           completionStatus ??
           (mealCompleted
               ? (completedBeforeArrival
                     ? MealCompletionStatus.completedBeforeArrival
                     : MealCompletionStatus.completedAfterArrival)
               : MealCompletionStatus.notCompleted);

  factory MealHistoryEntry.fromJson(Map<String, Object?> json) {
    final rewardIds = json['rewardIds'];
    final completedBeforeArrival =
        json['completedBeforeArrival'] as bool? ?? false;
    final completionStatus = mealCompletionStatusFromJson(
      json['completionStatus'],
      completedBeforeArrival: completedBeforeArrival,
      mealCompleted: json['mealCompleted'] as bool?,
    );
    final mealCompleted =
        json['mealCompleted'] as bool? ??
        completionStatus != MealCompletionStatus.notCompleted;

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
    );
  }

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration targetDuration;
  final Duration actualDuration;
  final bool completedBeforeArrival;
  final bool mealCompleted;
  final MealCompletionStatus completionStatus;
  final List<String> rewardIds;

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
    };
  }
}
