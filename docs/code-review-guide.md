# Timey Rider Code Review Guide

This guide is for reviewers who are new to this codebase. Use it to build enough context before reviewing a change, then focus the review on behavior, persistence, UI flow, localization, and tests.

## Product Context

Timey Rider is a kid-friendly Flutter routine timer. A child chooses an activity and vehicle, the vehicle moves along a course while the timer runs, and completed sessions can award stickers toward reward goals.

The app is local-first. Settings, active timer sessions, history, sticker inventory, and reward goals are stored with `shared_preferences`. There is no backend in the current architecture.

## Start Here

Read these files first for most reviews:

- `lib/main.dart`: service creation and app bootstrap.
- `lib/app.dart`: initial routing, onboarding, child name setup, app-level config persistence, and purchase entitlement fallback.
- `lib/screens/home_screen.dart`: activity selection, presets, active timer resume/cancel, vehicle pack entry points, and navigation into the timer.
- `lib/screens/timer_screen.dart`: timer lifecycle, active session persistence, motivation media, orientation, and completion flow.
- `lib/screens/result_screen.dart`: result recording, sticker choice, success/failure media, and reward goal updates.
- `lib/controllers/activity_timer_controller.dart`: timer state machine and elapsed time calculation.
- `lib/models/activity_timer_config.dart`: shared config object passed across screens and persisted by settings.

For data definitions, check:

- `lib/catalogs/activity_catalog.dart`: built-in activities and default durations.
- `lib/catalogs/vehicle_catalog.dart`: vehicle assets, labels, avatar slots, and course kinds.
- `lib/catalogs/activity_marker_catalog.dart`: marker definitions and course marker generation.
- `lib/catalogs/motivation_asset_catalog.dart`: motivation video and voice asset selection.
- `lib/catalogs/timer_audio_asset_catalog.dart`: timer BGM, marker, preview, and finish audio paths.
- `lib/catalogs/result_audio_asset_catalog.dart`: result screen audio paths.
- `lib/catalogs/vehicle_unlock_catalog.dart`: free vehicles, locked vehicles, and the vehicle pack product id.

## Main Runtime Flow

The normal app flow is:

1. `main.dart` loads `LocalSettingsService`, `LocalActivityProgressService`, `ActiveActivityTimerSessionStore`, and the cached vehicle pack entitlement.
2. `TimeyRiderApp` decides whether to show splash, onboarding, child name setup, or home, applying a free-vehicle fallback if a saved vehicle is still locked.
3. `HomeScreen` builds a timer config from the selected activity, duration, vehicle, and marker choices.
4. `TimerScreen` starts or restores an `ActivityTimerController`.
5. `TimerScreen` continuously saves an `ActiveActivityTimerSession` so the timer can be resumed later.
6. When the timer completes, `TimerScreen` creates an `ActivitySessionResult` and opens `ResultScreen`.
7. `ResultScreen` records the result through `LocalActivityProgressService`.
8. `LocalActivityProgressService` updates history, sticker inventory, and reward goals.

When reviewing a change, identify where it lands in this flow and check the upstream and downstream assumptions.

## State And Persistence

Most durable state is stored in `shared_preferences`.

- `LocalSettingsService` persists app settings, child name, selected vehicle, sound/video options, marker mode, and avatar settings.
- `ActiveActivityTimerSessionStore` persists the currently running or paused timer as JSON.
- `LocalActivityProgressService` persists activity history, sticker inventory, active reward goals, earned reward goals, and used reward goals.
- `LocalRecentTimerService` and `LocalSavedTimerPresetService` persist timer presets.
- `LocalAvatarImageService` handles imported avatar image storage and normalization.
- `LocalPurchaseEntitlementStore` persists the cached vehicle pack entitlement.

Review persistence changes carefully:

- Preserve backward compatibility for existing keys unless the change intentionally migrates them.
- Keep malformed JSON handling defensive. Existing services usually ignore bad local data instead of crashing.
- Check whether model `toJson` and `fromJson` evolve together.
- Check whether default values still match `ActivityTimerConfig.defaults()`.
- Check whether tests cover missing fields, old fields, and invalid values.

## Timer Behavior

`ActivityTimerController` is intentionally wall-clock based. The periodic ticker refreshes UI, but elapsed time is derived from `DateTime` differences. This avoids drift if frames or timer ticks are delayed.

Important states:

- `idle`: not started.
- `running`: active countdown.
- `paused`: elapsed time is frozen and pause duration is tracked.
- `arrived`: target duration has been reached but completion handling may still be pending.
- `completed`: final result has been created.

