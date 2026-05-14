# Yamyam Rider

Yamyam Rider is a warm, kid-friendly Flutter meal timer that turns eating into a small ride. Children choose a vehicle and a meal course, then follow the rider along a playful road until the meal mission is complete.

The app is built around a simple goal: make mealtime pacing feel like a cozy journey instead of a plain countdown.

## Highlights

- First-run child name setup
- Preset meal courses for 15, 25, and 35 minutes
- Custom meal duration from 1 to 60 minutes
- Compact vehicle selection with multiple rider vehicles
- Animated road progress based on timer progress
- State-aware timer copy for running, paused, arrived, and idle states
- Pause, resume, and complete controls during a meal session
- Optional remaining-time display
- Motivation video overlay during timer milestones
- Completion result screen with video or image fallback
- Local meal history, progress summary, and reward sticker inventory
- Sticker collection screen
- Korean and English localization
- Local settings persistence with `shared_preferences`
- Phase 2 polished UI system with shared colors, radius, shadows, spacing, and bouncy button variants

## App Flow

1. Launch the app and enter the child's name on first run.
2. Pick a vehicle on the home screen.
3. Start a preset course or configure a custom duration.
4. Watch the selected vehicle move along the road as the timer progresses.
5. Pause or resume the ride when needed.
6. Finish the meal from the timer controls or respond to the arrival prompt.
7. Review the result and earned stickers.
8. Return home or open the sticker collection.

## Tech Stack

- Flutter
- Dart
- Material 3
- Custom local text bundles for Korean and English
- `shared_preferences` for local settings and progress persistence
- `video_player` for motivation and result videos
- `lottie` for splash animation
- `flutter_launcher_icons` for launcher icon generation
- Cal Sans bundled font

## Project Structure

```text
lib/
  app.dart                         # App root, theme, localization, initial routing
  main.dart                        # App bootstrap and local service initialization
  catalogs/
    vehicle_catalog.dart           # Available vehicles and image assets
  controllers/
    meal_timer_controller.dart     # Timer state, progress, pause/resume logic
  l10n/
    app_texts.dart                 # Locale selection and text bundle wiring
    text_sets.dart                 # Text interfaces
    en/, ko/                       # English and Korean copy
  models/
    meal_timer_config.dart         # User timer settings
    meal_session_result.dart       # Completed session result data
    meal_progress_snapshot.dart    # Meal progress snapshot
    meal_history_entry.dart        # Stored meal history entry
    reward_item.dart               # Reward and sticker models
    vehicle.dart                   # Vehicle definition
  screens/
    splash_screen.dart             # Splash animation
    child_name_setup_screen.dart   # First-run child name setup
    home_screen.dart               # Course selection, vehicle picker, progress summary
    timer_screen.dart              # Active meal ride experience
    result_screen.dart             # Completion feedback and rewards
    settings_screen.dart           # Timer and display settings
    sticker_collection_screen.dart # Sticker inventory
  services/
    local_settings_service.dart    # SharedPreferences wrapper for settings
    local_meal_progress_service.dart # Local history and reward persistence
  theme/
    app_colors.dart                # Role-based color tokens
    app_radius.dart                # Radius tokens
    app_shadows.dart               # Shadow elevation tokens
    app_spacing.dart               # Spacing tokens
    app_motion.dart                # Motion tokens
    app_theme.dart                 # Material theme
  utils/
    duration_format.dart           # Duration display helper
  widgets/
    app/                           # Reusable UI primitives
    road_view.dart                 # Road scene, vehicle placement, video bubble
    road_painter.dart              # Road path drawing and progress highlight
    timer_control_bar.dart         # Pause/resume and complete controls
    vehicle_selection_card.dart    # Compact home vehicle picker
    vehicle_widget.dart            # Animated vehicle renderer
    reward_sticker_image.dart      # Sticker image with fallback

assets/
  fonts/                           # Cal Sans font
  images/                          # App icon, vehicles, stickers, result fallbacks
  videos/                          # Splash, motivation, and result media

test/
  widget_test.dart                 # App flow, localization, timer, vehicle, reward tests
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
flutter analyze
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
- The selected vehicle is shared across home, vehicle selector, timer road view, and vehicle rendering through `VehicleDefinition`.
- Settings and meal progress are stored locally with `SharedPreferences`.
- Sound and keep-screen-awake settings are persisted, but runtime behavior is still reserved for a later iteration.
- UI polish should use the shared design tokens in `lib/theme/` and reusable app widgets in `lib/widgets/app/`.
- Vehicle and sticker assets should keep consistent canvas size, padding, and visual scale when adding new artwork.

## Status

This is an active Flutter prototype with a Phase 2 polished kid-friendly UI. Core flows are covered by widget tests, including home actions, vehicle selection, timer copy, road progress, localization fallback, and reward persistence.
