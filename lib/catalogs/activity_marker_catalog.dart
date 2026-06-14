import 'dart:math' as math;

import '../models/activity_marker.dart';

abstract final class ActivityMarkerCatalog {
  static const maxSelectableMarkerCount = 5;
  static const minCourseSlotCount = 30;
  static const maxCourseSlotCount = 144;
  static const referenceCourseDuration = Duration(minutes: 5);

  static const topTeeth = ActivityMarkerDefinition(
    id: 'top_teeth',
    labelKo: '윗니',
    labelEn: 'Top teeth',
    emoji: '😁',
    activityIds: ['brushing'],
  );

  static const bottomTeeth = ActivityMarkerDefinition(
    id: 'bottom_teeth',
    labelKo: '아랫니',
    labelEn: 'Bottom teeth',
    emoji: '😄',
    activityIds: ['brushing'],
  );

  static const frontTeeth = ActivityMarkerDefinition(
    id: 'front_teeth',
    labelKo: '앞니',
    labelEn: 'Front teeth',
    emoji: '😁',
    activityIds: ['brushing'],
  );

  static const molars = ActivityMarkerDefinition(
    id: 'molars',
    labelKo: '어금니',
    labelEn: 'Molars',
    emoji: '✨',
    activityIds: ['brushing'],
  );

  static const tongue = ActivityMarkerDefinition(
    id: 'tongue',
    labelKo: '혀',
    labelEn: 'Tongue',
    emoji: '😋',
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
    labelKo: '마지막 장',
    labelEn: 'Last page',
    emoji: '🏁',
    activityIds: ['reading'],
  );

  static const blocks = ActivityMarkerDefinition(
    id: 'blocks',
    labelKo: '블록',
    labelEn: 'Blocks',
    emoji: '🧱',
    activityIds: ['cleanup'],
  );

  static const books = ActivityMarkerDefinition(
    id: 'books',
    labelKo: '책',
    labelEn: 'Books',
    emoji: '📚',
    activityIds: ['cleanup'],
  );

  static const cars = ActivityMarkerDefinition(
    id: 'cars',
    labelKo: '자동차',
    labelEn: 'Cars',
    emoji: '🚗',
    activityIds: ['cleanup'],
  );

  static const dolls = ActivityMarkerDefinition(
    id: 'dolls',
    labelKo: '인형',
    labelEn: 'Dolls',
    emoji: '🧸',
    activityIds: ['cleanup'],
  );

  static const box = ActivityMarkerDefinition(
    id: 'box',
    labelKo: '상자',
    labelEn: 'Box',
    emoji: '📦',
    activityIds: ['cleanup'],
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
    star,
    flag,
    heart,
    rainbow,
    rocket,
  ];

  static const legacyMarkers = [frontTeeth];

  static const defaultSelectionIds = [
    'star',
    'flag',
    'heart',
    'rainbow',
    'rocket',
  ];

  static ActivityMarkerDefinition? findById(String id) {
    for (final marker in [...all, ...legacyMarkers]) {
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
    final markerIds = markerIdsForActivity(activityId);
    if (markerIds.isEmpty) {
      return defaultSelectionIds;
    }
    return List.unmodifiable(markerIds.take(maxSelectableMarkerCount));
  }

  static List<String> randomSelectionIds({
    String? activityId,
    int count = maxSelectableMarkerCount,
    math.Random? random,
  }) {
    if (count <= 0) {
      return const [];
    }

    final candidates = _randomCandidatesForActivity(activityId);
    final shuffled = candidates.map((marker) => marker.id).toList();
    shuffled.shuffle(random ?? math.Random());
    return List.unmodifiable(shuffled.take(math.min(count, shuffled.length)));
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

  static List<ActivityMarkerDefinition> _randomCandidatesForActivity(
    String? activityId,
  ) {
    if (activityId == null) {
      return all;
    }

    final markers = all
        .where((marker) => marker.activityIds.contains(activityId))
        .toList();
    return markers.isEmpty ? genericMarkers : markers;
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
}
