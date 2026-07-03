# Timey Rider

Timey Rider is a warm, kid-friendly Flutter routine timer that turns everyday activities into small playful rides.

This repository was split from the original rider timer and is being converted into a general kids routine timer.

- Timey Rider keeps the ride-based timer, vehicles, avatars, rewards, and local progress tracking.
- The product direction is expanding toward routines like brushing teeth, reading, cleanup, play time, and custom timers.
- Activity-first concepts are being added while keeping the app runnable and localized.

The app is designed around one simple goal: make daily routines feel like cozy journeys instead of plain countdowns.

## Highlights

- First-run empathy onboarding cards before child name setup
- Child name setup and local settings persistence
- Activity quick starts for brushing teeth, reading, cleanup, play time, and custom timers
- Custom timer duration from 1 to 60 minutes
- Course marker setup with automatic previews or selected picture markers
- Home course suggestions that adapt to the saved default duration
- 12 selectable rider vehicles: motorcycle, fire truck, police car, excavator, airplane, bus, supercar, train, T-rex, shark, brachio, and pteranodon
- Vehicle-specific custom avatar storage and preview
- Custom avatar setup flow with image upload, per-vehicle adjustment controls, and prompt guidance
- Animated road, rail, sky, or water course progress based on the selected vehicle
- Portrait and landscape timer layouts with dedicated road, vehicle, and motivation video layers
- Pause, resume, complete, arrival prompt, and exit confirmation flows
- Optional remaining-time display, sound effects, and keep-screen-awake setting
- Short motivation video overlay during timer milestones
- Locale-based shared motivation voice playback when sound is enabled
- Completion result screen with vehicle-specific success videos and fallback handling
- In-app parent guide and contextual help for markers, motivation videos, results, rewards, and history
- Local active timer session restore, activity history, progress summary, reward stickers, and reward goal tracking
- Sticker collection and reward goal screens
- Korean and English localization
- Shared kid-friendly UI system with colors, radius, shadows, spacing, motion, cards, and bouncy buttons

## App Flow

1. Review the first-run onboarding cards.
2. Enter the child's name on first setup.
3. Pick an activity mission such as brushing teeth, reading, cleanup, play time, or custom timer.
4. Pick a rider vehicle on the home screen.
5. Start the activity timer with automatic or selected picture markers.
6. Watch the selected rider move along the course as the timer progresses.
7. See short motivation videos and optional cheer audio during the timer.
8. Complete the activity, let time end, or record that more time is needed.
9. Review the result and earned stickers.
10. Track activity history, sticker inventory, and reward goals from the home screen.

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

## Assets Status / TODO

- Launcher icon: Timey Rider source icon is configured at `assets/icons/timey_rider_app_icon.png`.
- Adaptive icon foreground/background: Timey Rider adaptive icon assets are configured at `assets/icons/timey_rider_app_icon_foreground.png` and `assets/icons/timey_rider_app_icon_background.png`.
- Timey Rider logo: the home header uses `assets/images/timey_rider_logo.png` with a text fallback if the asset cannot load.
- Onboarding illustrations: add card images under `assets/images/onboarding/`; the vehicle choice card uses existing vehicle chip assets.
- Activity marker image assets: add optional marker images under `assets/images/markers/` when emoji-only markers are not enough.
- Vehicle stickers: reward stickers reuse the standalone vehicle image assets in `assets/images/`.

## Tech Stack

- Flutter
- Dart
- Material 3
- Custom local text bundles for Korean and English
- `shared_preferences` for local settings, progress, history, stickers, and rewards
- `in_app_purchase` for the optional one-time vehicle pack purchase
- `video_player` for splash, motivation, and result videos
- `audioplayers` for motivation voice playback
- `image_picker`, `path_provider`, and `image` for custom avatar image import and normalization
- `wakelock_plus` for the keep-screen-awake timer setting
- `flutter_launcher_icons` for launcher icon generation
- Cal Sans bundled font

## Purchase and Privacy Direction

- Timey Rider has no ads, analytics, account login, backend server, or remote config.
- Normal app settings, timer progress, activity history, stickers, rewards, avatar settings, and the purchase entitlement cache are local-first.
- The vehicle pack uses the non-consumable product ID `vehicle_pack` and unlocks all locked vehicles after a successful purchase or restore.
- Purchase and restore entry points are shown only after a parent/guardian check.
- Custom rider image selection is optional and user-initiated. The selected image is imported from the device and stored locally by Timey Rider; the app does not upload rider images or child photos to a server.
- Because there is no backend receipt validation, the app relies on the app store purchase result and local entitlement cache. Store restore is required for cross-device or reinstall recovery.

## Project Structure

