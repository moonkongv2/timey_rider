import '../models/activity.dart';

abstract final class ActivityCatalog {
  static const brushing = ActivityDefinition(
    id: 'brushing',
    labelKo: '양치',
    labelEn: 'Brush Teeth',
    emoji: '🪥',
    defaultDuration: Duration(minutes: 2),
    presetDurations: [
      Duration(minutes: 2),
      Duration(minutes: 3),
      Duration(minutes: 5),
    ],
    completionMode: ActivityCompletionMode.confirmDone,
    rewardEnabledByDefault: true,
    markerIds: ['top_teeth', 'bottom_teeth', 'molars', 'tongue'],
  );

  static const reading = ActivityDefinition(
    id: 'reading',
    labelKo: '책 읽기',
    labelEn: 'Reading',
    emoji: '📚',
    defaultDuration: Duration(minutes: 15),
    presetDurations: [
      Duration(minutes: 10),
      Duration(minutes: 15),
      Duration(minutes: 20),
    ],
    completionMode: ActivityCompletionMode.confirmDone,
    rewardEnabledByDefault: true,
    markerIds: ['cover', 'first_pages', 'favorite_scene', 'bookmark', 'finish'],
  );

  static const cleanup = ActivityDefinition(
    id: 'cleanup',
    labelKo: '정리',
    labelEn: 'Cleanup',
    emoji: '🧸',
    defaultDuration: Duration(minutes: 5),
    presetDurations: [
      Duration(minutes: 3),
      Duration(minutes: 5),
      Duration(minutes: 10),
    ],
    completionMode: ActivityCompletionMode.confirmDone,
    rewardEnabledByDefault: true,
    markerIds: ['blocks', 'books', 'cars', 'dolls', 'box'],
  );

  static const play = ActivityDefinition(
    id: 'play',
    labelKo: '놀이',
    labelEn: 'Play Time',
    emoji: '🎈',
    defaultDuration: Duration(minutes: 20),
    presetDurations: [
      Duration(minutes: 10),
      Duration(minutes: 20),
      Duration(minutes: 30),
    ],
    completionMode: ActivityCompletionMode.timeEndsAutomatically,
    rewardEnabledByDefault: false,
    markerIds: [],
  );

  static const meal = ActivityDefinition(
    id: 'meal',
    labelKo: '식사',
    labelEn: 'Meal',
    emoji: '🍽️',
    defaultDuration: Duration(minutes: 20),
    presetDurations: [
      Duration(minutes: 10),
      Duration(minutes: 20),
      Duration(minutes: 30),
    ],
    completionMode: ActivityCompletionMode.parentCheck,
    rewardEnabledByDefault: false,
    markerIds: [],
  );

  static const custom = ActivityDefinition(
    id: 'custom',
    labelKo: '기타',
    labelEn: 'Other',
    emoji: '⭐',
    defaultDuration: Duration(minutes: 10),
    presetDurations: [
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
    ],
    completionMode: ActivityCompletionMode.parentCheck,
    rewardEnabledByDefault: false,
    markerIds: [],
  );

  static const all = [brushing, play, cleanup, reading, meal, custom];

  static const defaultActivity = brushing;

  static ActivityDefinition findById(String id) {
    for (final activity in all) {
      if (activity.id == id) {
        return activity;
      }
    }
    return defaultActivity;
  }
}
