# Architecture

This document describes the architecture, conventions, and tooling of this Flutter
template. It is the single source of truth — every other doc (including `AGENTS.md`)
defers to this file.

The template is intentionally opinionated and small. The apps built from it are small;
the choices below favor cohesion, type-safety, and minimal indirection over flexibility
that won't be exercised.

---

## Table of contents

1. [Principles](#principles)
2. [Layer model](#layer-model)
3. [Folder layout](#folder-layout)
4. [Dependency injection](#dependency-injection)
5. [Data layer](#data-layer)
6. [Domain layer](#domain-layer)
7. [UI layer](#ui-layer)
8. [Cross-layer utilities (`lib/shared/`)](#cross-layer-utilities)
9. [Bootstrap sequence](#bootstrap-sequence)
10. [Error model](#error-model)
11. [Environments & configuration](#environments--configuration)
12. [Routing](#routing)
13. [Logging](#logging)
14. [Testing](#testing)
15. [Linting & layer-boundary enforcement](#linting--layer-boundary-enforcement)
16. [Git hooks (lefthook)](#git-hooks-lefthook)
17. [Cloning the template](#cloning-the-template)
18. [Future considerations](#future-considerations)

---

## Principles

- **Flutter version pinned via FVM** (`.fvmrc`). The template targets Flutter
  **3.44.1**. All Flutter/Dart commands route through `fvm` (`fvm flutter`,
  `fvm dart`) so developers don't accidentally use a host SDK at a different
  version. The Makefile and lefthook do this automatically.
- **3 layers, strict direction.** `ui → domain → data`. Lower layers never import upper layers.
- **Pure layer-first.** Top-level folders are `data/`, `domain/`, `ui/`, plus `shared/` for
  cross-layer utilities. Feature subdivision exists only inside `ui/features/`.
- **Strongly typed everywhere.** No `dynamic`. No `double`. Inference is used where it
  doesn't obscure types.
- **Minimal codegen.** No Freezed, no json_serializable, no go_router_builder, no mockito.
  Equatable + manual `copyWith` + manual JSON + mocktail. The one exception is
  Flutter's built-in `gen-l10n` for localization — the manual alternative is too
  verbose for what it buys.
- **Primary constructors** (Dart's recent feature) used wherever possible:
  `class User(final String id, final String name) extends Equatable { ... }`.
- **Immutable by default.** Every entity, DTO, and notifier state class is immutable.
- **Single helper module for DI.** `lib/shared/inject.dart` exposes two symbols:
  `inject<T>()` for typed lookups and `injector` (the raw `GetIt` instance) for
  registration. Raw `GetIt.I` appears **only** inside `inject.dart`; every other
  file — including bootstrap — uses `injector` or `inject<T>()`.
- **Riverpod owns shared state, hooks own local state.** No overlap.
- **Test by construction.** Services have interfaces only when there is a real second
  implementation (e.g. in-memory for tests). Repositories do not.

---

## Layer model

| Layer | Responsibility | May import from |
|-------|----------------|-----------------|
| `data/` | Outside access: HTTP, platform packages, storage. Returns DTOs. | `shared/`, external packages |
| `domain/` | Business logic. Defines use-cases and entities. Converts DTOs → entities. | `shared/`, `data/`, external packages (rare) |
| `ui/` | Widgets, Riverpod providers/notifiers, routing, hooks. | `shared/`, `domain/`, external packages |
| `shared/` | Cross-layer utilities (`inject`, `log`). | nothing inside `lib/` |

Lefthook enforces the import direction. See
[Linting & layer-boundary enforcement](#linting--layer-boundary-enforcement).

---

## Folder layout

```
lib/
  main.dart
  app.dart                            # MaterialApp.router + env banner
  shared/
    inject.dart                       # inject<T>() + injector
    log.dart                          # global `log` accessor
    clock.dart                        # IsoClock — injected wall clock
    config/
      app_env.dart                    # value class, registered in GetIt
    contracts/                        # cross-layer interfaces
      i_logger.dart
      i_preference_service.dart
      i_crash_report_service.dart
      i_permission_service.dart
      i_location_client.dart
      i_foreground_tracking_service.dart
      i_sending_service.dart
      i_prediction_service.dart
      i_connectivity_service.dart
    errors/
      data_exception.dart             # sealed DataException hierarchy (cross-layer)
  data/
    di/
      data_module.dart                # registers dio + repos + services
    http/
      dio_provider.dart               # constructs the single Dio instance
      auth_interceptor.dart           # attaches X-API-Key from AppEnv
      guard_dio.dart                  # try/catch → DataException helper
      http_logging_interceptor.dart
    models/                           # DTOs
      user_dto.dart
    data_source/                      # on-device persistence (sqflite DAOs)
      position_queue_dao.dart
    repositories/
      user_repository.dart            # concrete; no abstract interface
    services/                         # platform-package wrappers (prod only)
      preference_service.dart
      logger_service.dart
  domain/
    entities/                         # immutable, Equatable
      user.dart
    converters/                       # extension methods: DTO → entity
      user_converter.dart
    errors/
      domain_exception.dart           # sealed DomainException hierarchy
    use_cases/
      use_case.dart                   # abstract UseCase<R> / StreamUseCase<R>
      get_current_user.dart
  ui/
    shared/
      l10n/
        l10n.dart                     # static L10n façade
        generated/                    # gen-l10n output (gitignored)
      router/
        app_router.dart               # GoRouter provider + redirect logic
        app_routes.dart               # composes per-page .route() calls
      state/                          # cross-feature Riverpod providers
        app_env_provider.dart
      theme/
        app_theme.dart
      widgets/                        # cross-feature widgets
      error_messages.dart             # exception → user-readable helper
    hooks/                            # custom flutter_hooks helpers (rare)
    features/
      home/
        home_page.dart
        home_notifier.dart
      dev/
        env_switcher_page.dart
        env_switcher_notifier.dart
assets/
  env/
    dev.json
    staging.json
    prod.json
    local.json                        # gitignored
  l10n/
    en.arb                            # template
    nl.arb
test/
  data/repositories/
  domain/use_cases/
  ui/features/
  helpers/
    di_test_helper.dart
    fixtures.dart
    fakes/                            # in-memory/no-op contract impls
      in_memory_preference_service.dart
      in_memory_permission_service.dart
      noop_logger.dart
      …
tool/
  check_architecture_violations.dart
  clone_template.dart
.claude/
  skills/
    clone-template/SKILL.md           # LLM-driven scaffolding
l10n.yaml
lefthook.yml
Makefile
.fvmrc                                # Flutter SDK pin (3.44.1)
```

State that belongs to a single feature lives in that feature's folder (e.g.
`ui/features/profile/profile_notifier.dart`). State is promoted to
`ui/shared/state/` only when a second feature consumes it. The promotion is a
deliberate refactor, not an automatic one.

---

## Dependency injection

GetIt is the only DI container. `lib/shared/inject.dart` is the only file that
references it directly; everything else goes through the two symbols it exports:

```dart
// lib/shared/inject.dart
import 'package:get_it/get_it.dart';

GetIt get injector => GetIt.I;
T inject<T extends Object>({String? instanceName}) =>
    injector<T>(instanceName: instanceName);
```

- `injector` — raw GetIt instance. Used by bootstrap / `registerDataModule()`
  for `registerSingleton`, `registerFactory`, `reset`, etc.
- `inject<T>()` — typed lookup. Used everywhere else.

**Registered in GetIt:**

- `AppEnv` (config)
- `Dio` (HTTP client)
- All data-layer repositories
- All data-layer platform-service wrappers (`IPreferenceService`, `ILogger`, …)

**Not registered in GetIt:**

- Use-cases. Use-cases are constructed at the call site by their consumer
  (typically a Riverpod provider/notifier). Their internal dependencies are
  resolved via private `inject<T>()` getters.
- Entities, DTOs, value objects.
- Riverpod providers/notifiers.

**The `inject` boundary rule:** widgets do not call `inject<T>()`. Use-cases,
notifiers, repos, services, and bootstrap code do. The layer-boundary check
enforces this; see [Linting](#linting--layer-boundary-enforcement).

Raw `GetIt.I` appears in **exactly one place**: inside `lib/shared/inject.dart`.
Bootstrap and `registerDataModule()` use `injector` instead.

---

## Data layer

### Repositories

- Concrete classes, no abstract interface. If a second implementation is ever
  needed (e.g. offline mode), introduce the interface *then*, not preemptively.
- Constructor takes nothing. Internal dependencies resolved via private
  `inject<T>()` getters.
- Always return DTOs (never entities).
- Throw `DataException` subtypes on failure (translation happens in the dio
  interceptor, so repo methods rarely contain try/catch).

```dart
class UserRepository {
  Dio get _dio => inject();
  Future<UserDto> fetchMe() async {
    final r = await _dio.get<Map<String, Object?>>('/me');
    return UserDto.fromJson(r.data!);
  }
}
```

### DTOs

- Primary constructors with positional `final` fields.
- Manual `factory fromJson` and `toJson()`.
- No `==` / `hashCode` — DTOs are transient.

```dart
class UserDto(final String id, final String fullName, final String? email) {
  factory UserDto.fromJson(Map<String, Object?> json) => UserDto(
    json['id'] as String,
    json['full_name'] as String,
    json['email'] as String?,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'full_name': fullName,
    if (email != null) 'email': email,
  };
}
```

### HTTP client

- Single shared `Dio` instance, configured at startup with `AppEnv.apiBaseUrl`
  and the `DataExceptionInterceptor`.
- Repositories receive it via `inject()`.
- For a second backend, register a named instance:
  `inject<Dio>(instanceName: 'analytics')`.

### Platform services

Thin wrappers around third-party packages. Each exposes an app-specific API,
not the package's API. Services either have a clear second implementation
need (`IPreferenceService` + `InMemoryPreferenceService` for tests) or are
concrete-only when no swap is plausible.

Naming convention: `IFooService` for the interface, `FooService` for the
production impl, `InMemoryFooService` for test impls.

Production implementations live in `lib/data/services/`. Test doubles
(`InMemoryX`, `NoopX`) live in `test/helpers/fakes/` so they do not ship
with the production binary. The interfaces themselves live in
`lib/shared/contracts/` so both production and test code can depend on them
without crossing layer boundaries.

### Dependencies on packages (canonical list)

- `dio` — HTTP
- `get_it` — DI
- `flutter_riverpod` — state
- `flutter_hooks` + `hooks_riverpod` — local state & widget ergonomics
- `go_router` — routing
- `equatable` — equality
- `shared_preferences` — non-secure key/value
- `flutter_secure_storage` — secure key/value
- `logger` — logging backend
- `mocktail` (dev) — mocking

---

## Domain layer

### Use-cases

One class per operation. Constructor parameters carry the *inputs* for this
invocation. Internal dependencies are resolved via private `inject<T>()`
getters. `call()` always has no parameters.

```dart
// domain/use_cases/use_case.dart
abstract class UseCase<R> { Future<R> call(); }
abstract class StreamUseCase<R> { Stream<R> call(); }

// domain/use_cases/get_current_user.dart
class GetCurrentUser implements UseCase<User> {
  UserRepository get _repo => inject();
  @override
  Future<User> call() async => (await _repo.fetchMe()).toEntity();
}

// domain/use_cases/search_users.dart
class SearchUsers(final String query) implements UseCase<List<User>> {
  UserRepository get _repo => inject();
  @override
  Future<List<User>> call() async {
    final dtos = await _repo.search(query);
    return dtos.map((d) => d.toEntity()).toList();
  }
}
```

### Entities

- Primary constructors with `final` fields.
- `extends Equatable`. Override `props`.
- Manual `copyWith`.
- No knowledge of DTOs.

```dart
class User(final String id, final String name, final String? email)
    extends Equatable {
  User copyWith({String? id, String? name, String? email}) =>
      User(id ?? this.id, name ?? this.name, email ?? this.email);
  @override
  List<Object?> get props => [id, name, email];
}
```

### Converters

Extension methods on the DTO, living in `domain/converters/`. The domain entity
remains unaware of the DTO type.

```dart
// domain/converters/user_converter.dart
extension UserDtoX on UserDto {
  User toEntity() => User(id, fullName, email);
}

// reverse direction when needed (writes):
extension UserX on User {
  UserDto toDto() => UserDto(id, name, email);
}
```

### Multi-outcome operations

When an operation has multiple *legitimate* outcomes (not errors), return a
sealed result type:

```dart
sealed class LoginOutcome {}
class LoginSuccess(final User user) extends LoginOutcome {}
class LoginRequiresMfa(final String challengeId) extends LoginOutcome {}
class LoginInvalidCredentials extends LoginOutcome { const LoginInvalidCredentials(); }
```

Use the sealed class only when each branch carries different shape/data.
A simple success/failure split is better served by an exception.

---

## UI layer

### Widget base class

`HookConsumerWidget` is the default for screens — it allows both `ref.watch`
(Riverpod) and hooks (`useTextEditingController`, …).

```dart
class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  static const String path = '/profile';
  static const String name = 'profile';
  static GoRoute route() => GoRoute(
    path: path, name: name,
    builder: (context, state) => const ProfilePage(),
  );
  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nameCtl = useTextEditingController();
    return user.when(
      data: (u) => ...,
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorView(e),
    );
  }
}
```

### State responsibilities

- **Riverpod owns shared state** — anything that crosses widget instances,
  benefits from caching, or needs auto-dispose semantics.
  - `FutureProvider` / `StreamProvider` for read-only operations.
  - `AsyncNotifierProvider` for state that supports mutations.
  - All `autoDispose` by default. Use `keepAlive` only with a documented reason
    (e.g. auth session, app-wide settings).
- **flutter_hooks owns local state** — text controllers, focus nodes, animation
  controllers, form state, ephemeral booleans.

### Riverpod providers wrap use-cases

```dart
final currentUserProvider = FutureProvider.autoDispose<User>((ref) async {
  return GetCurrentUser().call();
});

class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() => GetProfile().call();
  Future<void> rename(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => UpdateProfile(name).call());
  }
}

final profileProvider =
    AsyncNotifierProvider.autoDispose<ProfileNotifier, Profile>(
      ProfileNotifier.new,
    );
```

Notifiers may call `inject<T>()` (they are not widgets), but typically only
instantiate use-cases — the use-case handles all GetIt resolution internally.

### Pages own their routes

Every page exposes `static const String path`, `static const String name`, a
`static GoRoute route()` constructor, and (for parameterized pages) a
typed `static void go(BuildContext, ...)` helper. The route tree composes them:

```dart
final List<RouteBase> appRoutes = [
  HomePage.route(),
  ProfilePage.route(),
  UserDetailPage.route(),
];
```

No central `routes.dart` constants file.

### Custom hooks

Rare. The only situations that justify a custom hook are flutter_hooks-native
abstractions (controllers + lifecycle) — never use-case execution, since
`ref.watch` already gives `AsyncValue<R>`.

---

## Cross-layer utilities

`lib/shared/` holds the few utilities that all layers may import:

```dart
// lib/shared/inject.dart
T inject<T extends Object>() => GetIt.I<T>();

// lib/shared/log.dart
ILogger get log => inject<ILogger>();
```

Widgets and other consumers call `log.info('…')` directly. This both centralizes
the logger and keeps `inject<>` out of the widget tree. `lib/shared/` may not
import from `lib/data/`, `lib/domain/`, or `lib/ui/`; all cross-layer
interfaces (e.g. `ILogger`, `IPreferenceService`) live in
`lib/shared/contracts/` so `shared/` introduces no transitive coupling.

---

## Bootstrap sequence

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Preference service: lazy-initialized, no async dependencies.
  GetIt.I.registerSingleton<IPreferenceService>(PreferenceService());

  // 2. Logger: registered early so other modules can log.
  GetIt.I.registerSingleton<ILogger>(LoggerService());

  // 3. Resolve and register AppEnv.
  final envName = await inject<IPreferenceService>()
          .readString('app.selected_env') ?? AppEnvs.fallbackName;
  final raw = await rootBundle.loadString('env/$envName.json');
  final env = AppEnv.fromJson(envName, jsonDecode(raw) as Map<String, Object?>);
  GetIt.I.registerSingleton<AppEnv>(env);

  // 4. Data module: dio + repos + remaining services.
  registerDataModule();

  runApp(const ProviderScope(child: App()));
}
```

`registerDataModule()` is the single entry point for data-layer registrations.
Domain and UI have no registration functions because they own no GetIt entries.

---

## Error model

### Hierarchy

Sealed exception classes — two hierarchies, two locations:

```dart
// shared/errors/data_exception.dart  (cross-layer: both data and ui import it)
sealed class DataException implements Exception {}
class NetworkException extends DataException {}
class TimeoutException extends DataException {}
class HttpException(final int statusCode, final Object? body) extends DataException;
class ParseException(final Object cause) extends DataException;
class UnknownDataException(final Object cause) extends DataException;

// domain/errors/domain_exception.dart
sealed class DomainException implements Exception {}
class NotFoundException extends DomainException {}
class ValidationException(final String field, final String message) extends DomainException;
class UnauthorizedException extends DomainException {}
class ConflictException extends DomainException {}
class ServerException(final int statusCode) extends DomainException;
```

`DataException` lives under `lib/shared/errors/` because both `data/` (the
producer) and `ui/` (`error_messages.dart` matches on `NetworkException`,
`TimeoutException`, …) consume it. Putting it in `shared/` keeps the
`ui → data` layer rule intact.

### Flow

- `guardDio` (in `lib/data/http/`) wraps every repository call. It translates
  all `DioException`s into the sealed `DataException` types so repos never
  write their own try/catch around HTTP.
- The `UseCase` base class is a template: subclasses override `execute()`;
  the public `call()` wraps it and translates well-known HTTP status codes
  into `DomainException` subtypes via `mapHttpStatusToDomain()`:
  - `401` / `403` → `UnauthorizedException`
  - `404` → `NotFoundException`
  - `409` → `ConflictException`
  - `5xx` → `ServerException(statusCode)`
  - everything else propagates as the original `HttpException`.
  Per-use-case overrides remain free to catch + rethrow more specific
  `DomainException`s (e.g. parsing a 422 body into `ValidationException`).
- Authentication. The reference Android app uses a static `X-API-Key`
  header sourced from `BuildConfig.GCP_API_KEY` (loaded at build time from
  the gitignored `local.properties`). The Flutter port mirrors this:
  `AuthInterceptor` (registered in `buildDio`) reads `AppEnv.apiKey` and
  attaches it as `X-API-Key` on every request. The real key lives in
  `assets/env/local.json` (gitignored); committed env files carry an empty
  placeholder.
- Riverpod's `AsyncValue` captures these via `AsyncValue.guard`. UI surfaces
  them with `.when(error: ...)` plus pattern matching:

```dart
err.when(
  error: (e, _) => switch (e) {
    NetworkException()      => const OfflineBanner(),
    UnauthorizedException() => const LoginPrompt(),
    NotFoundException()     => const NotFoundView(),
    _                       => GenericErrorView(message: errorMessage(e)),
  },
  ...
);
```

### `errorMessage(Object e)`

`lib/ui/shared/error_messages.dart` exposes `String errorMessage(Object e)`,
the central exception → user-readable-string helper. Add new cases here as
new exception types are introduced.

---

## Environments & configuration

### Files

```
assets/env/dev.json
assets/env/staging.json
assets/env/prod.json
assets/env/local.json     # gitignored, optional per-developer override
```

Each file is a JSON object with the keys required by `AppEnv.fromJson`. Files
are declared as Flutter assets in `pubspec.yaml`.

### Selection

- The selected env name is persisted in `IPreferenceService` under
  `app.selected_env`. Default: `prod`.
- An in-app env switcher (`ui/features/dev/env_switcher_page.dart`) writes the
  new name and prompts a restart. We do **not** hot-swap: dio is already
  configured, tokens are env-scoped, and Riverpod state may be cached.
- The switcher route is registered at `/dev/env` but the UI entry point is
  only rendered when `env.name != 'prod'`. The route remains deep-linkable in
  prod for QA.
- A coloured corner banner is rendered in non-prod builds (see
  [Environment banner](#environment-banner)).

### `AppEnv`

```dart
class AppEnv(
  final String name,
  final String apiBaseUrl,
  final bool enableLogging,
  final String newRelicToken,
  final String apiKey,
) extends Equatable { … }
```

`apiKey` is the backend's static `X-API-Key`. Committed env files
(`dev.json`, `staging.json`, `prod.json`) carry an empty string; the real
key lives in `assets/env/local.json` (gitignored), mirroring the reference
Android app's `local.properties` pattern.

### Feature flags

Boolean fields on `AppEnv` for now. A runtime-override layer (e.g. backed by a
remote feature-flag service) is an explicit extension point — add a
`FeatureFlagsService` in `data/services/` and read it from a Riverpod provider.

---

## Routing

- `go_router` only.
- Single `GoRouter` exposed as `routerProvider` (a Riverpod `Provider<GoRouter>`).
  This allows the router to `ref.watch(authStateProvider.notifier)` for
  auth-driven redirects.
- Pages own their routing metadata (see [UI layer](#ui-layer)).
- Path parameters reach a page via `state.pathParameters['id']!` inside the
  page's `static GoRoute route()`. Typed `static void go(BuildContext, …)`
  helpers are the public navigation API.
- Bottom nav / tab persistence: use `StatefulShellRoute.indexedStack` in
  `app_routes.dart` when needed. The template ships no shell route by default.

---

## Localization (l10n)

- Flutter's built-in `gen-l10n` is the source of generated `AppLocalizations`.
  Triggered automatically by `flutter pub get` (because `generate: true` is set
  in `pubspec.yaml`).
- `l10n.yaml` config: ARB files in `assets/l10n/`, generated Dart in
  `lib/ui/shared/l10n/generated/`, non-nullable `of()`.
- Default/template locale is `en` (`en.arb`). Additional locales sit
  alongside (`nl.arb`, etc).
- Access from widgets via the static façade in `lib/ui/shared/l10n/l10n.dart`:

  ```dart
  Text(L10n.translate.helloUser(user.name))
  ```

- **Never alias `L10n.translate`.** Do not write `final l = L10n.translate;`
  (or `final t = ...`, etc.) and then read `l.someKey`. Always reference
  `L10n.translate.someKey` directly at the call site, even when several keys
  are read in the same method. Aliases hide the static façade, make greps for
  `L10n.` miss usages, and add a local that doesn't carry its weight.

- `L10n.init(context)` is called once from `App.onGenerateTitle` — which always
  runs with a localised context, and re-runs on locale change. After that the
  static `L10n.translate`, `L10n.currentLocale`, and `L10n.loadLocale(...)`
  are available everywhere without passing `BuildContext`.
- `MaterialApp.router` is configured with `L10n.localizationsDelegates` and
  `L10n.supportedLocales`.
- Generated files under `lib/ui/shared/l10n/generated/` are **gitignored** and
  regenerated by `flutter pub get` (or `fvm flutter gen-l10n`). The analyzer
  also excludes them.
- l10n lives under `lib/ui/shared/` because the wrapper takes a `BuildContext`.
  If domain ever needs localized strings (e.g. for error messages crossing the
  wire), promote the strings/wrapper to `lib/shared/`.

---

## Environment banner

Non-prod builds render a corner ribbon with the current env name (`dev`,
`staging`, `local`) via Flutter's `Banner` widget, wired through the
`MaterialApp.router` `builder` callback in `lib/app.dart`. Prod renders no
banner. The default Flutter "DEBUG" banner is disabled
(`debugShowCheckedModeBanner: false`) so the env banner is the only ribbon
ever visible.

---

## Logging

- `ILogger` interface in `lib/shared/contracts/`.
- `LoggerService` wraps `package:logger`.
- Registered in GetIt early in bootstrap.
- Accessed via the global `log` in `lib/shared/log.dart`:

```dart
log.info('User signed in: ${user.id}');
log.error('Sync failed', error, stack);
```

- The dio interceptor logs HTTP traffic when `AppEnv.enableLogging` is true.

---

## Testing

- **`mocktail`** for mocks. No codegen.
- **`InMemoryPreferenceService`** is the default `IPreferenceService` in tests.
  All fakes live in `test/helpers/fakes/` and are imported via relative paths
  from the tests that use them.
- Test layout mirrors `lib/`:

```
test/
  data/repositories/user_repository_test.dart
  domain/use_cases/get_current_user_test.dart
  ui/features/profile/profile_page_test.dart
  helpers/
    di_test_helper.dart
    fixtures.dart
```

- Every test that uses `inject<T>()` (i.e. any domain or repository test)
  begins with `setUp(setupTestDi)`. `setupTestDi` calls `GetIt.I.reset()` then
  registers in-memory and mock implementations:

```dart
// test/helpers/di_test_helper.dart
Future<void> setupTestDi({
  IPreferenceService? prefs,
  Dio? dio,
}) async {
  await GetIt.I.reset();
  GetIt.I.registerSingleton<IPreferenceService>(prefs ?? InMemoryPreferenceService());
  GetIt.I.registerSingleton<ILogger>(NoopLogger());
  GetIt.I.registerSingleton<Dio>(dio ?? MockDio());
  // …repos use these via inject() internally
  GetIt.I.registerSingleton<UserRepository>(UserRepository());
}
```

- UI tests override Riverpod providers via `ProviderScope(overrides: [...])`.
- Test fixtures (sample DTOs/entities) live in `test/helpers/fixtures.dart`
  to avoid scattered ad-hoc builders.

---

## Linting & layer-boundary enforcement

A single Dart script enforces the import direction:

`tool/check_architecture_violations.dart` expresses the rules as a small `const` list:

```
(importerGlob, forbiddenImportGlob, reason)
─────────────────────────────────────────────────────────────────────────────
lib/data/**         lib/domain/**          'data must not depend on domain'
lib/data/**         lib/ui/**              'data must not depend on ui'
lib/domain/**       lib/ui/**              'domain must not depend on ui'
lib/ui/**           lib/data/**            'ui must not depend on data'
lib/ui/features/**  package:get_it/**      'widgets must not use get_it; '
lib/ui/features/**  inject<                'go through providers/notifiers'
                                           'use log.x() instead of inject<ILogger>'
```

It also enforces a **strict GetIt allow-list**: raw `GetIt.I` may appear *only*
in `lib/shared/inject.dart`. Anywhere else — including bootstrap and module
registration — must use `injector` (for `registerSingleton` / `reset`) or
`inject<T>()` (for typed lookup), both re-exported from the same helper.

The script reads each Dart file under `lib/`, scans `import` statements (and
the source for the `inject<` and `GetIt.I` text rules), and prints violations
+ exits non-zero on failure. It runs in <100ms and is invoked from lefthook on
both pre-commit and pre-push.

`dart_custom_lint` is **not** used — it is deprecated upstream. The official
replacement, `analysis_server_plugin`, is documented as a future option if
IDE-time feedback becomes worth the setup cost (see [Future](#future-considerations)).

`analysis_options.yaml` enables the strict-mode flags:

```yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
linter:
  rules:
    - always_declare_return_types
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - prefer_final_fields
    - prefer_single_quotes
    - unawaited_futures
    - avoid_dynamic_calls
    - avoid_returning_null_for_void
```

---

## Git hooks (lefthook)

`lefthook.yml`:

```yaml
pre-commit:
  parallel: true
  commands:
    format:
      run: dart format --set-exit-if-changed --output=none .
    analyze:
      run: dart analyze --fatal-infos
    layers:
      run: dart run tool/check_architecture_violations.dart

pre-push:
  parallel: true
  commands:
    format:
      run: dart format --set-exit-if-changed --output=none .
    analyze:
      run: dart analyze --fatal-infos
    layers:
      run: dart run tool/check_architecture_violations.dart
    test:
      run: flutter test
```

Skip when needed: `git push --no-verify` (standard git flag).

---

## Cloning the template

### Script

`tool/clone_template.dart` is invoked as:

```
dart run tool/clone_template.dart --name my_new_app --org com.example
```

It:

1. Copies the repo tree to a sibling directory `../my_new_app/`, excluding
   `.git`, `.dart_tool`, `build`, `env/local.json`.
2. Replaces `app` (the template's package name) → `my_new_app` in `pubspec.yaml`, every Dart
   `import` statement, and the iOS/Android bundle identifiers.
3. Replaces the Android package path (`com.datacadabra.track_and_trace` — kept
   as the template's native identifier suffix for now)
   → `<org>.<name>` in `MainActivity.kt` and `AndroidManifest.xml`.
4. Resets `env/*.json` to placeholder values.
5. `cd` into the new directory, runs `git init`, `flutter pub get`, and an
   initial commit.

The script keeps all example features in the new app; trimming is left to the
developer (a one-folder delete).

### Skill for LLM-driven scaffolding

`.claude/skills/clone-template/SKILL.md` defines a skill that wraps the script.
It asks the user a small Q&A (app name, org, primary features, backend
characteristics) and then invokes `clone_template.dart` plus any
feature-specific scaffolding. Intended for use from Claude Code.

---

## Future considerations

- **`analysis_server_plugin`** for IDE-time layer-boundary feedback. Heavier to
  maintain than the grep script; revisit when team friction makes it worth it.
- **Remote feature flags.** Add a `FeatureFlagsService` and a Riverpod provider
  wrapping it. Keep the `AppEnv` boolean flags as compile-time defaults.
- **Offline / cached repos.** Introduce abstract repository interfaces in
  `domain/` (or alongside the concrete repo in `data/`) only when a second
  implementation is real. Until then, the concrete class is the contract.
- **Hot env-swap.** Not planned. Restart is the contract.
