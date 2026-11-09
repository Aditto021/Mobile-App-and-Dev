# FeriWala

A refined Flutter shopping demo with a Bangladeshi cycle-vendor identity, quiet violet and champagne surfaces, and high-refresh-rate Android support.

## Run and verify

Use Flutter 3.47.7 / Dart 3.13.5 and Java 21. Run `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter run`.

The catalogue ships with the app; product photos need internet. Cart, wishlist, local profile, and orders persist on the device. Accounts, tracking, and payment methods are demonstrations: no server account is created and no money is charged.

## Build a signed APK

Run `flutter build apk --release`, then `./scripts/package_release.ps1 -SkipBuild`.

The packaging script verifies the package identity, version, original signing certificate, and APK alignment. It writes a SHA-256 checksum and update manifest and keeps only the current APK in `release/`. Android 7.0 or later is required. APKs and signing keys are excluded from source control.

Preserve the existing signing keystore. The direct-install app currently uses the original Android debug certificate; this is not a Play Store release. A different signing key cannot update existing installations.

## Publish online updates

The app checks public GitHub Releases on storefront launch/resume, at most once every 15 minutes. Account > App updates checks immediately. Downloads are verified by size, checksum, package, version, Android compatibility, and signing certificate before Android opens its installation confirmation.

The Android release workflow runs on pushes to main or manual dispatch. Configure repository secret `ANDROID_KEYSTORE_BASE64` with the EXISTING signing keystore encoded as Base64. Optional secrets are `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, and `ANDROID_KEY_ALIAS`; when omitted, existing debug-keystore defaults are used. Never commit signing material.

For each release, increment both parts of `version:` in `pubspec.yaml`, commit, and push. The workflow tests, builds, verifies, uploads a draft release, and publishes after both the APK and metadata have uploaded. The repository must be public for phones to read the feed. The workflow never changes repository visibility.

For manual publishing, authenticate with `GITHUB_TOKEN` (Contents: write), then run `./scripts/publish_release.ps1`. The feed remains unavailable until a release is published. Editing source files alone does not change an installed app.

## Design and validation

- The splash decodes the logo before the main reveal and requests high refresh rate after the first frame.
- The default background avoids live shader compilation during startup. Live motion remains optional.
- Product images decode near their displayed size. Tabs use repaint boundaries and inactive tickers pause.
- Reduced-motion settings are supported by the splash, page transitions, onboarding illustration, and success celebration.
- Tests cover persistence, malformed saved data, validation, update prompts, and 13 screens at normal and 140% text size.
- Local visual previews are generated in `build/qa/`. Remote images use offline placeholders in tests.

Physical-device checks are still needed for sustained 120 fps and installation through a live update feed. Hardware, thermal limits, and Android settings determine actual frame rate.

## Code layout

```
lib/
  main.dart, app.dart   entry point and MaterialApp
  core/                 brand config, theme, validators, formatters, services
  data/models/          Product, Review, Category, CartItem, Order
  data/state/           Shop — all app state (Provider + shared_preferences)
  features/<name>/      one folder per screen group
  shared/widgets/       reusable glass, product, logo and background widgets
```

Every Dart file opens with a `/// MODULE:` header. See
[docs/VIVA_GUIDE.md](docs/VIVA_GUIDE.md) for a module-by-module walkthrough.
