abstract final class AppFeatureFlags {
  static const bool motivationMediaAvailable = bool.fromEnvironment(
    'ENABLE_MOTIVATION_MEDIA',
    defaultValue: false,
  );
}
