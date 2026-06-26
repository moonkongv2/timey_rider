import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/activity_catalog.dart';
import 'package:timey_rider/models/activity_completion_status.dart';
import 'package:timey_rider/models/activity_session_result.dart';

void main() {
  test('ActivityCatalog.findById returns matching activity', () {
    final activity = ActivityCatalog.findById('reading');

    expect(activity.id, 'reading');
    expect(activity.labelEn, 'Reading');
    expect(activity.defaultDuration, const Duration(minutes: 15));
  });

  test('ActivityCatalog.findById falls back to default activity', () {
    final activity = ActivityCatalog.findById('missing');

    expect(activity, same(ActivityCatalog.defaultActivity));
    expect(activity.id, 'brushing');
  });

  test('ActivityDefinition.labelForLanguage returns localized label', () {
    final activity = ActivityCatalog.findById('cleanup');

    expect(activity.labelForLanguage('ko'), '정리');
    expect(activity.labelForLanguage('en'), 'Cleanup');
    expect(activity.labelForLanguage('ja'), 'Cleanup');
  });

  test('play and meal activities define default marker ids', () {
    expect(ActivityCatalog.play.markerIds, [
      'balloon',
      'ball',
      'music',
      'cars',
      'dolls',
    ]);
    expect(ActivityCatalog.meal.markerIds, [
      'rice',
      'spoon',
      'sip_water',
      'soup',
      'plate',
      'apple',
      'banana',
    ]);
  });

  test('activityCompletionStatusFromJson returns known status values', () {
    final status = activityCompletionStatusFromJson(
      'completedAtEnd',
      completedBeforeEnd: false,
      activityCompleted: false,
    );

    expect(status, ActivityCompletionStatus.completedAtEnd);
  });

  test('activityCompletionStatusFromJson maps legacy status values', () {
    final status = activityCompletionStatusFromJson(
      'completedAtArrival',
      completedBeforeEnd: false,
    );

    expect(status, ActivityCompletionStatus.completedAtEnd);
  });

  test(
    'activityCompletionStatusFromJson falls back for incomplete activity',
    () {
      final status = activityCompletionStatusFromJson(
        'invalid',
        completedBeforeEnd: true,
        activityCompleted: false,
      );

      expect(status, ActivityCompletionStatus.needsMoreTime);
    },
  );

  test('activityCompletionStatusFromJson falls back for early completion', () {
    final status = activityCompletionStatusFromJson(
      null,
      completedBeforeEnd: true,
    );

    expect(status, ActivityCompletionStatus.completedBeforeEnd);
  });

  test('activityCompletionStatusFromJson falls back for late completion', () {
    final status = activityCompletionStatusFromJson(
      'not-a-status',
      completedBeforeEnd: false,
    );

    expect(status, ActivityCompletionStatus.completedAfterEnd);
  });

  test('ActivitySessionResult activityCompleted follows completion status', () {
    final startedAt = DateTime.utc(2026, 6, 13, 1);
    final completed = ActivitySessionResult(
      activityId: 'brushing',
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 2)),
      targetDuration: const Duration(minutes: 2),
      actualDuration: const Duration(minutes: 2),
      completedBeforeEnd: false,
      completionStatus: ActivityCompletionStatus.timeEnded,
    );
    final incomplete = ActivitySessionResult(
      activityId: 'brushing',
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 1)),
      targetDuration: const Duration(minutes: 2),
      actualDuration: const Duration(minutes: 1),
      completedBeforeEnd: false,
      completionStatus: ActivityCompletionStatus.needsMoreTime,
    );

    expect(completed.activityCompleted, isTrue);
    expect(incomplete.activityCompleted, isFalse);
  });

  test(
    'Activity completion status helpers separate completion and stickers',
    () {
      expect(
        activityCompletionStatusIsCompleted(
          ActivityCompletionStatus.completedBeforeEnd,
        ),
        isTrue,
      );
      expect(
        activityCompletionStatusIsCompleted(ActivityCompletionStatus.timeEnded),
        isTrue,
      );
      expect(
        activityCompletionStatusIsCompleted(
          ActivityCompletionStatus.needsMoreTime,
        ),
        isFalse,
      );

      expect(
        activityCompletionStatusCanReceiveSticker(
          ActivityCompletionStatus.completedAtEnd,
        ),
        isTrue,
      );
      expect(
        activityCompletionStatusCanReceiveSticker(
          ActivityCompletionStatus.timeEnded,
        ),
        isFalse,
      );
      expect(
        activityCompletionStatusCanReceiveSticker(
          ActivityCompletionStatus.canceled,
        ),
        isFalse,
      );
    },
  );

  test('ActivitySessionResult copyWith updates selected marker ids', () {
    final startedAt = DateTime.utc(2026, 6, 13, 1);
    final result = ActivitySessionResult(
      activityId: 'brushing',
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 2)),
      targetDuration: const Duration(minutes: 2),
      actualDuration: const Duration(minutes: 2),
      completedBeforeEnd: false,
      completionStatus: ActivityCompletionStatus.completedAtEnd,
      selectedMarkerIds: const ['top_teeth'],
    );

    final updated = result.copyWith(
      selectedMarkerIds: const ['top_teeth', 'bottom_teeth'],
    );

    expect(result.selectedMarkerIds, const ['top_teeth']);
    expect(updated.selectedMarkerIds, const ['top_teeth', 'bottom_teeth']);
  });
}
