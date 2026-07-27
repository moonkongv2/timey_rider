# Finish And Result Audio Implementation Plan

## Overview

This plan applies the finish-drive, arrival, success-result, and sticker-collect
audio behavior from `jy_yamyam` to `timey_rider`.

The target repo already has the main visual flow needed for this feature:

- `TimerScreen._startFinishDrive()` animates the vehicle to the destination when
  an activity is completed before the planned end.
- `finishDriveDurationForProgress()` calculates the remaining finish-drive
  animation duration from the current course progress.
- Timer audio is centralized in:
  - `lib/catalogs/timer_audio_asset_catalog.dart`
  - `lib/services/timer_audio_service.dart`
- `ResultScreen` may show a sticker-choice screen before recording the result.
- A success intro video is created only after the result is recorded with a
  sticker reward.
- `FlyingStickerAnimation` already reports when the awarded sticker reaches the
  sticker album button.
- `sticker_fountain_animation.dart` separately plays `sticker_popup.mp3` for
  album-sheet sticker preview. This plan does not change that behavior.
- The required new audio files are not currently present in `timey_rider`; copy
  or otherwise provide them before registering them as Flutter assets.

## Agreed Behavior

- If `finishDriveDuration < 1.5s`, skip the finish-drive SFX and only play the
  arrival SFX.
- If `1.5s <= finishDriveDuration < 2.5s`, play
  `assets/audio/final_drive_short.mp3`.
- If `finishDriveDuration >= 2.5s`, play
  `assets/audio/final_drive_long.mp3`.
- When the finish-drive animation completes, stop any drive SFX before playing
  the arrival SFX.
- Play `assets/audio/finish_arrival.mp3`, keep the arrived screen visible for
  about 1 second, then transition to the result screen.
- Use `assets/audio/crowd_cheering.mp3` only for the success result intro video.
- Use `assets/audio/sticker_collect.mp3` only when the awarded sticker lands in
  the sticker album button.
- Do not add a separate sticker reveal sound.
- Honor `ActivityTimerConfig.soundEnabled` for all newly added audio.
- Stop newly added in-flight audio when the app leaves the resumed lifecycle
  state, unless a later product decision explicitly allows background playback.
- Do not add arrival SFX or an extra arrival hold to already-arrived
  acknowledgement flows unless manual product QA later asks for it. Those flows
  already show the arrived UI before the user confirms completion.

## Repo Fit Notes

- Target activity states are activity-based:
  - `ActivityTimerState.running`
  - `ActivityTimerState.paused`
  - `ActivityTimerState.arrived`
  - `ActivityTimerState.completed`
- Completed-before-end uses the fast finish-drive animation and is the primary
  place for drive SFX and arrival SFX.
- Completed-at-end, completed-after-end, time-ended, and needs-more-time flows
  pass through the arrival panel or result screen without fast finish-drive.
- Result success audio must be tied to the actual intro-video playback, not to
  the initial `ResultScreen` mount, because the user may need to choose whether
  to receive a sticker first.
- Result audio ownership should be centralized in a result audio service instead
  of adding raw `AudioPlayer` ownership directly to multiple widgets. The
  production result audio service should use separate players for cheering and
  sticker collection so stop/dispose behavior stays explicit even if future UI
  changes allow overlap.
- Existing timer and result tests live mostly in `test/widget_test.dart`; keep
  the new tests there unless the repo is later split into focused test files.

## Commit 1: Register Finish And Result Audio Assets

- Add exact asset entries to `pubspec.yaml`:
  - `assets/audio/final_drive_short.mp3`
  - `assets/audio/final_drive_long.mp3`
  - `assets/audio/finish_arrival.mp3`
  - `assets/audio/crowd_cheering.mp3`
  - `assets/audio/sticker_collect.mp3`
- Copy or provide those exact files under `assets/audio/` before registration.
  Do not register placeholder paths; asset validation should fail if any file is
  missing.
- Add finish-drive and arrival constants to `TimerAudioAssetCatalog`:
  - `finishDriveShortAssetPath`
  - `finishDriveLongAssetPath`
  - `finishArrivalAssetPath`
  - `finishDriveVolume`
  - `finishArrivalVolume`