Review timer changes for:

- pause and resume correctness;
- restored session correctness;
- elapsed time clamping at zero;
- arrival behavior for different activity completion modes;
- active session clearing after a recorded completion;
- lifecycle handling when the app is paused or resumed;
- timer audio cleanup and one-shot cues for preview, ready/start, markers, finish drive, and arrival.

## Activities, Markers, Vehicles

Activities and vehicles are static catalogs, so changes usually need matching assets, tests, and localized copy.

For a new or changed activity, check:

- `ActivityCatalog` has a stable id, labels for every supported locale, emoji, default duration, preset durations, completion mode, reward default, and marker ids.
- Marker ids exist in `ActivityMarkerCatalog`.
- Tests cover catalog lookup and fallback behavior if relevant.

For a new or changed vehicle, check:

- `VehicleCatalog` has correct `assetPath`, `selectionAssetPath`, label copy for every supported locale, avatar slot, road anchor offset if needed, and course kind.
- Result video and motivation media fallbacks remain valid.
- Reward sticker lookup still works.
- Vehicle pack locking still matches `VehicleUnlockCatalog`.
- Widget tests or focused rendering tests cover avatar and vehicle presentation when behavior changes.

## Purchases And Parent Gate

The vehicle pack is a client-only, non-consumable purchase. The app caches a
local entitlement and relies on store restore for recovery across reinstall or
device changes.

Key files:

- `lib/catalogs/vehicle_unlock_catalog.dart`
- `lib/models/purchase_entitlement.dart`
- `lib/services/iap_purchase_client.dart`
- `lib/services/local_purchase_entitlement_store.dart`
- `lib/services/vehicle_pack_purchase_controller.dart`
- `lib/widgets/purchase/parent_gate_sheet.dart`
- `lib/widgets/purchase/vehicle_pack_info_sheet.dart`
- `lib/widgets/purchase/vehicle_pack_purchase_sheet.dart`
- `docs/iap-release-setup.md`

Review checks:

- Locked vehicles remain visible but cannot be selected before entitlement.
- Purchase and restore entry points remain behind the parent gate.
- The pre-gate info sheet does not expose direct purchase or price wording.
- Successful purchase or restore unlocks all locked vehicles and preserves the intended selection when applicable.
- Failed, canceled, pending, unavailable, and not-found restore states do not corrupt local config.
- Saved locked vehicle ids fall back to a free vehicle until entitlement is restored without overwriting the saved premium choice.
- Product id changes stay synchronized with store setup docs and tests.

## Motivation Media

Motivation videos and voice clips are selected during the timer.

Key files:

- `lib/screens/timer_screen.dart`
- `lib/utils/motivation_video_schedule.dart`
- `lib/catalogs/motivation_asset_catalog.dart`
- `lib/services/motivation_audio_service.dart`

Review checks:

- Sound disabled should suppress voice playback.
- Video disabled should suppress motivation video scheduling.
- Progress milestones should not repeat within one session.
- Timed schedules should behave correctly for long timers and custom intervals.
- Restored sessions should preserve already shown milestones and last shown time.
- Asset fallback paths should remain valid.

## UI And Navigation

The core navigation is direct `MaterialPageRoute` usage rather than a central router. The app also uses `appRouteObserver` so `HomeScreen` refreshes when returning from child routes.

Review UI changes for:

- portrait and landscape behavior in `TimerScreen`;
- orientation handoff between timer and result screens;
- text overflow on small devices;
- button availability and dialog cancel paths;
- active session prompts before starting a new timer;
- avoiding regressions in onboarding and child name setup.

Reusable UI primitives live under `lib/widgets/app/` and visual tokens live under `lib/theme/`. Prefer existing tokens and components over one-off styling.

## Localization

Localization is custom, not generated ARB-based localization.

Key files:

- `lib/l10n/app_texts.dart`
- `lib/l10n/text_sets.dart`
- `lib/l10n/en/`
- `lib/l10n/ko/`
- `lib/l10n/ja/`
- `lib/l10n/es/`
- `lib/l10n/pt_BR/`

When a change adds user-facing text:

- Add it to the appropriate text set interface in `text_sets.dart`.
- Implement every supported locale: English, Korean, Japanese, Spanish, and Brazilian Portuguese.
- For catalog labels, update every localized label field such as `labelKo`, `labelEn`, `labelJa`, `labelEs`, and `labelPtBr`.
- Avoid embedding display strings directly in screens unless the surrounding file already treats the value as non-localized test/debug copy.
- Check widget tests that assert exact text.
- Check `test/localization_support_test.dart` for broad locale coverage.

