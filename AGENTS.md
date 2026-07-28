## Working Style
- Keep changes minimal.
- Do not do unrelated refactors.
- Search first to understand the structure before editing.
- Run tests or lint within a practical scope after changes.
- If tests fail, clearly report the cause and scope.

## Editing Rules
- Preserve existing function and class style as much as possible.
- Prefer targeted edits over full-file rewrites.
- Add new dependencies only when clearly necessary.

## Review Loop Shortcuts
- Default review-loop shortcuts use compact mode: `code-review-loop`, `agy-code-review-loop`, `codex-code-review-loop`, `plan-review-loop`, `agy-plan-review-loop`, `codex-plan-review-loop`.
- Audit review-loop shortcuts preserve detailed artifacts: `audit-code-review-loop`, `agy-audit-code-review-loop`, `codex-audit-code-review-loop`, `audit-plan-review-loop`, `agy-audit-plan-review-loop`, `codex-audit-plan-review-loop`.
- If the loop count is omitted, default to 1 loop.
- Detailed review-loop behavior lives in `CODEX_REVIEW_LOOP.md`.
- Do not read or apply `CODEX_REVIEW_LOOP.md` for unrelated implementation, debugging, explanation, or commit requests.

## Communication
- Briefly summarize what changed, why it changed, and how it was verified.
- After each implementation task, explicitly list the app areas or flows the user should manually check.

## Localization
- When translating Korean phrases into English (or other languages), do not translate them literally. Instead, carefully review the context and translate the phrases so they sound natural and idiomatic to native speakers of the target language.

## Release management
- Read `docs/release_process.md` before changing release signing,
  app versions, build numbers, store configuration, or IAP configuration.
- Treat `pubspec.yaml` as the source of truth for the app version and
  build number.
- Keep Android `versionCode` and iOS `CFBundleVersion` aligned through
  the Flutter build number.
- Do not increment the build number for ordinary local development.
- Increment the build number only when preparing a new binary for
  Play Console, TestFlight, or App Store Connect, unless explicitly
  instructed otherwise.
- Never reuse a build number that has already been successfully uploaded.
- Do not create Git tags or GitHub releases unless explicitly requested.
- Never commit signing keys, keystores, passwords, API keys,
  `android/key.properties`, or store credentials.
- Do not change application IDs, bundle IDs, IAP product IDs, or signing
  identities without explicit approval.

## In-app purchases
- The non-consumable vehicle pack product ID is `vehicle_pack`.
- `vehicle_pack` must remain consistent between the Flutter code,
  Google Play Console, App Store Connect, and StoreKit test configuration.
- The same product ID is used independently for this app on Android and iOS.
- Preserve purchase restoration and existing entitlement behavior.

## App identity
- App name: Timey Rider
- Android application ID: `com.timeyrider.app`
- iOS bundle ID: `com.timeyrider.app`
