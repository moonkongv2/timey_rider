# Course Preview Audio Implementation Plan

## Implementation Status

- Implemented through Commit 5.
- Manual simulator QA has been completed by the user.
- Final verification passed:
  - `flutter test test/widget_test.dart --plain-name "Timer audio"`
  - `flutter test test/widget_test.dart --plain-name "TimerScreen"`
  - `flutter analyze`

## Repo Fit Summary

- The preview audio assets are tracked and registered:
  - `assets/audio/course_loading.mp3`
  - `assets/audio/ready_start_beep_02.mp3`
- Runtime timer audio is centralized in:
  - `lib/catalogs/timer_audio_asset_catalog.dart`
  - `lib/services/timer_audio_service.dart`
- Startup preview orchestration lives in `TimerScreen._startPreviewSequence()` in `lib/screens/timer_screen.dart`.
- Timer audio tests currently live in `test/widget_test.dart`; there is no separate `test/timer_audio_asset_catalog_test.dart` or `test/timer_audio_lifecycle_test.dart` in this repo.
- Keep this implementation scoped to startup preview audio. Do not add audio to the manual course overview flow.

## Current Audio Timing

- `assets/audio/course_loading.mp3`: 6.576 seconds.
- `assets/audio/ready_start_beep_02.mp3`: 1.533958 seconds.
- Current startup sequence:
  - Course preview animation for timers longer than 5 minutes: about 4.7 seconds.
  - Ready message: currently 700 ms; update to 770 ms.
  - Go message: currently 700 ms; update to 770 ms.
  - Ready + Go total after implementation: 1.54 seconds.

The current `ready_start_beep_02.mp3` length fits a 770 ms Ready + 770 ms Go sequence, so the startup preview message delays should be updated from 700 ms to 770 ms.

## Commit 1: Register Preview Audio Assets

- Add exact asset paths to `pubspec.yaml`:
  - `assets/audio/course_loading.mp3`
  - `assets/audio/ready_start_beep_02.mp3`
- Add catalog constants in `TimerAudioAssetCatalog`:
  - `courseLoadingPath`
  - `readyStartBeepPath`
  - `courseLoadingVolume`
  - `readyStartBeepVolume`
- Include both new paths in `TimerAudioAssetCatalog.runtimeAssetPaths`.
- Extend the existing timer audio catalog tests in `test/widget_test.dart` to verify both files exist and both paths are registered in `pubspec.yaml`.
- Update the playable-file validation in `test/widget_test.dart` so the top-level preview audio files are treated as intentional runtime audio, while license/evidence files remain excluded.
- Verification:
  - `flutter test test/widget_test.dart --plain-name "Timer audio"`

## Commit 2: Add Preview Audio APIs

- Add preview audio methods to `TimerAudioService`:
  - `playCourseLoading()`
  - `stopCourseLoading()`
  - `playReadyStartBeep()`
  - `stopReadyStartBeep()`
- Implement no-op methods in `NoOpTimerAudioService`.
- Add dedicated players in `AudioplayersTimerAudioService`:
  - `_courseLoadingPlayer`
  - `_readyStartBeepPlayer`
- Play `course_loading.mp3` as one-shot audio with `PlayerMode.mediaPlayer` because it is a 6.576 second asset.
- Play `ready_start_beep_02.mp3` as one-shot audio with `PlayerMode.lowLatency`, matching marker SFX behavior.
- Stop and dispose both players from `stopAll()` and `dispose()`.
- Add a `_disposed` guard in `AudioplayersTimerAudioService` so play/stop methods return without touching native players after disposal.
- Preserve the existing BGM operation queue for BGM only; preview one-shots can follow the marker SFX pattern.
- Verification:
  - `flutter test test/widget_test.dart --plain-name "Timer audio"`

## Commit 3: Wire Startup Preview Playback

- In `TimerScreen._startPreviewSequence()`, mark course loading audio active only during the long course preview animation section.
- Add a small preview-audio sync helper in `TimerScreen`, separate from `_syncTimerBgm()`, that starts/stops course loading based on:
  - startup preview mode
  - course-loading phase activity
  - `soundEnabled`
  - app lifecycle resumed state
- Stop `course_loading.mp3` immediately after the preview reverse animation completes or when startup preview is canceled.
- Play `ready_start_beep_02.mp3` once immediately before showing the Ready message.
- Change the Ready delay and Go delay from 700 ms to 770 ms each; prefer a local `const Duration(milliseconds: 770)` to avoid duplicated magic numbers.
- Stop `ready_start_beep_02.mp3` if startup preview is canceled during the Ready/Go phase.
- Stop both preview sounds before `_controller.start()` so timer BGM does not overlap.
- Do not play either preview sound for restored sessions.
- Do not play either preview sound during manual course overview after the timer has started.
- Verification:
  - `flutter test test/widget_test.dart --plain-name "TimerScreen starts timer BGM after preview finishes"`

## Commit 4: Handle Sound and Lifecycle Edges

- If sound is disabled before startup preview, do not play preview audio.
- If sound is toggled off during startup preview, stop the active preview audio.
- If sound is toggled on again during the course-loading phase, allow `course_loading.mp3` to resume.
- Do not restart `ready_start_beep_02.mp3` after it has already fired; it is a short cue tied to the Ready transition.
- On app background during startup preview, stop active preview audio.
- On foreground return, resume only the course-loading phase if it is still active.
- Keep BGM lifecycle behavior unchanged: `_syncTimerBgm()` should remain responsible only for timer BGM.
- Verification:
  - `flutter test test/widget_test.dart --plain-name "TimerScreen toggles sound and syncs timer BGM"`
  - `flutter test test/widget_test.dart --plain-name "TimerScreen syncs timer BGM with app lifecycle"`

## Commit 5: Add Focused Tests

- Extend `_FakeTimerAudioService` in `test/widget_test.dart` with preview audio call recording.
- Add tests for:
  - New 5-minute-plus timer plays course loading audio during startup preview.
  - Course loading audio stops before timer BGM starts.
  - Ready/Go beep plays once before timer start.
  - Sound disabled prevents preview audio and BGM.
  - Restored running/paused sessions do not play preview audio.
  - 5-minute-or-shorter timers skip course loading but still play Ready/Go beep.
  - Sound toggled off during startup preview stops course loading audio.
  - App background during startup preview stops course loading audio; foreground resumes only if still in the course-loading phase.
  - App background/foreground during the Ready/Go phase does not restart `ready_start_beep_02.mp3`.
- Update existing timer BGM expectations that currently assume no audio calls happen during preview.
- Verification:
  - `flutter test test/widget_test.dart --plain-name "TimerScreen"`

## Final Verification

- `dart format` changed Dart files.
- `flutter test test/widget_test.dart --plain-name "Timer audio"`.
- `flutter test test/widget_test.dart --plain-name "TimerScreen"`.
- `flutter analyze` when practical.

## Manual Check Areas

- Completed by the user:
  - Timer startup preview for durations longer than 5 minutes.
  - Timer startup for durations 5 minutes or shorter.
  - Ready/Go cue timing.
  - Transition from preview audio to timer BGM.
  - Sound off and sound toggle behavior.
  - App background/foreground during startup preview.
  - Restored session entry.