## Rewards And History

`LocalActivityProgressService.recordActivityResult` is the main write path for completed sessions.

Review reward/history changes for:

- completed vs incomplete status behavior;
- whether a sticker should be awarded for each `ActivityCompletionStatus`;
- reward goal slot filling and transition from active to earned;
- inventory count increments;
- history ordering, deletion, and selected marker persistence;
- migration fallback from older `meal*` keys where still relevant.

## Avatar Flow

Avatar behavior is per vehicle and has legacy single-avatar compatibility.

Important files:

- `lib/models/activity_timer_config.dart`
- `lib/services/local_settings_service.dart`
- `lib/services/local_avatar_image_service.dart`
- `lib/screens/avatar_setup_screen.dart`
- `lib/widgets/avatar/avatar_composite_preview.dart`
- `lib/widgets/vehicle_widget.dart`
- `lib/widgets/vehicle_selection_card.dart`

Review checks:

- Custom avatars should only apply to the vehicle they were configured for.
- Missing local files should fall back safely.
- Scale, offset, and rotation should persist and reload.
- Legacy avatar fields should continue to migrate into the per-vehicle map.

## Test Selection

Run the smallest meaningful test set for the change, then broaden if the change crosses boundaries.

Common commands:

```bash
flutter analyze
flutter test
```

Focused test choices:

- Timer math or restore behavior: `flutter test test/activity_timer_controller_test.dart`
- Active session persistence: `flutter test test/active_activity_timer_session_store_test.dart`
- Settings persistence: `flutter test test/local_settings_service_test.dart test/local_settings_service_onboarding_test.dart`
- Activity or marker catalog changes: `flutter test test/activity_domain_test.dart test/activity_marker_catalog_test.dart`
- Timer preset changes: `flutter test test/activity_timer_preset_test.dart test/local_recent_timer_service_test.dart test/local_saved_timer_preset_service_test.dart`
- Avatar changes: `flutter test test/local_avatar_image_service_test.dart test/avatar_composite_preview_test.dart test/vehicle_avatar_presentation_test.dart`
- Localization changes: `flutter test test/localization_support_test.dart`
- Purchase or locked vehicle changes: `flutter test test/app_purchase_entitlement_test.dart test/vehicle_pack_purchase_controller_test.dart test/vehicle_pack_purchase_sheet_test.dart test/parent_gate_sheet_test.dart test/iap_purchase_client_test.dart test/local_purchase_entitlement_store_test.dart`
- Onboarding and app-level flow: `flutter test test/onboarding_screen_test.dart test/app_onboarding_flow_test.dart`
- Broad UI behavior: `flutter test test/widget_test.dart`

If a test cannot run because of missing local tooling, simulator availability, or asset issues, report the command, failure reason, and likely scope.

## High-Risk Review Areas

Prioritize review attention when a change touches:

- `TimerScreen`, because it combines timer state, persistence, media playback, orientation, navigation, and dialogs.
- `ActivityTimerConfig`, because it is shared across many screens and persisted in multiple forms.
- `LocalActivityProgressService`, because result recording updates several pieces of state at once.
- `LocalSettingsService`, because settings changes can affect existing users after app upgrade.
- `VehiclePackPurchaseController`, `IapPurchaseClient`, and `VehicleUnlockCatalog`, because purchase state affects vehicle selection, settings, avatar setup, and restore behavior.
- vehicle or activity ids, because ids are persisted and referenced by catalogs, rewards, media, tests, and history.
- localization interfaces, because adding a getter requires every supported locale implementation.
- asset paths, because missing assets usually fail at runtime rather than compile time.

## Review Checklist

Use this short checklist before approving:

- The change is scoped to the requested behavior.
- Existing app flow still works from home to timer to result.
- Persisted models handle old and missing data safely.
- Timer pause, resume, restore, arrival, and completion behavior still make sense.
- User-facing text is localized in every supported language.
- Asset paths match files under `assets/` and `pubspec.yaml`.
- Parent-gated purchase, restore, support, and privacy entry points stay gated where required.
- UI handles small screens and both timer orientations where relevant.
- Tests cover the behavior or the risk is explicitly low.
- `flutter analyze` and relevant `flutter test` commands were run or the reason they were not run is documented.
