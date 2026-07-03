# Timey Rider IAP Release Setup

Timey Rider uses a client-only, non-consumable in-app purchase for the vehicle pack.

## Product

- Product ID: `vehicle_pack`
- Type: non-consumable / one-time purchase
- Unlock: all locked vehicles
- Free vehicles: `motorcycle`, `supercar`
- Backend: none
- Ads: none
- Account/login: none
- Analytics: none
- Remote config: none

## iOS

Local simulator testing uses:

- `ios/Runner/StoreKitConfiguration.storekit`
- Product ID `vehicle_pack`
- Type `NonConsumable`

Open `ios/Runner.xcodeproj`, edit the Runner scheme, and set:

- Run > Options > StoreKit Configuration: `Runner/StoreKitConfiguration.storekit`

Before App Store release, configure the real product in App Store Connect:

- Product ID: `vehicle_pack`
- Type: Non-Consumable
- Reference name: Vehicle Pack
- Localized display name and description for English and Korean
- Pricing tier selected
- Product cleared for sale
- Sandbox tester account available for device testing

## Android

The Android manifest declares:

- `com.android.vending.BILLING`

Before Play release, configure the product in Play Console:

- Product ID: `vehicle_pack`
- Product type: one-time product
- Active product status
- Localized name and description for English and Korean
- Price configured for target countries
- License tester account available for device testing

## Client-Only Limitation

This app has no backend receipt validation. The app caches the local entitlement after a successful store purchase or restore. That supports offline use after purchase, but it cannot provide server-side fraud detection, cross-device entitlement sync outside store restore, or independent receipt revocation checks.

This is acceptable for the current local-first release direction, but release notes and review notes should be clear that purchases are restored through the app store and normal app progress/settings remain local.

## Privacy and Data Safety Wording

Use wording that matches the actual client-only implementation:

- Timey Rider does not include ads, third-party analytics, account login, backend server sync, or remote config.
- Routine settings, timer progress, activity history, stickers, reward goals, avatar settings, and the vehicle pack entitlement cache are stored locally on the device.
- Custom rider image selection is optional and started by the parent/guardian or user. Timey Rider imports the selected image from the device and stores the normalized rider image locally.
- Timey Rider does not upload child photos or rider images to a server.
- If a parent/guardian prepares an image with an external photo app or AI service before importing it into Timey Rider, that external service's own privacy terms apply.
- Because the app has no backend receipt validation, purchase restore depends on the app store account and store APIs.

## Kids App Review Notes

- Purchase and restore actions must remain behind the parent gate.
- The pre-gate vehicle pack info sheet must not show price or direct purchase wording.
- The purchase sheet may show price only after the parent gate passes.
- There are no ads, analytics, login, backend server, or remote config in this IAP flow.

## Release QA Checklist

- Locked premium vehicles stay visible with the lock icon and cannot be selected directly.
- Tapping a locked vehicle first shows the vehicle pack info sheet, then the parent gate, then the purchase sheet.
- Canceling or failing purchase keeps the current selected vehicle unchanged.
- A successful purchase or restore unlocks all premium vehicles and allows the originally tapped vehicle to be selected when the current flow is still active.
- Restore is available from both the purchase sheet and Settings, and both entry points are parent-gated.
- If a saved premium `vehicleId` exists before entitlement is restored, the app temporarily falls back to a free vehicle without rewriting other settings.
- After a successful purchase or restore has been cached locally, locked vehicles remain available while offline.
- Avatar setup uses the same locked vehicle policy as the Home vehicle picker.
- Settings, onboarding, timer resume, recent/favorite timer presets, marker selection, stickers, rewards, history, and avatar image import still work after the IAP changes.