- Include timer finish audio paths in `TimerAudioAssetCatalog.runtimeAssetPaths`.
- Add `lib/catalogs/result_audio_asset_catalog.dart` for:
  - `crowdCheeringAssetPath`
  - `stickerCollectAssetPath`
  - result-audio volumes
  - result runtime asset paths, if useful for tests
- Update `test/widget_test.dart` asset validation:
  - runtime audio files exist
  - exact runtime paths are registered in `pubspec.yaml`
  - `_licenses`, metadata, PDFs, and directories are not registered as Flutter
    assets
  - top-level finish/result audio files are treated as intentional runtime audio

Verification:

- `flutter test test/widget_test.dart --plain-name "Timer audio"`

## Commit 2: Extend Timer Audio Service

- Add finish audio APIs to `TimerAudioService`:
  - `playFinishDriveShortSfx()`
  - `playFinishDriveLongSfx()`
  - `stopFinishDriveSfx()`
  - `playFinishArrivalSfx()`
- Implement no-op methods in `NoopTimerAudioService`.
- Add dedicated players in `AudioplayersTimerAudioService`:
  - `_finishDrivePlayer`
  - `_finishArrivalPlayer`
- Play finish-drive SFX as one-shot audio.
- Play arrival SFX as a short one-shot cue.
- Stop both new players from `stopAll()`.
- Stop and dispose both new players from `dispose()`.
- Keep playback failures non-fatal: catch, `debugPrint`, and do not block timer
  completion or navigation.
- Preserve the existing BGM operation queue for BGM only.

Verification:

- `flutter test test/widget_test.dart --plain-name "Timer audio"`

## Commit 3: Wire Finish-Drive Playback

- In `TimerScreen._startFinishDrive()`:
  - compute `finishDriveDuration` once
  - keep the existing animation duration based on that value
  - choose no/short/long drive SFX from the agreed thresholds
  - play drive SFX only when `soundEnabled` is true and the app is resumed
- On finish-drive animation completion:
  - stop finish-drive SFX
  - play arrival SFX when `soundEnabled` is true and the app is resumed
  - hold the arrived screen for about 1 second
  - open the result screen afterward
- Guard async completion with:
  - `mounted`
  - `_isFinishDriving`
  - `_pendingFinishDriveResult`
  - the same pending result still being current after the 1 second hold
- Keep existing direct result navigation for already-arrived acknowledgement
  flows.
- Stop finish-drive SFX when:
  - the app lifecycle changes away from `AppLifecycleState.resumed`
  - the sound toggle is turned off during finish-drive
  - the timer screen is disposed
  - `TimerAudioService.stopAll()` is called
- Do not replay finish-drive SFX after the app resumes mid-animation; only the
  arrival SFX may play at animation completion if the app is resumed and sound
  is enabled at that time.

Verification:

- Focused `TimerScreen` tests for early completion and finish-drive timing.
- Focused lifecycle/sound-toggle tests for stopping finish-drive SFX without
  replaying it on resume.

## Commit 4: Add Result Audio Service And Success Cheering

- Add `lib/services/result_audio_service.dart`.
- Define injectable `ResultAudioService`:
  - `playCrowdCheering()`
  - `playStickerCollect()`
  - `stop()`
  - `dispose()`
- Provide no-op and audioplayers implementations.
- Add optional `ResultAudioService? resultAudioService` to `ResultScreen`.
- `ResultScreen` should dispose only the production result audio service it
  creates itself; injected test services should be stopped but not disposed.
- Play `crowd_cheering.mp3` only after the success intro video initializes and
  starts playback.
- Gate cheering with `widget.config.soundEnabled`.
- Track `AppLifecycleState` in `ResultScreen` so result audio can honor the same
  resumed-only policy as timer finish audio.
- Stop cheering from the intro-video listener at the same point that
  `_introFinished` becomes true.
- Stop cheering when the app lifecycle changes away from
  `AppLifecycleState.resumed`. Do not automatically replay cheering on resume;
  the cue is tied to the intro start, and a late replay would no longer match
  the video moment.
