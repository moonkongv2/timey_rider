import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ticky_rider/catalogs/activity_marker_catalog.dart';

void main() {
  test('markerIdsForActivity returns brushing markers', () {
    final markerIds = ActivityMarkerCatalog.markerIdsForActivity('brushing');

    expect(markerIds, [
      'top_teeth',
      'bottom_teeth',
      'front_teeth',
      'molars',
      'tongue',
    ]);
  });

  test('randomSelectionIds for reading returns only reading markers', () {
    final selectedIds = ActivityMarkerCatalog.randomSelectionIds(
      activityId: 'reading',
      random: math.Random(1),
    );
    final readingIds = ActivityMarkerCatalog.markerIdsForActivity('reading');

    expect(selectedIds, hasLength(5));
    expect(selectedIds.every(readingIds.contains), isTrue);
  });

  test('courseSlotCountForDuration clamps between min and max', () {
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(Duration.zero),
      ActivityMarkerCatalog.minCourseSlotCount,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 1),
      ),
      ActivityMarkerCatalog.minCourseSlotCount,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(hours: 2),
      ),
      ActivityMarkerCatalog.maxCourseSlotCount,
    );
  });

  test('courseSlotsFor falls back to generic markers when ids are empty', () {
    final slots = ActivityMarkerCatalog.courseSlotsFor(const [], slotCount: 7);
    final defaultIds = ActivityMarkerCatalog.defaultSelectionIds;

    expect(slots, hasLength(7));
    expect(slots.every((marker) => defaultIds.contains(marker.id)), isTrue);
    expect(slots.map((marker) => marker.id).take(5), defaultIds);
  });
}
