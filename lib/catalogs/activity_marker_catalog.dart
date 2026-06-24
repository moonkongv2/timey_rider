import 'dart:math' as math;

import '../models/activity_marker.dart';

abstract final class ActivityMarkerCatalog {
  static const maxSelectableMarkerCount = 5;
  static const minCourseSlotCount = 30;
  static const maxCourseSlotCount = 144;
  static const referenceCourseDuration = Duration(minutes: 5);

  static const topTeeth = ActivityMarkerDefinition(
    id: 'top_teeth',
    labelKo: '위쪽 반짝',
    labelEn: 'Top sparkle',
    emoji: '😁',
    activityIds: ['brushing'],
  );

  static const bottomTeeth = ActivityMarkerDefinition(
    id: 'bottom_teeth',
    labelKo: '아래쪽 반짝',
    labelEn: 'Bottom sparkle',
    emoji: '🫧',
    activityIds: ['brushing'],
  );

  static const molars = ActivityMarkerDefinition(
    id: 'molars',
    labelKo: '안쪽 꼼꼼',
    labelEn: 'Back brush',
    emoji: '✨',
    activityIds: ['brushing'],
  );

  static const tongue = ActivityMarkerDefinition(
    id: 'tongue',
    labelKo: '마무리 헹굼',
    labelEn: 'Final rinse',
    emoji: '💧',
    activityIds: ['brushing'],
  );

  static const cover = ActivityMarkerDefinition(
    id: 'cover',
    labelKo: '표지',
    labelEn: 'Cover',
    emoji: '📘',
    activityIds: ['reading'],
  );

  static const firstPages = ActivityMarkerDefinition(
    id: 'first_pages',
    labelKo: '첫 장',
    labelEn: 'First pages',
    emoji: '📖',
    activityIds: ['reading'],
  );

  static const favoriteScene = ActivityMarkerDefinition(
    id: 'favorite_scene',
    labelKo: '재미있는 장면',
    labelEn: 'Favorite scene',
    emoji: '🌟',
    activityIds: ['reading'],
  );

  static const bookmark = ActivityMarkerDefinition(
    id: 'bookmark',
    labelKo: '책갈피',
    labelEn: 'Bookmark',
    emoji: '🔖',
    activityIds: ['reading'],
  );

  static const finish = ActivityMarkerDefinition(
    id: 'finish',
    labelKo: '다 읽음',
    labelEn: 'All read',
    emoji: '✅',
    activityIds: ['reading'],
  );

  static const blocks = ActivityMarkerDefinition(
    id: 'blocks',
    labelKo: '블록 자리',
    labelEn: 'Blocks',
    emoji: '🧱',
    activityIds: ['cleanup'],
  );

  static const books = ActivityMarkerDefinition(
    id: 'books',
    labelKo: '책 자리',
    labelEn: 'Books',
    emoji: '📚',
    activityIds: ['cleanup'],
  );

  static const cars = ActivityMarkerDefinition(
    id: 'cars',
    labelKo: '자동차 자리',
    labelEn: 'Cars',
    emoji: '🚗',
    activityIds: ['cleanup', 'play'],
  );

  static const dolls = ActivityMarkerDefinition(
    id: 'dolls',
    labelKo: '인형 자리',
    labelEn: 'Dolls',
    emoji: '🧸',
    activityIds: ['cleanup', 'play'],
  );

  static const box = ActivityMarkerDefinition(
    id: 'box',
    labelKo: '정리 상자',
    labelEn: 'Toy box',
    emoji: '📦',
    activityIds: ['cleanup'],
  );

  static const balloon = ActivityMarkerDefinition(
    id: 'balloon',
    labelKo: '풍선',
    labelEn: 'Balloon',
    emoji: '🎈',
    activityIds: ['play'],
  );

  static const ball = ActivityMarkerDefinition(
    id: 'ball',
    labelKo: '공',
    labelEn: 'Ball',
    emoji: '⚽',
    activityIds: ['play'],
  );

  static const music = ActivityMarkerDefinition(
    id: 'music',
    labelKo: '음악',
    labelEn: 'Music',
    emoji: '🎵',
    activityIds: ['play'],
  );

  static const spoon = ActivityMarkerDefinition(
    id: 'spoon',
    labelKo: '숟가락',
    labelEn: 'Spoon',
    emoji: '🥄',
    activityIds: ['meal'],
  );

  static const sipWater = ActivityMarkerDefinition(
    id: 'sip_water',
    labelKo: '물 한 모금',
    labelEn: 'Sip of water',
    emoji: '🥤',
    activityIds: ['meal'],
  );

  static const rice = ActivityMarkerDefinition(
    id: 'rice',
    labelKo: '밥',
    labelEn: 'Rice',
    emoji: '🍚',
    activityIds: ['meal'],
  );

  static const plate = ActivityMarkerDefinition(
    id: 'plate',
    labelKo: '접시',
    labelEn: 'Plate',
    emoji: '🍽️',
    activityIds: ['meal'],
  );

