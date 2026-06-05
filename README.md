# Yamyam Rider

Yamyam Rider is a warm, kid-friendly Flutter meal timer that turns eating into a small ride. Children choose a rider vehicle, start a meal course, and follow the character along a playful road until the meal mission is complete.

The app is designed around one simple goal: make mealtime pacing feel like a cozy journey instead of a plain countdown.

## Highlights

- First-run child name setup and local settings persistence
- Preset meal courses for 15, 25, and 35 minutes
- Custom meal duration from 1 to 60 minutes
- Home course suggestions that adapt to the saved default duration
- 12 selectable rider vehicles: motorcycle, fire truck, police car, excavator, airplane, bus, supercar, train, T-rex, shark, brachio, and pteranodon
- Vehicle-specific custom avatar storage and preview
- Custom avatar setup flow with image upload, per-vehicle adjustment controls, and prompt guidance
- Animated road progress based on timer progress
- Portrait and landscape timer layouts with dedicated road, vehicle, and motivation video layers
- Pause, resume, complete, arrival prompt, and exit confirmation flows
- Optional remaining-time display, sound effects, and keep-screen-awake setting
- Short motivation video overlay during timer milestones
- Locale-based shared motivation voice playback when sound is enabled
- Completion result screen with vehicle-specific success videos and fallback handling
- Local meal history, progress summary, reward stickers, and reward goal tracking
- Sticker collection and reward goal screens
- Korean and English localization
- Shared kid-friendly UI system with colors, radius, shadows, spacing, motion, cards, and bouncy buttons

## App Flow

1. Launch the app and enter the child's name on first run.
2. Pick a rider vehicle on the home screen.
3. Start a preset course or configure a custom duration.
4. Watch the selected vehicle move along the road as the timer progresses.
5. See short motivation videos at progress milestones.
6. If sound is enabled, hear a short locale-based cheer voice with the motivation video.
7. Pause, resume, complete, or respond to the arrival prompt when needed.
8. Review the result and earned stickers.
9. Track meal history, sticker inventory, and reward goals from the home screen.

## Motivation Media

Motivation videos are short silent cheer-up clips, focused on smiling and thumbs-up style encouragement rather than spoken lip-sync video.

Current behavior:

- Milestones still decide when a motivation video can appear.
- The actual video is selected from the current vehicle's candidate list.
- Unknown or unsupported vehicle IDs fall back to `motivation_fallback.mp4`.
- Motivation videos have a minimum replay interval.
- For test builds, the current minimum interval is set to 10 seconds.
- When `soundEnabled` is off, only the video is shown.
- When `soundEnabled` is on, the app picks a shared voice clip by locale.
- Korean uses `ko_*.mp3`, English uses `en_*.mp3`.
- Unsupported locales fall back to English voice clips.
- Vehicle-specific voice override support is reserved in the catalog structure, but not used yet.

Asset layout:

```text
assets/
  videos/
    motivation/
      motivation_motorcycle_1.mp4
      motivation_motorcycle_2.mp4
      motivation_fallback.mp4
      ...
  audio/
    motivation/
      ko_1.mp3
      ko_2.mp3
      en_1.mp3
      en_2.mp3
```

## Tech Stack

- Flutter
- Dart
- Material 3
- Custom local text bundles for Korean and English
- `shared_preferences` for local settings, progress, history, stickers, and rewards
- `video_player` for splash, motivation, and result videos
- `audioplayers` for motivation voice playback
- `image_picker`, `path_provider`, and `image` for custom avatar image import and normalization
- `wakelock_plus` for the keep-screen-awake timer setting
- `flutter_launcher_icons` for launcher icon generation
- Cal Sans bundled font

## Project Structure

