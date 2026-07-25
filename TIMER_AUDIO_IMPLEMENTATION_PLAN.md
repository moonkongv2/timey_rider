# Timer Audio Implementation Plan

## Current Asset Validation

- BGM playable file: `assets/audio/timer_bgm/timer_bgm_01.mp3`
- Marker playable file: `assets/audio/marker/marker_01.mp3`
- Direct playable file count is valid for both runtime directories.
- `pubspec.yaml` now registers only those two exact playable timer audio files.
- Keep the current untracked audio and evidence files as commit targets.
- Ignore `.DS_Store` files for playable asset validation and do not intentionally commit them.
- Existing marker metadata already uses the `license-cleared-resource` / `not_applicable` structure. Keep unknown non-app facts as `TODO_USER`.
- Existing BGM evidence is currently split under `assets/audio/timer_bgm/_licenses/` and `assets/audio/timer_bgm/_licenses/timer_bgm_01/`; normalize it into the per-asset evidence folder during Commit 1.

## Commit 1: Audio Asset Catalog And License Metadata

- Add `lib/catalogs/timer_audio_asset_catalog.dart`.
- Catalog exact runtime paths:
  - `assets/audio/timer_bgm/timer_bgm_01.mp3`
  - `assets/audio/marker/marker_01.mp3`
- Catalog default volumes:
  - BGM: `0.22`
  - marker SFX: `0.080`
- Verify `pubspec.yaml` registers only the exact playable timer audio files:
  - `assets/audio/timer_bgm/timer_bgm_01.mp3`
  - `assets/audio/marker/marker_01.mp3`
- Do not register `assets/audio/timer_bgm/`, `assets/audio/marker/`, `_licenses`, metadata, PDFs, certificates, screenshots, or original source files as Flutter assets.
- Add `assets/audio/README.md` only as asset governance documentation:
  - explain which files are runtime Flutter assets
  - explain that `_licenses`, metadata, PDFs, certificates, screenshots, and originals are evidence files only
  - state that evidence files must not be registered as Flutter assets
  - this README is not needed for runtime playback
- Ensure per-asset metadata/evidence layout:

```text
assets/audio/
├── README.md
├── timer_bgm/
│   ├── timer_bgm_01.mp3
│   └── _licenses/
│       └── timer_bgm_01/
│           ├── README.md
│           ├── metadata.yaml
│           ├── Content_License_Pixabay.pdf
│           └── electronic-cute-happy-kids-481995-license.txt
└── marker/
    ├── marker_01.mp3
    └── _licenses/
        └── marker_01/
            ├── README.md
            └── metadata.yaml
```

- Preserve real BGM evidence files.
- Do not fabricate missing BGM source/license facts; leave unverified fields as `TODO_USER`.
- Keep marker metadata as license-cleared-resource unless the user later provides real source evidence.

## Commit 2: Dedicated Timer Audio Service

- Add `lib/services/timer_audio_service.dart`.
- Do not reuse `MotivationAudioService`.
- Define injectable `TimerAudioService` with:
  - `startOrResumeBgm`
  - `pauseBgm`
  - `stopBgm`
  - `playMarkerSfx`
  - `stopAll`
  - `dispose`
- Provide `NoopTimerAudioService` for tests and unavailable paths.
- Implement `AudioplayersTimerAudioService` using two separate `AudioPlayer` instances:
  - BGM player: `PlayerMode.mediaPlayer`, `ReleaseMode.loop`
  - marker player: `PlayerMode.lowLatency`, `ReleaseMode.stop`
- Use the same normalized asset path convention as `MotivationAudioService`: strip the `assets/` prefix before passing to `AssetSource`.
- Use an explicit audio context matching the existing motivation voice policy unless the product decision changes:
  - `AudioContextConfig(focus: AudioContextConfigFocus.gain, respectSilence: false).build()`
  - pass the context to both BGM and marker playback so iOS silent-switch behavior is consistent with existing app audio
- Keep BGM state transitions idempotent and race-resistant.
- Catch and log playback failures with `debugPrint`; never interrupt timer flow or rethrow from timer audio methods.
- Do not change the existing motivation media or motivation voice service.

