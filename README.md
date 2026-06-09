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
