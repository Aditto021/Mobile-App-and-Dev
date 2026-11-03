# Online updates

The Android feed is `https://github.com/Aditto021/Mobile-App-and-Dev/releases/latest/download/feriwala-update.json`.

Publishing a new signed release activates the feed. The app checks on storefront launch/resume (15-minute throttle) and through Account > App updates. A download starts only after the user chooses it. Android asks the user to approve installation. Existing app data is preserved by matching package identity and signing certificate.

## Release process

1. Modify and test the Flutter source.
2. Increment version name AND build number in `pubspec.yaml`.
3. Commit and push to main.
4. The Android release workflow tests, builds, verifies, uploads a draft release, and publishes it after both assets are present.

Configure `ANDROID_KEYSTORE_BASE64` in repository Actions secrets using the existing signing keystore. The optional password/alias secrets are documented in README.md. Never upload the key in a commit or release asset. Changing keys breaks updates to existing installations.

Manual alternative: set GITHUB_TOKEN in an authenticated PowerShell session and run `./scripts/publish_release.ps1`. Add -SkipBuild only for an APK already built from the current version. The script rejects a mismatched package, certificate, version, checksum, or a non-increasing build number.

## Public feed schema

The JSON asset contains packageId, versionName, versionCode, apkUrl, sha256, sizeBytes, and releaseNotes. The APK URL points to the versioned release asset. APK downloads must use HTTPS and the configured release repository. Phones validate APK size, SHA-256, package name, build number, Android minimum SDK, and installed certificate before opening the installer.

A public repository is necessary for unauthenticated phone access. The scripts do not change visibility. Local editing alone does not update installed phones: a new release must be built and published.

Before a feed is published, the app remains usable and manual checks clearly report that the feed is not published. Real-device update installation against a live feed remains an acceptance check after publishing.