- If the product requirement is to stop audio when another route covers
  `ResultScreen`, subscribe with `RouteAware` and stop audio from
  `didPushNext()`. If dispose-only behavior is sufficient, document that route
  coverage can keep the cue playing until the screen is removed.
- Do not play cheering on:
  - sticker-choice screen
  - skipped-sticker results
  - failed or needs-more-time results
  - `timeEnded` results without a sticker
  - intro-video initialization failure
- Stop result audio when:
  - the intro video reaches the end
  - intro-video initialization fails
  - the app lifecycle changes away from `AppLifecycleState.resumed`
  - the widget is disposed
  - the route is replaced or left
  - another route is pushed above `ResultScreen`, if the `RouteAware`
    requirement is adopted

Verification:

- Focused `ResultScreen` tests for success intro audio start/stop and sound-off
  suppression.

## Commit 5: Add Sticker Collect Audio

- Reuse `ResultAudioService.playStickerCollect()`.
- In `ResultScreen`, play `sticker_collect.mp3` from
  `FlyingStickerAnimation.onAnimationFinished` when:
  - the recorded result awarded a sticker
  - the flying animation has not already finished
  - `widget.config.soundEnabled` is true
  - the app is currently resumed
- Keep the central sticker reveal silent.
- Do not change `sticker_fountain_animation.dart` or `sticker_popup.mp3`; that
  sound belongs to album-sheet sticker preview.
- Keep the collect sound timing at the landing point. The current animation is
  2.5 seconds:
  - reveal/scale: about 0.0s to 0.75s
  - fly-to-album: about 1.5s to 2.5s
  - collect SFX: at animation completion

Verification:

- Focused `ResultScreen` tests for sticker collect playback, sound-off
  suppression, and no-reward suppression.

## Commit 6: Tests And Final Verification

- Extend `_FakeTimerAudioService` in `test/widget_test.dart` with finish audio
  call recording.
- Add `_FakeResultAudioService` in `test/widget_test.dart`.
- Add or update tests for:
  - finish-drive threshold behavior
  - no drive SFX under 1.5 seconds
  - short drive SFX from 1.5 seconds to under 2.5 seconds
  - long drive SFX from 2.5 seconds and above
  - sound-off suppression for drive and arrival SFX
  - drive SFX stops before arrival SFX
  - arrived screen holds for about 1 second before result navigation
  - lifecycle pause stops finish-drive SFX and resume does not replay it
  - already-arrived acknowledgement flow remains unchanged
  - cheering plays only during success intro video
  - cheering stops on video end, fallback, and dispose
  - cheering stops on lifecycle pause and does not replay on resume
  - cheering route-cover behavior matches the chosen `RouteAware` or
    dispose-only policy
  - cheering is suppressed when sound is disabled or sticker is skipped
  - sticker collect plays once when an awarded sticker lands
  - sticker collect is suppressed when sound is disabled
  - sticker collect is suppressed when the app is not resumed
  - sticker collect is not played when no sticker reward is awarded
- Run:
  - `dart format`
  - `flutter test test/widget_test.dart --plain-name "Timer audio"`
  - `flutter test test/widget_test.dart --plain-name "TimerScreen"`
  - focused `ResultScreen` tests
  - `flutter analyze`

## Manual Check Areas

- Early completion from near-finish progress.
- Early completion from mid-course progress.
- Early completion from early-course progress.
- Sound disabled during early completion.
- Backgrounding and resuming during early completion.
- Arrival SFX and 1 second arrived-screen hold before result transition.
- Completion after natural arrival through the arrival panel.
- Sticker-choice screen: receive sticker.
- Sticker-choice screen: skip sticker.
- Success intro video with cheering.
- Success intro video with sound disabled.
- Backgrounding and resuming during the success intro video.
- Success intro route replacement or route cover behavior.
- Sticker collect sound when the sticker lands in the album button.
- Result without sticker reward.
- Existing album-sheet sticker preview sound from `sticker_popup.mp3`.