  static const allDone = ActivityMarkerDefinition(
    id: 'all_done',
    labelKo: '잘 먹었어요',
    labelEn: 'All done',
    emoji: '✅',
    activityIds: ['meal'],
  );

  static const star = ActivityMarkerDefinition(
    id: 'star',
    labelKo: '별',
    labelEn: 'Star',
    emoji: '⭐',
  );

  static const flag = ActivityMarkerDefinition(
    id: 'flag',
    labelKo: '깃발',
    labelEn: 'Flag',
    emoji: '🏁',
  );

  static const heart = ActivityMarkerDefinition(
    id: 'heart',
    labelKo: '하트',
    labelEn: 'Heart',
    emoji: '💛',
  );

  static const rainbow = ActivityMarkerDefinition(
    id: 'rainbow',
    labelKo: '무지개',
    labelEn: 'Rainbow',
    emoji: '🌈',
  );

  static const rocket = ActivityMarkerDefinition(
    id: 'rocket',
    labelKo: '로켓',
    labelEn: 'Rocket',
    emoji: '🚀',
  );

  static const genericMarkers = [star, flag, heart, rainbow, rocket];

  static const all = [
    topTeeth,
    bottomTeeth,
    molars,
    tongue,
    cover,
    firstPages,
    favoriteScene,
    bookmark,
    finish,
    blocks,
    books,
    cars,
    dolls,
    box,
    balloon,
    ball,
    music,
    spoon,
    sipWater,
    rice,
    plate,
    allDone,
    star,
    flag,
    heart,
    rainbow,
    rocket,
  ];

  static const defaultSelectionIds = [
    'star',
    'flag',
    'heart',
    'rainbow',
    'rocket',
  ];

  static const commonAutoSelectionIds = ['star', 'flag'];

  static ActivityMarkerDefinition? findById(String id) {
    for (final marker in all) {
      if (marker.id == id) {
        return marker;
      }
    }
    return null;
  }

  static List<String> markerIdsForActivity(String activityId) {
    return List.unmodifiable(
      all
          .where((marker) => marker.activityIds.contains(activityId))
          .map((marker) => marker.id),
    );
  }

  static List<String> defaultSelectionIdsForActivity(String activityId) {
    return autoSelectionIdsForActivity(activityId);
  }

  static List<String> autoSelectionIdsForActivity(String? activityId) {
    final ids = <String>[];
    if (activityId != null) {
      ids.addAll(markerIdsForActivity(activityId));
    }
    ids.addAll(commonAutoSelectionIds);
    if (ids.isEmpty) {
      ids.addAll(defaultSelectionIds);
    }
    return List.unmodifiable(_uniqueKnownIds(ids));
  }

  static List<String> automaticSelectionIds({
    String? activityId,
    int count = maxSelectableMarkerCount,
  }) {
    if (count <= 0) {
      return const [];
    }

    final candidateIds = autoSelectionIdsForActivity(activityId);
    return List.unmodifiable(candidateIds.take(count));
  }

  static List<ActivityMarkerDefinition> courseSlotsFor(
    List<String> selectedIds, {
    int slotCount = minCourseSlotCount,
  }) {
    if (slotCount <= 0) {
      return const [];
    }

    final selectedMarkers = _markersForIds(selectedIds);
    final markers = selectedMarkers.isEmpty
        ? _markersForIds(defaultSelectionIds)
        : selectedMarkers;
    final slots = <ActivityMarkerDefinition>[];

    for (var index = 0; index < slotCount; index += 1) {
      var marker = markers[index % markers.length];
      if (markers.length >= 2 &&
          slots.length >= 2 &&
          slots[slots.length - 1].id == marker.id &&
          slots[slots.length - 2].id == marker.id) {
        marker = markers[(index + 1) % markers.length];
      }
      slots.add(marker);
    }

    return List.unmodifiable(slots);
  }

  static int courseSlotCountForDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return minCourseSlotCount;
    }

    final durationFactor =
        duration.inMilliseconds / referenceCourseDuration.inMilliseconds;
    final clampedFactor = math.max(1.0, durationFactor);
    final targetSlotCount = (18 * clampedFactor).round();
    return targetSlotCount
        .clamp(minCourseSlotCount, maxCourseSlotCount)
        .toInt();
  }

  static List<ActivityMarkerDefinition> _markersForIds(List<String> ids) {
    final markers = <ActivityMarkerDefinition>[];
    final seenIds = <String>{};
    for (final id in ids) {
      final marker = findById(id);
      if (marker == null || !seenIds.add(marker.id)) {
        continue;
      }
      markers.add(marker);
    }
    return markers;
  }

  static List<String> _uniqueKnownIds(List<String> ids) {
    final selectedIds = <String>[];
    final seenIds = <String>{};
    for (final id in ids) {
      if (!seenIds.add(id) || findById(id) == null) {
        continue;
      }
      selectedIds.add(id);
    }
    return selectedIds;
  }
}
