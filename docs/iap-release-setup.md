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

## Kids App Review Notes

- Purchase and restore actions must remain behind the parent gate.
- The pre-gate vehicle pack info sheet must not show price or direct purchase wording.
- The purchase sheet may show price only after the parent gate passes.
- There are no ads, analytics, login, backend server, or remote config in this IAP flow.
