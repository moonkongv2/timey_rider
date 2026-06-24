import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/activity_marker_catalog.dart';

void main() {
  test('markerIdsForActivity returns brushing markers', () {
    final markerIds = ActivityMarkerCatalog.markerIdsForActivity('brushing');

    expect(markerIds, ['top_teeth', 'bottom_teeth', 'molars', 'tongue']);
  });

  test('automaticSelectionIds for reading keeps auto marker order', () {
    final selectedIds = ActivityMarkerCatalog.automaticSelectionIds(
      activityId: 'reading',
      count: 7,
    );

    expect(selectedIds, [
      'cover',
      'first_pages',
      'favorite_scene',
      'bookmark',
      'finish',
      'star',
      'flag',
    ]);
  });

  test('autoSelectionIdsForActivity combines activity and common markers', () {
    final brushingIds = ActivityMarkerCatalog.autoSelectionIdsForActivity(
      'brushing',
    );

    expect(brushingIds, [
      'top_teeth',
      'bottom_teeth',
      'molars',
      'tongue',
      'star',
      'flag',
    ]);
  });

  test('brushing markers use process labels and friendly emoji', () {
    expect(ActivityMarkerCatalog.findById('top_teeth')?.labelKo, '위쪽 반짝');
    expect(ActivityMarkerCatalog.findById('bottom_teeth')?.emoji, '🫧');
    expect(ActivityMarkerCatalog.findById('molars')?.labelEn, 'Back brush');
    expect(ActivityMarkerCatalog.findById('tongue')?.labelKo, '마무리 헹굼');
  });

  test('reading finish marker does not duplicate the common flag emoji', () {
    expect(ActivityMarkerCatalog.findById('finish')?.emoji, isNot('🏁'));
    expect(ActivityMarkerCatalog.findById('finish')?.labelKo, '다 읽음');
  });

  test('cleanup markers use put-away labels', () {
    expect(ActivityMarkerCatalog.findById('blocks')?.labelKo, '블록 자리');
    expect(ActivityMarkerCatalog.findById('books')?.labelEn, 'Books');
    expect(ActivityMarkerCatalog.findById('cars')?.labelKo, '자동차 자리');
    expect(ActivityMarkerCatalog.findById('dolls')?.labelEn, 'Dolls');
    expect(ActivityMarkerCatalog.findById('box')?.labelKo, '정리 상자');
  });

  test('play markers include toy choices and shared markers', () {
    expect(ActivityMarkerCatalog.markerIdsForActivity('play'), [
      'cars',
      'dolls',
      'balloon',
      'ball',
      'music',
    ]);
    expect(ActivityMarkerCatalog.autoSelectionIdsForActivity('play'), [
      'cars',
      'dolls',
      'balloon',
      'ball',
      'music',
      'star',
      'flag',
    ]);
  });

  test('meal markers avoid napkin-like emoji', () {
    final mealIds = ActivityMarkerCatalog.markerIdsForActivity('meal');
    final mealEmoji = mealIds
        .map(ActivityMarkerCatalog.findById)
        .nonNulls
        .map((marker) => marker.emoji)
        .toList();

    expect(mealIds, ['spoon', 'sip_water', 'rice', 'plate', 'all_done']);
    expect(mealEmoji, isNot(contains('🧻')));
  });

  test('autoSelectionIdsForActivity falls back to common markers', () {
    expect(ActivityMarkerCatalog.autoSelectionIdsForActivity('custom'), [
      'star',
      'flag',
    ]);
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