## Commit 3: Activity Timer BGM Lifecycle Integration

- Add optional `TimerAudioService? timerAudioService` injection to `TimerScreen`.
- `TimerScreen` should dispose only a production timer audio service it creates itself.
- Add local BGM state tracking in `TimerScreen`, following current TimerScreen style rather than introducing unrelated lifecycle refactors.
- Add one centralized BGM synchronization helper, for example `_syncTimerBgm()`, and call it from all state-transition points instead of scattering direct `startOrResumeBgm`, `pauseBgm`, and `stopBgm` calls.
- `_syncTimerBgm()` should derive the desired audio state from current timer state and local UI state:
  - stop when sound is disabled, arrived, completed, finish-drive is active, preview is active, active session is finalized, or screen is disposing
  - pause when `ActivityTimerState.paused`
  - pause when the app is inactive, hidden, paused, or detached
  - play/resume only when `ActivityTimerState.running`, sound is enabled, preview is inactive, finish-drive is inactive, and the app is resumed
- Track the last applied BGM target state so repeated timer ticks do not repeatedly call the audio service.
- BGM behavior:
  - no BGM during the preview sequence
  - start after `_controller.start()` when the real timer begins
  - start for restored running sessions only when sound is enabled
  - do not start for restored paused, arrived, completed, preview, finish-drive, or sound-disabled states
  - pause when the activity timer pauses
  - resume from the current BGM position when the activity timer resumes
  - pause on app inactive, hidden, paused, or detached
  - resume on app resumed only when the timer is actively running and sound is enabled
  - stop on arrival, manual completion, finish-drive start, confirmed exit, active session finalization, sound disabled, and dispose
- Required call sites for `_syncTimerBgm()`:
  - after `_controller.start()` in the preview sequence
  - after pause/resume actions
  - in `_handleTimerChanged()` after timer state changes are observed
  - in `didChangeAppLifecycleState`
  - after restored-session initialization
  - after runtime sound toggle
  - before route removal or result navigation when the timer is finalized
  - in `dispose`
- Preserve activity timing, completion, persistence, result, orientation, screen-awake, and motivation scheduling behavior.

## Commit 3.5: Fix Active Timer Clear Race On Confirmed Exit

- Carry over the intermediate Yamyam bugfix because Timey has the same risk pattern.
- Current Timey `_confirmExit()` clears the active session with `unawaited(_clearActiveSession())` before removing the timer route.
- Change confirmed exit flow so the active session clear completes before the route is removed.
- Stop timer audio before route removal through the centralized BGM sync/stop path.
- Keep timer audio stop non-fatal; audio failures must be logged by `TimerAudioService` and must not prevent route removal.
- Add focused regression coverage with a delayed active session store:
  - route should not be removed before `clear()` completes
  - active timer card should not survive after confirmed exit
- Do not change home active-session display behavior beyond fixing this race.

## Commit 4: Course Marker SFX Integration

- Add `ValueChanged<int>? onCourseMarkerPassed` to `RoadView`.
- Use existing `_markerSlotProgress(...)` values for marker crossing detection.
- Do not duplicate an approximate marker formula in `TimerScreen`.
- Refactor `_RoadMarkerLayer` to stateful as needed.
- Required callback behavior:
  - fires when `markerClearProgress` moves from below a marker progress to at or above it
  - rebuilding at the same progress does not fire again
  - initial mount at advanced progress does not replay old markers
  - remount or orientation reconstruction at advanced progress does not replay old markers
  - restored timer at advanced progress does not replay old markers
  - jumping across several markers emits at most one callback, using the highest newly crossed index
  - no callback for the start marker or finish star
  - no callback during preview
- Add parent-side duplicate protection in `TimerScreen` with a highest-handled marker index.
- Initialize the parent-side highest-handled marker index from the current `markerClearProgress` / visible marker slots when the timer is restored or mounted at advanced progress, so old cleared markers are treated as already handled in memory.
- On a new marker crossing, mark all indices up to that index as handled and play only one marker SFX when:
  - `soundEnabled` is true
  - `ActivityTimerState.running`
  - app lifecycle state is resumed
  - screen is mounted
  - preview is inactive
  - finish-drive is inactive
