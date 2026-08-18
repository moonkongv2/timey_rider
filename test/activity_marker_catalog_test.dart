import 'package:flutter_test/flutter_test.dart';
import 'package:timey_rider/catalogs/activity_marker_catalog.dart';

void main() {
  test('markerIdsForActivity returns brushing markers', () {
    final markerIds = ActivityMarkerCatalog.markerIdsForActivity('brushing');

    expect(markerIds, ['top_teeth', 'bottom_teeth', 'molars', 'tongue']);
  });

  test('automaticSelectionIds for reading keeps activity marker order', () {
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
    ]);
  });

  test('autoSelectionIdsForActivity only returns activity markers', () {
    final brushingIds = ActivityMarkerCatalog.autoSelectionIdsForActivity(
      'brushing',
    );

    expect(brushingIds, ['top_teeth', 'bottom_teeth', 'molars', 'tongue']);
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

  test('course marker emoji avoid stars and check marks', () {
    final emoji = ActivityMarkerCatalog.all.map((marker) => marker.emoji);

    expect(emoji, isNot(contains('⭐')));
    expect(emoji, isNot(contains('🌟')));
    expect(emoji, isNot(contains('✅')));
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
    ]);
  });

  test('meal markers use direct food and utensil emoji', () {
    final mealIds = ActivityMarkerCatalog.markerIdsForActivity('meal');
    final mealEmoji = mealIds
        .map(ActivityMarkerCatalog.findById)
        .nonNulls
        .map((marker) => marker.emoji)
        .toList();

    expect(mealIds, [
      'rice',
      'spoon',
      'sip_water',
      'soup',
      'plate',
      'apple',
      'banana',
    ]);
    expect(mealEmoji, ['🍚', '🥄', '🥤', '🥣', '🍽️', '🍎', '🍌']);
    expect(mealEmoji, isNot(contains('🧻')));
  });

  test('autoSelectionIdsForActivity falls back to common markers only', () {
    expect(ActivityMarkerCatalog.autoSelectionIdsForActivity('custom'), [
      'smile',
      'star',
      'flag',
      'heart',
      'rainbow',
      'rocket',
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
    expect(
      slots.map((marker) => marker.id).take(defaultIds.length),
      defaultIds,
    );
  });
  test('Activity marker catalog has non-empty unique ids', () {
    final ids = ActivityMarkerCatalog.all.map((marker) => marker.id).toList();

    expect(ids, isNotEmpty);
    expect(ids.every((id) => id.trim().isNotEmpty), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('Activity marker automatic selection returns valid ids', () {
    final ids = ActivityMarkerCatalog.automaticSelectionIds();

    expect(ids, isNotEmpty);
    expect(ids, hasLength(ActivityMarkerCatalog.maxSelectableMarkerCount));
    for (final id in ids) {
      expect(ActivityMarkerCatalog.findById(id), isNotNull);
    }
  });

  test('Activity marker course slots returns exactly 30 markers', () {
    final slots = ActivityMarkerCatalog.courseSlotsFor([
      'top_teeth',
      'bottom_teeth',
    ]);

    expect(slots, hasLength(30));
  });

  test('Activity marker course slot count scales with duration', () {
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 1),
      ),
      30,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 5),
      ),
      30,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 15),
      ),
      54,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 25),
      ),
      90,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 35),
      ),
      126,
    );
    expect(
      ActivityMarkerCatalog.courseSlotCountForDuration(
        const Duration(minutes: 60),
      ),
      144,
    );
  });

  test('Activity marker course slots only uses selected ids', () {
    const selectedIds = ['top_teeth', 'bottom_teeth', 'molars'];
    final slots = ActivityMarkerCatalog.courseSlotsFor(selectedIds);

    expect(slots.map((marker) => marker.id).toSet(), {
      'top_teeth',
      'bottom_teeth',
      'molars',
    });
  });
  test('Activity marker course slots fall back for invalid selected ids', () {
    final slots = ActivityMarkerCatalog.courseSlotsFor(['missing']);

    expect(
      slots.map((marker) => marker.id).toSet(),
      ActivityMarkerCatalog.defaultSelectionIds.toSet(),
    );
  });

  test(
    'Activity marker course slots avoids 3 consecutive identical ids when possible',
    () {
      final slots = ActivityMarkerCatalog.courseSlotsFor([
        'top_teeth',
        'top_teeth',
        'bottom_teeth',
      ]);

      for (var index = 2; index < slots.length; index += 1) {
        expect(
          slots[index].id == slots[index - 1].id &&
              slots[index].id == slots[index - 2].id,
          isFalse,
        );
      }
    },
  );
}