```text
lib/
  app.dart                           # App root, theme, localization, initial routing
  main.dart                          # App bootstrap and local service initialization
  catalogs/
    avatar_prompt_catalog.dart       # Vehicle-specific avatar generation prompt copy
    activity_catalog.dart            # Built-in activity definitions and defaults
    activity_marker_catalog.dart     # Activity marker options and course slot generation
    timer_duration_catalog.dart      # Preset and custom timer duration constants
    motivation_asset_catalog.dart    # Motivation video and voice asset catalogs
    vehicle_catalog.dart             # Available vehicles and image assets
  controllers/
    activity_timer_controller.dart   # Timer state, progress, pause/resume logic
  l10n/
    app_texts.dart                   # Locale selection and text bundle wiring
    text_sets.dart                   # Text interfaces
    en/, ko/                         # English and Korean copy
    en/user_guide.dart, ko/user_guide.dart # Parent guide copy
  models/
    activity_timer_config.dart       # User timer, vehicle, avatar, and display settings
    active_activity_timer_session.dart # Persisted active timer session data
    activity_completion_status.dart  # Completion status enum
    activity_marker.dart             # Activity marker definition
    activity_session_result.dart     # Completed session result data
    activity_progress_snapshot.dart  # Activity progress snapshot
    activity_history_entry.dart      # Stored activity history entry
    reward_goal.dart                 # Reward goal models
    reward_item.dart                 # Reward and sticker models
    vehicle.dart                     # Vehicle definition and avatar slot
    vehicle_avatar_presentation.dart # Resolved default/custom avatar presentation
  navigation/
    app_route_observer.dart          # Route observer for home refresh behavior
  screens/
    splash_screen.dart               # Splash video
    child_name_setup_screen.dart     # First-run child name setup
    home_screen.dart                 # Activity selection, vehicle picker, progress summary
    activity_history_screen.dart     # Stored activity record list
    timer_screen.dart                # Active activity ride experience
    result_screen.dart               # Completion feedback and rewards
    settings_screen.dart             # Timer, sound, display, and avatar settings
    user_guide_screen.dart           # In-app parent guide and usage rules
    avatar_setup_screen.dart         # Custom avatar upload, adjustment, and prompt flow
    reward_goal_screen.dart          # Reward goal creation and management
    sticker_collection_screen.dart   # Sticker inventory
  services/
    avatar_image_picker.dart         # Avatar image picker abstraction
    active_activity_timer_session_store.dart # SharedPreferences store for active timer sessions
    local_avatar_image_service.dart  # Local avatar image normalization and storage
    local_settings_service.dart      # SharedPreferences wrapper for settings
    local_activity_progress_service.dart # Local history, sticker, and reward persistence
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
    motivation_video_schedule.dart   # Timer milestone scheduling for motivation media
  widgets/
    app/                             # Reusable UI primitives
    app/app_help_sheet.dart          # Reusable contextual help bottom sheet
    avatar/                          # Avatar composite preview
    activity_marker_picker_sheet.dart # Automatic/selected marker picker
    road_view.dart                   # Road scene, vehicle placement, video bubble/layers
    road_painter.dart                # Road path drawing and progress highlight
    timer_control_bar.dart           # Pause/resume and complete controls
    vehicle_selection_card.dart      # Compact vehicle picker with avatar previews
    vehicle_widget.dart              # Vehicle renderer with avatar composite support
    reward_sticker_image.dart        # Sticker image with fallback

assets/
  audio/motivation/                  # Locale-based shared motivation voice clips
  fonts/                             # Cal Sans font
  images/                            # Vehicles, markers, result fallbacks
  icons/                             # Launcher icon source assets
  videos/                            # Splash and result media
  videos/motivation/                 # Vehicle-specific silent motivation videos

test/
  active_activity_timer_session_store_test.dart # Active timer persistence tests
  avatar_composite_preview_test.dart # Avatar preview fallback and rendering tests
  local_avatar_image_service_test.dart # Avatar image storage tests
  activity_timer_controller_test.dart # Timer restore and state transition tests
  vehicle_avatar_presentation_test.dart # Avatar presentation resolution tests
  widget_test.dart                   # App flow, localization, vehicle, media, reward tests
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

- `ActivityTimerController` calculates elapsed time from wall-clock timestamps so progress stays accurate even if frame or ticker timing varies.
- `ActiveActivityTimerSessionStore` persists running or paused timer sessions for restore behavior.
- Timer UI copy is state-aware: running uses progress-based messages, paused shows break copy, and arrived/completed shows arrival copy.
- The selected vehicle is shared across home, vehicle selector, timer road view, result media, and avatar rendering through `VehicleDefinition`.
- Vehicle course visuals are selected through `VehicleCourseKind`, so airplanes and pteranodons use sky styling, sharks use water styling, trains use rail styling, and other vehicles use road styling.
- Activity markers are previewed or selected before a ride and expanded into repeated course slots by `ActivityMarkerCatalog`.
- Custom avatar images are stored per vehicle, so multiple vehicle tiles can keep their own custom avatar previews.
- User-facing guide and help copy should stay synchronized with actual timer, marker, motivation, and reward rules.
- Settings, activity progress, sticker inventory, reward goals, and avatar config are stored locally with `SharedPreferences`.
- First-run onboarding state is stored locally; existing users with a saved child name skip onboarding by default.
- Motivation video paths and voice paths should be registered through `MotivationAssetCatalog`.
- Vehicle and sticker assets should keep consistent canvas size, padding, and visual scale when adding new artwork.
- UI polish should use the shared design tokens in `lib/theme/` and reusable app widgets in `lib/widgets/app/`.
- Launcher icon assets live under `assets/icons/`; regenerate platform icons with `dart run flutter_launcher_icons` after changing them.

## Status

This is an active Flutter prototype with a polished kid-friendly UI. Core flows are covered by focused unit and widget tests, including first launch, home actions, vehicle selection, custom avatars, active timer restore, timer copy, course progress, motivation media catalogs, localization fallback, stickers, and reward persistence.
