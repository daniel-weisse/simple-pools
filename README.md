# Simple Pools

An offline fencing tournament organizer for Android, iOS, and the web.

## Local setup

Install Flutter **3.35.7** (pinned in [.flutter-version](.flutter-version) and CI),
including its bundled Dart SDK, and add Flutter's `bin` directory to `PATH`.

| Target | Additional tools |
| --- | --- |
| Web | Chrome and Python 3.7+ (for the release preview scripts) |
| Android | Android SDK, JDK 17, and an emulator or connected device |
| iOS | macOS, Xcode, CocoaPods, and a simulator or connected device |

Run commands from the repository root. Use `python3` instead of `python` where needed.

```sh
flutter doctor
flutter pub get --enforce-lockfile
dart run build_runner build --delete-conflicting-outputs
```

Start the app in Chrome, or select a mobile device:

```sh
flutter run -d chrome
flutter devices
flutter run -d <device-id>
```

## Local checks

Run the same generation, formatting, analysis, and tests used by CI:

```sh
flutter pub get --enforce-lockfile
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test --coverage
```

For a focused UI check, use `flutter test test/widget_test.dart`.

## Local builds

### Web

Build and open the release app at **http://127.0.0.1:8000/**:

```sh
python tool/run_web.py
```

Stop with **Ctrl+C**. Optional flags: `--port 8080`, `--no-open`, and
`--flutter-sdk "path/to/flutter"`. The script finds Flutter in `.tools/flutter`
or on `PATH`.

To build without starting a server:

```sh
flutter build web --release --no-web-resources-cdn --pwa-strategy=none
dart run tool/build_offline.dart
```

Preview `build/web`, or an extracted GitHub web artifact, using the supplied server:

```sh
python tool/serve_web.py
python tool/serve_web.py "path/to/extracted/web"
```

Open the localhost URL instead of opening `index.html` directly. For deployment,
upload the entire `build/web` directory to an HTTPS host. Apply
[web/_headers](web/_headers) where supported, otherwise the offline worker supplies
isolation headers after an initial reload. For a subdirectory, add `--base-href /your-path/`
to the Flutter build command.

Optional browser smoke test after building the web app:

```sh
python -m pip install websocket-client
python tool/browser_smoke.py "path/to/chromium-or-edge"
```

Screenshots are saved in `build/verification`.

### Android

```sh
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

APKs are saved in `build/app/outputs/flutter-apk`. Find the release AAB in
`build/app/outputs/bundle/release`. Release builds are unsigned unless signing
is configured. For local signing, place your keystore at `android/app/release.jks`
and create the ignored `android/key.properties` file:

```properties
storeFile=release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

### iOS

On macOS, build an unsigned device app:

```sh
flutter build ios --release --no-codesign
```

Output: `build/ios/iphoneos/Runner.app`. Use the signed GitHub Actions build below
to export an IPA with your Apple certificate and provisioning profile.

## GitHub setup

1. Push the project, including `.github/workflows`, to the repository's default
   branch. Manual workflow runs require write access and a workflow on that branch.
   See [GitHub's manual workflow guide](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).
2. In **Settings → Actions → General**, enable Actions and allow the `actions/*`
   actions and `subosito/flutter-action` used by this repository. Organization
   policies must also permit them. See [GitHub Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository).
3. For signed builds, add the repository secrets below under
   **Settings → Secrets and variables → Actions → New repository secret**.
   See [GitHub's secrets guide](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).

Checks and unsigned builds require no secrets. Draft releases use the automatic
`GITHUB_TOKEN` with the `contents: write` permission already requested by the release job.

### Signing secrets

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release keystore |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Signing key password |
| `ANDROID_KEY_ALIAS` | Signing key alias |
| `IOS_CERTIFICATE_BASE64` | Base64-encoded signing certificate and private key (.p12) |
| `IOS_CERTIFICATE_PASSWORD` | P12 password |
| `IOS_PROFILE_BASE64` | Base64-encoded provisioning profile (.mobileprovision) |
| `IOS_KEYCHAIN_PASSWORD` | Password for the temporary CI keychain |
| `IOS_TEAM_ID` | Apple developer team ID |
| `IOS_SIGNING_IDENTITY` | Identity matching the certificate, such as `Apple Distribution` |

Enabling `sign_artifacts` signs both mobile targets, so configure both sets of
secrets. The iOS profile must match `org.simplepools.simplePools`, the certificate,
and `ios_method`. Android uses `org.simplepools.simple_pools`. If changing identifiers,
also update the iOS provisioning map in
[build-artifacts.yml](.github/workflows/build-artifacts.yml).

## Using GitHub Actions

| Workflow | Trigger | Result |
| --- | --- | --- |
| [Checks](.github/workflows/checks.yml) | Every push and pull request | Formatting, analysis, tests with coverage, and a `web-preview` artifact |
| [Build release artifacts](.github/workflows/build-artifacts.yml) | Manual | Checks followed by Android, iOS, and web downloads, with signing disabled by default |
| [Build draft release](.github/workflows/release.yml) | Manual | The same builds attached to a draft GitHub release, with signing enabled by default |
| [Deploy GitHub Pages](.github/workflows/deploy-pages.yml) | Manual or release published (including prereleases) | Web app deployed to GitHub Pages |

For Pages, set **Settings → Pages → Source → GitHub Actions** and ensure the
`github-pages` environment allows your manual-run branches and release tags.
Run **Actions → Deploy GitHub Pages → Run workflow**, or publish a release whose
tag includes this workflow. Manual runs deploy the selected revision, release
runs deploy the tagged revision. The site path is detected automatically. No extra
secrets are required.

### Download builds

1. Open **Actions → Build release artifacts → Run workflow**.
2. Select the branch and choose `sign_artifacts`. Leave it off for builds without
   signing credentials. When signing, choose `ios_method` to match the profile:
   `ad-hoc` (default), `app-store-connect`, `enterprise`, or `development`.
3. Run the workflow. After it succeeds, open the run's **Artifacts** section.

| Artifact | Contents |
| --- | --- |
| `android-release` | Release APK and AAB, signed only when requested |
| `ios-release` | Signed IPA, or `simple-pools-ios-unsigned.zip` containing `Runner.app` |
| `web-release` | `simple-pools-web.zip`, ready to extract and serve |

Unsigned mobile release artifacts need signing before installation or distribution.
Use the local Android debug build for an installable development APK.

### Create a release

1. Set the intended version and build number in [pubspec.yaml](pubspec.yaml),
   then commit and push.
2. Open **Actions → Build draft release → Run workflow** and select that branch.
3. Enter a new version tag such as `v1.0.0`. For signed artifacts, keep signing
   enabled and select the matching `ios_method`. For unsigned artifacts, disable signing.
4. After the workflow succeeds, open **Releases**, review the draft and its
   attached files, and publish it when ready.

The workflow builds the selected revision and creates a draft only. App store
submission is a separate step, publishing the release triggers Pages deployment.
