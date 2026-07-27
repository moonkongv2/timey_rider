# Settings Legal And Support Links Plan

## Goal

Update the Settings screen to place legal, support, guide, restore purchase, and app version items in commercially standard bottom sections while preserving the existing visual style and localization architecture.

## Commit 1: Link And Version Infrastructure

- Add `url_launcher` for external Support and Privacy URLs.
- Add `package_info_plus` so App Version can be displayed from runtime package metadata.
- Add testable injection points to `SettingsScreen`:
  - URL launch callback
  - app version loader callback
- Keep the Support and Privacy URLs as private constants near `SettingsScreen` or in a tiny local helper.
- Add URL launch failure handling:
  - Show the parent/guardian gate first.
  - Check `mounted` after the gate.
  - Attempt to launch the URL.
  - Show a localized snackbar if launch fails or throws.
- Run `flutter pub get` after dependency changes.

## Commit 2: Settings Localization

- Add new `SettingsTextSet` getters:
  - `helpAndSupportSectionTitle`
  - `userGuideSettingsItemTitle`
  - `restorePurchaseSettingsItemTitle`
  - `contactSupportSettingsItemTitle`
  - `aboutSectionTitle`
  - `privacyPolicySettingsItemTitle`
  - `appVersionSettingsItemTitle`
  - URL launch failure message
- Implement every new getter in:
  - `lib/l10n/ko/settings.dart`
  - `lib/l10n/en/settings.dart`
  - `lib/l10n/ja/settings.dart`
  - `lib/l10n/es/settings.dart`
  - `lib/l10n/pt_BR/settings.dart`
- Reuse existing equivalent strings only when doing so stays natural and does not create awkward cross-text-set coupling.
- Update `test/localization_support_test.dart`:
  - Verify all supported locales expose the new Settings strings.
  - Keep English fallback-copy checks for Japanese, Spanish, and Portuguese.
  - Explicitly verify Korean strings are Korean and match the requested labels where applicable.

## Commit 3: Restructure Settings Bottom Sections

- Remove the current top `userGuideSettingsTile` card.
- Add a bottom `Help & Support` section after normal app behavior/settings controls.
- Add these rows under `Help & Support`:
  - User Guide
  - Restore Purchase
  - Contact Support
- Add a final `About` section.
- Add these rows under `About`:
  - Privacy Policy
  - App Version
- Remove the existing Restore Purchase UI from the vehicle pack card to avoid duplicate restore entry points.
- Keep App Version as plain text only.
- Keep Card/ListTile styling consistent with the existing Settings screen.

## Commit 4: Protected Actions Wiring

- Keep User Guide as internal navigation to `UserGuideScreen`.
- Do not show the parent/guardian gate for User Guide.
- Protect Contact Support:
  - Show the existing `ParentGatePresenter`.
  - Launch the Support URL only after the gate passes.
  - Handle launch failure with localized feedback.
- Protect Privacy Policy:
  - Show the existing `ParentGatePresenter`.
  - Launch the Privacy URL only after the gate passes.
  - Handle launch failure with localized feedback.
- Protect Restore Purchase:
  - Show the existing `ParentGatePresenter`.
  - Call `purchaseController.restoreVehiclePack()` only after the gate passes.
  - Keep the existing restore snackbar result behavior.
- Keep Restore Purchase visible in the bottom Settings section even when the vehicle pack is already unlocked.
- Do not open the vehicle pack purchase sheet from the bottom Restore Purchase item.

## Commit 5: Tests And Verification

- Add or update Settings widget tests for:
  - User Guide opens from the new bottom section without the parent gate.
  - Contact Support calls the parent gate before the URL launcher.
  - Privacy Policy calls the parent gate before the URL launcher.
  - Gate failure prevents URL launch.
  - URL launch failure shows localized snackbar feedback.
  - Restore Purchase calls the parent gate and restores exactly once.
  - The old vehicle pack Restore Purchase button is gone.
  - App Version is displayed as plain text.
- Update existing Settings tests that depend on the old top User Guide tile or old Restore Purchase location.
- Run:
  - `dart format` on changed Dart files
  - `flutter test test/localization_support_test.dart`
  - targeted Settings tests in `test/widget_test.dart`
  - `flutter analyze`

## Manual Check Areas

- Settings bottom `Help & Support` and `About` sections.
- User Guide navigation.
- Privacy Policy parent gate and external browser launch.
- Contact Support parent gate and external browser launch.
- Restore Purchase parent gate and snackbar result.
- Restore Purchase visibility when the vehicle pack is already unlocked.
