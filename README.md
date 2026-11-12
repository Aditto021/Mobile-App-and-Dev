# FeriWala

A refined Flutter shopping demo with a Bangladeshi cycle-vendor identity, quiet violet and champagne surfaces, and high-refresh-rate Android support.

## Run and verify

Use Flutter 3.47.7 / Dart 3.13.5 and Java 21. Run `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter run`.

The catalogue ships with the app; product photos need internet. Start the backend (below) for real accounts, synced carts and server-side orders; without it the app still works on the device alone. Order tracking and payment methods are demonstrations: no money is charged.

## Backend

`server/` is a Dart REST API (shelf + shelf_router) the app talks to with Dio.

```
cd server
dart pub get
dart run bin/server.dart          # http://localhost:8090, data saved in server/data/db.json
dart test                         # 16 API tests
```

The app finds it at `localhost:8090` (web and desktop) or `10.0.2.2:8090` (Android emulator). For a phone on Wi-Fi, use `flutter run --dart-define=API_URL=http://<computer-ip>:8090`. `API_URL=off` runs without a server.

| Endpoint | What it does |
|---|---|
| `POST /auth/register`, `/auth/login`, `/auth/logout` | Accounts by email or BD mobile number. Passwords hashed with PBKDF2-SHA256; 30-day bearer tokens; 5 wrong passwords lock sign-in for a minute |
| `GET /me`, `PATCH /me` | Profile and delivery address |
| `GET /categories`, `/products`, `/products/:id` | Catalogue with `category`, `q`, `ids`, `sort`, `page`, `limit`; live stock |
| `GET/PUT /cart`, `/cart/items/:id`, `/cart/coupon` | Saved cart with price quote: delivery ৳60, free from ৳2,000; FERIWALA10 takes 10% off, at most ৳1,500 |
| `GET/PUT /wishlist`, `/wishlist/:id` | Saved wishlist |
| `GET/POST /orders`, `/orders/:id` | Server checks stock, prices the order, takes the units out of stock and empties the cart |

The app stays offline-first: changes show at once and are saved on the device, then a signed-in account sends its cart, voucher and wishlist to the server. Signing in on a new device merges both sides. If the server is down, sign-in and checkout fall back to the device and the account screen shows the sync state.

## Google Play

The default build is the Google Play build: no self-updater, no install-packages permission, https only, signed with the upload key in `android/key.properties` (kept out of Git; see `store/PLAY_STORE.md`).

```
./scripts/build_play.ps1 -ApiUrl https://your-api.example.com
```

It writes a verified `.aab` to `release/play/`. `store/PLAY_STORE.md` has the listing text, Data safety and content-rating answers, screenshots, feature graphic and icon, plus how to host the backend. The privacy policy and account-deletion pages live in `docs/` (GitHub Pages); the app shows the same policy under Account → Privacy policy and deletes accounts under Account → Delete account.

## Build a signed APK (direct download)

Run `flutter build apk --release -P sideload=true --dart-define=SIDELOAD=true`, then `./scripts/package_release.ps1 -SkipBuild` (or let the script build it). Only this build contains the in-app updater.

The packaging script verifies the package identity, version, original signing certificate, and APK alignment. It writes a SHA-256 checksum and update manifest and keeps only the current APK in `release/`. Android 7.0 or later is required. APKs and signing keys are excluded from source control.

Preserve the existing signing keystore. The direct-install app currently uses the original Android debug certificate; the Google Play build uses its own upload key instead. A different signing key cannot update existing installations.

## Publish online updates

The app checks public GitHub Releases on storefront launch/resume, at most once every 15 minutes. Account > App updates checks immediately. Downloads are verified by size, checksum, package, version, Android compatibility, and signing certificate before Android opens its installation confirmation.

The Android release workflow runs on pushes to main or manual dispatch. Configure repository secret `ANDROID_KEYSTORE_BASE64` with the EXISTING signing keystore encoded as Base64. Optional secrets are `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, and `ANDROID_KEY_ALIAS`; when omitted, existing debug-keystore defaults are used. Never commit signing material.

Every push to `main` that changes the app becomes an update; edits to Markdown, `docs/`, `store/` or `server/` do not. The workflow numbers the build itself (in its own copy of `pubspec.yaml`): version code = pubspec code + 100 + run number, and the patch number grows the same way (1.3.0 → 1.3.6, 1.3.7 …). The first line of the commit message becomes the update note phones show. It tests, builds, verifies, uploads a draft release, and publishes after both the APK and metadata have uploaded. Phones see it on the next app launch or resume (checked at most every 15 minutes) and install it with one tap plus Android's confirmation. Raise `version:` yourself only for a new major or minor version. The repository must be public for phones to read the feed. The workflow never changes repository visibility.

For manual publishing, authenticate with `GITHUB_TOKEN` (Contents: write), then run `./scripts/publish_release.ps1`. The feed remains unavailable until a release is published. Editing source files alone does not change an installed app.

## Product catalogue

`assets/data/products.json` holds 210 real Daraz Bangladesh listings across 14 categories: phones, laptops, gadgets, tablets, watches, smartwatches, fragrance, beauty, skin care, men's and women's fashion, bags, jewellery and shoes. Each product keeps Daraz's price in Taka, discount, rating, number of ratings, units sold, seller, ship-from city, spec highlights and product photo (loaded from Daraz's image CDN).

`node tool/build_catalogue.mjs` rebuilds the file from saved Daraz search replies in `.catalogue-cache/` (not committed). It drops replicas and off-topic results, mixes sellers, and tidies the titles. With `--fetch` it can ask Daraz for missing searches, slowly, and it stops at once if Daraz asks for a bot check.

## Design and validation

- The splash decodes the logo before the main reveal and requests high refresh rate after the first frame.
- The default background avoids live shader compilation during startup. Live motion remains optional.
- Product images decode near their displayed size. Tabs use repaint boundaries and inactive tickers pause.
- Reduced-motion settings are supported by the splash, page transitions, onboarding illustration, and success celebration.
- Tests cover the backend end to end (in-process, through Dio), persistence, malformed saved data, validation, update prompts, and 13 screens at normal and 140% text size.
- Local visual previews are generated in `build/qa/`. Remote images use offline placeholders in tests.

Physical-device checks are still needed for sustained 120 fps and installation through a live update feed. Hardware, thermal limits, and Android settings determine actual frame rate.

## Code layout

```
lib/
  main.dart, app.dart   entry point and MaterialApp
  core/                 brand config, theme, validators, formatters, services
  data/api/             Dio client and typed API calls
  data/models/          Product, Review, Category, CartItem, Order
  data/state/           Shop — all app state (Provider + shared_preferences + server sync)
  features/<name>/      one folder per screen group
  shared/widgets/       reusable glass, product, logo and background widgets
server/                 REST backend (bin/server.dart, lib/src/, test/)
```

Every Dart file opens with a `/// MODULE:` header naming the module and its classes.
