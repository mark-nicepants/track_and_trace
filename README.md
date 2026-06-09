# app — Flutter template

Opinionated Flutter template with a strict 3-layer architecture
(`data` / `domain` / `ui`), Riverpod state, GetIt DI, go_router routing,
and minimal codegen.

Read [`ARCHITECTURE.md`](./ARCHITECTURE.md) for the full design. AI agents
should also read [`AGENTS.md`](./AGENTS.md).

## Quick start

```bash
make setup                        # installs pinned Flutter via FVM, runs pub get + lefthook install
make run                          # flutter run + experiment flag, via fvm
```

The project pins Flutter to **3.44.1** via [FVM](https://fvm.app) (see `.fvmrc`).
`make setup` installs the SDK locally if needed.

`make test`, `make analyze`, `make layers`, `make check` are the other day-to-day
entry points. They all wrap Flutter/Dart commands through `fvm` and pass
`--enable-experiment=primary-constructors` where required.

## Cloning into a new app

```bash
fvm dart run --enable-experiment=primary-constructors \
  tool/clone_template.dart --name my_new_app --org com.example
```

The script copies the template into `../my_new_app`, rewrites package +
bundle identifiers, resets env files, and initialises git. From an LLM,
use the `clone-template` skill which drives the script interactively.

## Layout (high-level)

```
lib/
  data/      # outside-world access (HTTP, platform packages, storage)
  domain/    # business logic, use-cases, entities, converters
  ui/        # widgets, Riverpod providers/notifiers, routing
  shared/    # cross-layer utilities (inject, log, AppEnv, contracts)
env/         # dev/staging/prod/local JSON env files
tool/        # check_architecture_violations.dart, clone_template.dart
```

## Environments

The active env is persisted in `SharedPreferences` and defaults to
`prod`. Switch via the in-app env switcher (FAB on home page, only
visible in non-prod) and restart the app.

Each env JSON in `assets/env/*.json` carries three fields:

| Field           | Purpose                                                          |
|-----------------|------------------------------------------------------------------|
| `apiBaseUrl`    | Backend base URL (used by Dio).                                  |
| `enableLogging` | Console + Dio body logging. `false` in prod.                     |
| `newRelicToken` | New Relic Mobile application token. Empty = SDK boot is no-op.   |

The token is read on launch by `NewRelicService.start(token: ...)` from
`main.dart`. Replace the stub body with the real `NewrelicMobile.instance.startAgent(...)`
call once the native plugin is wired (see `lib/data/services/new_relic_service.dart`).

## Release builds

The Flutter SDK is pinned to **3.44.1** via FVM (see `.fvmrc`); every
command must go through `fvm` (or the Makefile, which already does).
Builds require the experiment flag for primary constructors.

### Android (.aab for Play Store, .apk for sideload)

```bash
# App Bundle — Play Store upload (preferred for store delivery):
fvm flutter build appbundle --enable-experiment=primary-constructors --release

# APK — direct install / sideload:
fvm flutter build apk --enable-experiment=primary-constructors --release
```

Output:
- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-release.apk`

The Makefile shortcut `make build-android` wraps `flutter build appbundle`.

### iOS (.ipa for TestFlight / App Store)

```bash
fvm flutter build ipa --enable-experiment=primary-constructors --release
```

Output: `build/ios/ipa/app.ipa`

`make build-ios` runs `flutter build ios` (Xcode archive step still
required for store delivery). Open `ios/Runner.xcworkspace` and use
**Product → Archive** to produce the store-ready `.ipa`.

### Selecting an env for a release build

The env JSON files are bundled as assets; the active env is picked from
`SharedPreferences` at runtime. For a release build that should default
to `prod`, no extra flag is needed (`prod` is the fallback). For ad-hoc
builds pointing at `dev` / `staging`, switch the env in-app on first
launch — the choice persists across relaunches.