```text
lib/
  app.dart                           # App root, theme, localization, initial routing
  main.dart                          # App bootstrap and local service initialization
  catalogs/
    avatar_prompt_catalog.dart       # Vehicle-specific avatar generation prompt copy
    meal_course_catalog.dart         # Preset and custom meal course constants
    motivation_asset_catalog.dart    # Motivation video and voice asset catalogs
    vehicle_catalog.dart             # Available vehicles and image assets
  controllers/
    meal_timer_controller.dart       # Timer state, progress, pause/resume logic
  l10n/
    app_texts.dart                   # Locale selection and text bundle wiring
    text_sets.dart                   # Text interfaces
    en/, ko/                         # English and Korean copy
  models/
    meal_timer_config.dart           # User timer, vehicle, avatar, and display settings
    meal_session_result.dart         # Completed session result data
    meal_progress_snapshot.dart      # Meal progress snapshot
    meal_history_entry.dart          # Stored meal history entry
    reward_goal.dart                 # Reward goal models
    reward_item.dart                 # Reward and sticker models
    vehicle.dart                     # Vehicle definition and avatar slot
  navigation/
    app_route_observer.dart          # Route observer for home refresh behavior
  screens/
    splash_screen.dart               # Splash video
    child_name_setup_screen.dart     # First-run child name setup
    home_screen.dart                 # Course selection, vehicle picker, progress summary
    timer_screen.dart                # Active meal ride experience
    result_screen.dart               # Completion feedback and rewards
    settings_screen.dart             # Timer, sound, display, and avatar settings
    avatar_setup_screen.dart         # Custom avatar upload, adjustment, and prompt flow
    reward_goal_screen.dart          # Reward goal creation and management
    sticker_collection_screen.dart   # Sticker inventory
  services/
    avatar_image_picker.dart         # Avatar image picker abstraction
    local_avatar_image_service.dart  # Local avatar image normalization and storage
    local_settings_service.dart      # SharedPreferences wrapper for settings
    local_meal_progress_service.dart # Local history, sticker, and reward persistence
    motivation_audio_service.dart    # Motivation voice playback wrapper
    screen_awake_service.dart        # Wakelock wrapper
  theme/
    app_colors.dart                  # Role-based color tokens
    app_motion.dart                  # Motion tokens
    app_radius.dart                  # Radius tokens
    app_shadows.dart                 # Shadow elevation tokens
    app_spacing.dart                 # Spacing tokens
    app_theme.dart                   # Material theme
  utils/
    duration_format.dart             # Duration display helper
  widgets/
    app/                             # Reusable UI primitives
    avatar/                          # Avatar composite preview
    road_view.dart                   # Road scene, vehicle placement, video bubble/layers
    road_painter.dart                # Road path drawing and progress highlight
    timer_control_bar.dart           # Pause/resume and complete controls
    vehicle_selection_card.dart      # Compact vehicle picker with avatar previews
    vehicle_widget.dart              # Vehicle renderer with avatar composite support
    reward_sticker_image.dart        # Sticker image with fallback

assets/
  audio/motivation/                  # Locale-based shared motivation voice clips
  fonts/                             # Cal Sans font
  images/                            # App icon, vehicles, stickers, result fallbacks
  videos/                            # Splash and result media
  videos/motivation/                 # Vehicle-specific silent motivation videos

test/
  widget_test.dart                   # App flow, localization, timer, vehicle, avatar, media, reward tests
```

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run static analysis:

```bash
dart analyze
```

Run tests:

```bash
flutter test
```

Generate launcher icons after changing icon assets:

```bash
dart run flutter_launcher_icons
```

## Development Notes

- `MealTimerController` calculates elapsed time from wall-clock timestamps so progress stays accurate even if frame or ticker timing varies.
- Timer UI copy is state-aware: running uses progress-based messages, paused shows break copy, and arrived/completed shows arrival copy.
- The selected vehicle is shared across home, vehicle selector, timer road view, result media, and avatar rendering through `VehicleDefinition`.
- Custom avatar images are stored per vehicle, so multiple vehicle tiles can keep their own custom avatar previews.
- Settings, meal progress, sticker inventory, reward goals, and avatar config are stored locally with `SharedPreferences`.
- Motivation video paths and voice paths should be registered through `MotivationAssetCatalog`.
- Vehicle and sticker assets should keep consistent canvas size, padding, and visual scale when adding new artwork.
- UI polish should use the shared design tokens in `lib/theme/` and reusable app widgets in `lib/widgets/app/`.
- Do not commit generated or reference-only files from `assets/resources/` unless they are intentionally part of the app.

## Status

This is an active Flutter prototype with a polished kid-friendly UI. Core flows are covered by widget tests, including first launch, home actions, vehicle selection, custom avatars, timer copy, road progress, motivation media catalogs, localization fallback, stickers, and reward persistence.