- Do not persist marker-audio history; derive old cleared markers from current progress and guard in memory.

## Commit 4.5: Runtime Sound Toggle During Timer

- Carry over the intermediate Yamyam feature because Timey should support sound on/off during an active timer.
- Use only the existing `soundEnabled` setting.
- Do not introduce a second sound setting.
- Add `timerSoundToggleButton` to:
  - portrait app bar
  - full landscape top controls
  - compact landscape controls
- Toggle behavior:
  - update `_timerConfig.copyWith(soundEnabled: enabled)`
  - call `widget.onConfigChanged(nextConfig)`
  - persist the active timer session
  - call the centralized BGM sync helper immediately
  - sound off stops BGM
  - sound on resumes BGM only if the timer is actively running
- The same setting must gate timer BGM, marker SFX, and future motivation voice.

## Commit 5: Sound Setting Localization

- Update `soundEnabled` label/subtitle in every supported locale:
  - Korean
  - English
  - Japanese
  - Spanish
  - Brazilian Portuguese
- Make the copy cover timer music, marker effects, and future motivation voice.
- Update motivation help bullet copy where it currently says only sound effects and video settings are separate.
- Keep the existing localization system; do not hardcode UI text.

## Commit 6: Tests And Documentation

- Add focused tests that do not use real platform audio playback.
- Add fake `TimerAudioService` tests for:
  - sound disabled prevents BGM start
  - fresh session starts BGM only after preview and actual timer start
  - pause pauses BGM
  - resume resumes BGM without creating another service
  - arrival stops BGM
  - manual/early completion stops BGM
  - confirmed exit stops BGM and waits for active-session clear
  - dispose stops owned timer audio resources
  - restored running session starts BGM
  - restored paused session does not start BGM
  - lifecycle background pauses and foreground resumes only when appropriate
  - repeated timer updates do not repeatedly start BGM
  - runtime sound toggle stops/restarts BGM and persists `soundEnabled`
  - audio service failures are swallowed/logged and do not block timer navigation or completion
- Add `RoadView` marker crossing tests for:
  - one marker crossing emits one callback and one SFX path from TimerScreen coverage
  - same marker does not replay on rebuild
  - initial advanced progress does not replay old markers
  - remount/orientation-like reconstruction does not replay old markers
  - jump across multiple markers emits only the highest index
  - paused, sound-disabled, preview, and finish-drive marker crossings do not play SFX
- Add asset/metadata validation tests for:
  - catalog paths match registered assets
  - runtime files exist
  - `_licenses` content is not referenced as Flutter assets
  - metadata points at the catalog runtime asset paths
  - `.DS_Store` files are ignored by playable asset validation
- Update `README.md` with:
  - BGM and marker SFX behavior
  - use of the existing sound setting
  - `assets/audio` layout
  - license evidence storage
  - motivation media remaining separately feature-gated
- Verification commands:
  - `flutter pub get`
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- If full `flutter test` fails, report whether failures are existing/unrelated or introduced by the timer audio work.

## Suggested Commit Split

1. `Add timer audio asset catalog and license metadata`
2. `Add dedicated timer audio service`
3. `Wire activity timer BGM lifecycle`
4. `Fix active timer clear before exit`
5. `Play marker SFX on visible course marker crossings`
6. `Allow sound toggle during timer`
7. `Update sound setting copy for timer audio`
8. `Add timer audio tests and documentation`

## Manual QA Checklist

- Android: BGM loop, pause/resume, marker overlap, exit and completion
- iOS: BGM loop, pause/resume, silent-switch behavior under the existing audio context
- BGM and marker SFX can play simultaneously
- No marker SFX duplication after rotation
- No old marker sound after restoring a session
- No BGM during preview
- No BGM or marker SFX when sound is disabled
- No burst of effects after a large progress jump
- The BGM loop boundary is acceptable on both platforms
- License documents are not included in the app bundle
