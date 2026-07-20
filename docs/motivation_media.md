# Motivation Media Deferral

Motivation video and voice media are temporarily unavailable in the launch
build because complete localized voice resources are not ready for every
supported language.

This is a feature availability gate, not a feature deletion. The catalog,
scheduling utilities, video widgets, audio service interfaces, configuration
fields, SharedPreferences keys, active-session fields, localization strings,
tests, and source media files are intentionally preserved so the feature can be
restored with a small code and asset registration change.

## Build Flag

Motivation media availability is controlled by:

```bash
--dart-define=ENABLE_MOTIVATION_MEDIA=true
```

The app-level flag is:

```dart
AppFeatureFlags.motivationMediaAvailable
```

Default launch behavior is `false`.

`motivationMediaAvailable` means the build offers the motivation video and
voice feature. `ActivityTimerConfig.motivationVideoEnabled` is the user's saved
preference for the feature when it is available. Do not overwrite or discard the
saved preference when build availability is false.

## Deferred Assets

Launch builds must not bundle these pubspec asset entries:

```yaml
    - assets/videos/motivation/
    - assets/audio/motivation/
```

The media source files stay in Git. To re-enable the feature, restore both
entries to `pubspec.yaml` before building with
`ENABLE_MOTIVATION_MEDIA=true`.

Enabling the flag without restoring these asset entries is invalid. The catalog
will still point to motivation asset paths, but the files will not be in the app
bundle.

## Locale Coverage Required

Before release re-enablement, motivation voice resources must be complete for:

- Korean
- English
- Japanese
- Spanish
- Portuguese

Do not rely on English fallback as the launch-quality behavior for supported
locales.

## Reference Tag

Use this reference tag for the last prelaunch enabled state:

```text
motivation-media-enabled-prelaunch-v1
```

## Re-enable Checklist

- Confirm Korean, English, Japanese, Spanish, and Portuguese voice coverage.
- Restore `assets/videos/motivation/` in `pubspec.yaml`.
- Restore `assets/audio/motivation/` in `pubspec.yaml`.
- Build with `--dart-define=ENABLE_MOTIVATION_MEDIA=true`.
- Run enabled-state tests that explicitly inject
  `motivationMediaAvailable: true`.
- Manually verify timer milestone video display and voice playback with fake or
  restored media resources.
- Verify launch-disabled builds still hide UI and do not bundle motivation
  media.

## Commands

Disabled launch checks:

```bash
dart format lib test
flutter pub get
flutter analyze
flutter test
flutter clean
flutter pub get
flutter build appbundle --release \
  --dart-define=ENABLE_MOTIVATION_MEDIA=false
unzip -l build/app/outputs/bundle/release/app-release.aab \
  | grep -E 'assets/(videos|audio)/motivation'
flutter build ios --release --no-codesign \
  --dart-define=ENABLE_MOTIVATION_MEDIA=false
```

The Android bundle inspection should print no matches.

Enabled restoration checks after restoring asset entries:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=ENABLE_MOTIVATION_MEDIA=true
```

Do not ship an enabled build unless the restored assets and locale coverage are
complete.
