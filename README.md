# Yamyam Rider

Yamyam Rider is a playful Flutter meal-timer app that turns eating into a small ride. Pick a meal course, watch the rider move along the road, pause when needed, and finish the session with a friendly reward screen.

The app is designed around a simple idea: make mealtime pacing feel less like staring at a countdown and more like following a tiny journey.

## Highlights

- Preset meal courses for 15, 25, and 35 minutes
- Custom meal duration from 5 to 60 minutes
- Animated rider progress on a curved road
- Pause, resume, and complete controls during a meal session
- Optional remaining-time display
- Local settings persistence with `shared_preferences`
- Completion result screen with encouraging feedback and reward stickers
- Custom launcher icon and bundled rider artwork

## App Flow

1. Choose a preset course or set a custom meal duration.
2. Start the ride and follow the rider's progress along the road.
3. Pause or resume the session whenever needed.
4. Complete the meal to see whether you finished before the rider arrived.
5. Restart the same course or return home for another ride.

## Tech Stack

- Flutter
- Dart
- Material 3
- `shared_preferences` for local configuration
- `flutter_launcher_icons` for app icon generation

## Project Structure

```text
lib/
  app.dart                         # App theme and root configuration
  main.dart                        # App bootstrap and settings loading
  controllers/
    meal_timer_controller.dart     # Timer state, progress, pause/resume logic
  models/
    meal_session_result.dart       # Completed session result data
    meal_timer_config.dart         # Meal timer preferences
  screens/
    home_screen.dart               # Course selection and custom duration
    timer_screen.dart              # Active meal ride experience
    result_screen.dart             # Completion feedback
    settings_screen.dart           # Timer and display settings
  services/
    local_settings_service.dart    # SharedPreferences wrapper
  utils/
    duration_format.dart           # Duration display helper
  widgets/
    road_view.dart                 # Rider placement along the road path
    road_painter.dart              # Curved road drawing
    motorcycle_widget.dart         # Animated rider asset
    meal_message_card.dart         # Progress message surface
    timer_control_bar.dart         # Pause/resume and complete controls

assets/
  images/                          # App icon and rider artwork
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

## Development Notes

- The timer calculates elapsed time from wall-clock timestamps, so progress stays accurate even if frame or ticker timing varies.
- Settings are stored locally and loaded before the app starts.
- Sound and keep-screen-awake options are currently persisted as settings, but their runtime behavior is intentionally left for a later iteration.

## Status

This is an early Flutter app focused on the core mealtime ride experience: selecting a duration, tracking progress, and celebrating completion.
