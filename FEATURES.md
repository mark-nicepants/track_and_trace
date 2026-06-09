# Feature Research — Track & Trace Flutter Port

**Domain:** Field-ops mobile app — continuous background GPS + offline-first sync + server-side activity prediction with user feedback (waste-disposal vehicle monitoring for a Dutch water board)
**Researched:** 2026-06-04
**Confidence:** HIGH (Android source is canonical; ecosystem norms verified against current Android 14 / iOS 17+ guidance and 2026 fleet-app comparisons)
**Mode note:** Validation-only — features are locked by Android parity. This research categorizes the existing inventory, surfaces what a customer might expect that the Android app does NOT do, and guards against scope creep.

---

## Executive Summary

The Android source already covers the **core operational loop** that defines this product category: continuous foreground-service GPS, offline SQLite queue with batch drain, server-side activity prediction with paired user feedback, dump-quantity capture with safety-net auto-confirm, crash-report self-upload, and a Dutch-only locked UI. That loop is the table-stakes set for a 2026 field-ops driver app and the Flutter port must replicate it 1:1.

The Android app is **deliberately minimal** in several areas where mainstream commercial fleet apps (Verizon Connect, Motive, Azuga, Fleetio) have expanded — no login/auth, no DVIR, no dashcam integration, no map view, no admin console on the device, no driver-behavior scoring. For this customer (Waterschap Vallei en Veluwe, vKK research-style measurement), that minimalism is correct: the app is a **data-collection instrument**, not a commercial fleet product. Most "missing" features would be anti-features here.

Two genuine gaps surface where a customer could be surprised: (1) **no in-app evidence of upload progress / queue health** (drivers don't see how many positions are queued, only "no network" when offline) and (2) **no GDPR/works-council transparency screen** for what is being collected, which is a Dutch employment-law expectation for GPS tracking of vehicles operated by workers. Both are flagged below as candidates for explicit OUT-OF-SCOPE confirmation rather than additions — the parity decision is locked, but the customer should sign off knowing these are deferred.

Battery posture is the one **parity item with a 2026 nuance**: 1-second GPS sampling for an entire shift is aggressive by modern standards. It is correct for this app's measurement purpose, but the Flutter port should be prepared to defend the choice (telemetry, on-device battery report) during the v1 field test because it will draw customer attention.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features a field operator and the operator's manager assume are present. All of these are in the Android source — the Flutter port replicates them.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Continuous background GPS with screen off | Drivers can't keep the screen on for an 8-hour shift; if GPS stops when the screen sleeps, the data is worthless | HIGH | Android: foreground service + `FOREGROUND_SERVICE_LOCATION` (Android 14 type required, see Android docs). iOS: `UIBackgroundModes: location` + Always authorization. Already in Android source §6. |
| Persistent foreground notification while tracking | Required by Android 14+, and a 2026 user-trust expectation: drivers should see at a glance that tracking is active | LOW (after FG service) | `flutter_foreground_task` provides the notification. Use Dutch copy. |
| Offline-first local queue for GPS positions | Vans regularly enter dead zones; data loss is unacceptable for a measurement program | HIGH | Already in Android source §7 (sqflite, ≤5/batch, 5 s retry). Use `last-write-wins` per modern offline-first guidance for any future conflict cases. |
| Sync drain on connectivity return | "Auto-uploads when reconnected" is the table-stakes user model | MEDIUM | Already in Android source — `SendingService` reads up to 5 rows, posts, deletes on success. |
| Permission flow with rationale and settings deep-link | iOS/Android both gate behavior on a permanently-denied state; users need a way back to settings | LOW | Already in Android source §2. `permission_handler.openAppSettings()` on Flutter. |
| Permission rationale in user's language | Apple App Review and the Play Console reject vague rationale strings | LOW | Dutch copy already specified in §12. Add `NSLocationAlwaysAndWhenInUseUsageDescription` etc. |
| Visible tracking-active indicator on the active screen | Drivers need confidence the app is actually recording (table stakes — measurement is invisible otherwise) | LOW | Already in Android source §5.1 (icon flips ON/OFF). |
| Start / Pause / Stop controls for a "run" | The mental model is a discrete trip; without explicit boundaries the data is uninterpretable | LOW | Already in Android source §5.3. |
| Stop-confirmation dialog | A misclicked Stop discards the rest of the shift; must require confirmation | LOW | Already in Android source §5.3 ("Weet u zeker…"). |
| Disable system back gesture during tracking | Same reason as Stop confirmation — accidental gesture ends a run | LOW | Already in Android source §3. Flutter: `PopScope(canPop: false)` on TrackingScreen. |
| Keep screen awake during tracking | Drivers should not have to babysit screen timeout for an 8-hour shift | LOW | Already in Android source §3. `wakelock_plus`. |
| Crash detection + log upload | Standard for any production mobile app; this one is operating critical measurement, so post-crash recovery visibility is a must | MEDIUM | Already in Android source §8 (EXITED_CORRECTLY flag, file logs, `/forward-logs` zip). |
| Network-loss user feedback | If the user thinks tracking is broken when actually only feedback is paused, they may stop the run prematurely | LOW | Already in Android source §5.3 (`NoNetworkDialog`). |
| Vehicle configuration persistence across launches | A driver shouldn't re-enter machine type + capacity every shift | LOW | Already in Android source §4.3. `shared_preferences`. |
| Dutch UI only | Single-customer Dutch product; not a localization platform | LOW | Already in Android source §12. Verbatim copy is locked. |
| ISO datetime format matching backend parser | Backend rejects deviating formats; one of the most common port bugs | LOW | Locked: `yyyy-MM-dd'T'HH:mm:ss.SSS`. |

### Differentiators (Competitive Advantage)

Features that distinguish this app from a generic fleet-tracking product. All exist in the Android source.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Server-side ML activity prediction with paired user feedback | The vKK measurement program needs *labelled* training data — every shift produces ground-truth pairs (predicted state vs operator-confirmed state). Standard commercial fleet apps don't have this loop. | HIGH | Already in Android source §6.3 (PredictionService 2 s poll), §5.2 (predicted vs feedback badges). Core to product purpose. |
| 4-way activity feedback grid (Rijden / Opladen / Storten / Stilstaan) | Captures driver intent precisely enough to label the GPS trace post-hoc | LOW | Already in Android source §5.1. |
| Dump-size quantity capture with 5-option radio + auto-confirm-to-FULL | Quantitative dump volumes are the actual output of the vKK measurement; the 5-min auto-FULL is a brilliant safety-net so a busy driver never silently skips it | MEDIUM | Already in Android source §5.4. Auto-confirm timer is the cleverest piece of UX in the app — preserve it exactly. |
| One-dump-dialog-per-dump-cycle guard | Prevents repeated nagging if the driver toggles DUMPING → DRIVING → DUMPING — only one quantity recorded per dumping episode | LOW | Already in Android source §5.2 (`shownDumpsizeDialogThisDump`). |
| Conditional nearest-depot lookup (only while DRIVING feedback) | Saves bandwidth + battery; depot data is only useful contextually | LOW | Already in Android source §5.3. |
| 1-second GPS sampling | Higher resolution than typical fleet apps (which use 15-30 s); produces denser trace data for vKK analysis | HIGH battery cost | Already locked. See pitfalls — this is the right choice for *measurement* but should be defended with field telemetry. |
| Parallel `/create-dump-size` + `/sync-run-data` on confirm | Provides two independent server-side records for cross-validation | LOW | Already in Android source §5.4. Don't remove the duplication on the port — it's intentional. |
| Crash-self-report with multipart zip upload | Field devices are physically remote; ops needs logs without "send me a screenshot" | MEDIUM | Already in Android source §8.3. `/forward-logs` endpoint. |
| Single-build env switch (debug menu, no flavors) | Lets ops swap dev/prd at the device without rebuilding — useful in this small-fleet, hand-distributed deployment | LOW | Decided this session in PROJECT.md. |
| Strict feature parity with Android | The customer trusts the Android UX; swapping platform should not change behaviour. Differentiator vs a "rewrite from spec" that would drift. | — | Locked decision in OFFERTE §2. |

### Anti-Features (Tempting But Out-of-Scope)

These features show up on every "best fleet app 2026" listicle and will be the first things suggested when the customer reviews the Flutter build. Document them explicitly so the parity boundary holds.

| Feature | Why Requested | Why Problematic Here | Alternative |
|---------|---------------|---------------------|-------------|
| **In-app live map / breadcrumb view** | Universal in commercial fleet apps (Verizon, Motive, Azuga). Drivers and managers will say "I want to see the route on the map." | Not in Android source. Adds a map SDK (Google Maps / Mapbox) cost + key management + tile caching. The backend, not the app, is the place to visualize traces for vKK analysis. Adds rendering load on a device already doing 1 Hz GPS. | Manager visualization belongs in the Cloud Run backend's dashboard, not on the driver's phone. Direct customer to backend tooling. |
| **Driver behavior scoring / harsh-braking alerts** | Stock 2026 fleet feature (Azuga, Motive, Tourmo) | Not what this app measures. vKK is about dump quantity + activity classification, not driving style. Adds accelerometer plumbing and a scoring algorithm with no business owner. | Stay focused on the measurement mission. |
| **DVIR (Daily Vehicle Inspection Report)** | FMCSA Feb 2026 final rule on electronic DVIR is U.S.-only but European fleet apps are adopting similar pre-trip checks | This is a Dutch water board, not a regulated U.S. carrier. Not requested. Adds a forms framework, signature capture, photo upload — significant scope. | Defer to v2 if customer raises it; not part of vKK measurement. |
| **Dashcam / video integration** | Every commercial fleet product is pushing AI dashcam integration in 2026 | Massive scope, hardware dependency, privacy / DPIA explosion for worker monitoring under GDPR + Dutch works-council rules. Currently nowhere in spec. | Hard NO. Refer customer to dedicated dashcam vendors if interested. |
| **Driver login / multi-driver per device** | Standard in fleet apps with shared vehicles | Android app has zero auth — one app install = one driver. If the customer raises this, it's a backend identity problem first, not a v1 app problem. | Defer. Customer-side: assign device 1:1 to driver/vehicle. |
| **Biometric / PIN unlock** | 2026 field-app best practice when handling worker data | No PII enters the app from the driver (machine type + capacity only). No need for unlock gate. Fingerprint adds permission, friction, edge cases. | Defer until app stores PII. |
| **In-app run history / "my previous shifts" view** | Drivers like seeing their own data | The Android app does NOT expose this — runs are write-only from the device. The backend owns history. Adding it would require new endpoints + caching + a list UI. | Stay write-only. Backend dashboard handles history. |
| **Push notifications for dispatch / route assignments** | Universal in 2026 fleet apps | Backend doesn't push dispatch; routes are operator-driven. Adds FCM/APNs plumbing, server-side push key management. Out of scope per OFFERTE §2 ("backend / API … stays as-is"). | Skip. |
| **Real-time fleet manager view inside the app** | Common in apps with role-switching | This is a driver-only app. Manager UX is web. | Out of scope. |
| **Geofencing alerts** (entered/left a zone) | Standard fleet feature, highlighted for waste collection in domain articles | Not in Android source. The backend can geofence post-hoc from the breadcrumb trail. Adding client-side geofence introduces fragile region monitoring. | Server-side post-hoc analysis only. |
| **Offline maps / route assistance** | Stock fleet feature | App does not navigate. Drivers know their routes. | Skip. |
| **Per-event sync (instead of 5-position batches)** | "Real-time everything" intuition | Batching is the correct offline-first pattern. Per-event sync would multiply backend calls 5×. | Keep batch of 5. |
| **Switch to `flutter_background_geolocation` (paid SDK) for v1** | "Best-in-class background tracking" tempting on day one | Already decided against in PROJECT.md — use free `background_location` first, re-evaluate with field battery telemetry. | Honor decision; re-open only if telemetry forces it. |
| **`freezed` / `json_serializable` / `drift` / `@riverpod` codegen** | "Modern Flutter" defaults | Explicitly excluded in PROJECT.md and FEATURES.md §13. Manual models are the contract. | Keep manual. |
| **Switching crash reporter to Sentry "while we're rewriting anyway"** | Sentry has a nicer DX | Backend ops already consumes New Relic. Behavioral change for ops = real cost. | Keep New Relic. |
| **Tablet / landscape layouts** | Form-factor flexibility | App runs on phones mounted in vehicle cradles. Single portrait phone target is sufficient. | Phone-portrait only. |
| **Localization framework (i18n) for future languages** | "Easy to add later" | One Dutch customer; YAGNI. `l10n/nl.dart` const map is enough. | Const string map per FEATURES.md §13.2. |
| **Driver photo capture / scene attachments to a dump event** | Drivers in some fleets like attaching photos as evidence | Not in spec; adds permission (camera), upload size explosion, retention/DPIA implications. | Defer. |

### Customer-Surprise Gaps (Features the Android App Does NOT Have That A Customer Might Expect)

These are not anti-features (the customer could legitimately ask) but also not parity items. Surface them now so the customer signs off on their absence rather than discovering it mid-test.

| Feature | Why a Customer Would Expect It | Android Source Status | Recommendation |
|---------|-------------------------------|----------------------|----------------|
| Visible **upload-queue depth indicator** ("47 positions pending upload") | Drivers/managers ask "is it sending?" — and the answer is currently only "we have/don't have network." With offline-first apps, queue visibility is now an emerging best practice (queued / syncing / synced / failed states). | Not present. The Android app only surfaces binary `networkAvailable`. | **Defer to v2 backlog explicitly.** Calling this out in the OFFERTE/PROJECT delivery notes prevents the question after delivery. The Flutter `LocalPositionQueue` could expose a debug count for the debug menu without scope creep. |
| **GDPR / privacy transparency screen** | Dutch GDPR + works-council rules require workers be informed about GPS tracking. The Dutch DPA (Autoriteit Persoonsgegevens) publishes guidance specifically for works-council review. Many EU field-ops apps include a "what we collect" screen reachable from settings. | Not present. Presumed handled by employer's onboarding / works-council agreement outside the app. | **Confirm with customer.** If the water board's works-council DPIA already covers this externally, no app change is needed. If not, a single static info screen is ~1 hour of work and very low risk. Either way: get an explicit decision so it isn't an audit surprise. |
| **Debug-menu visibility of current run state** | Field troubleshooting (`runId`, last upload time, queue size, backend URL in use) | The Android app has a debug build but the in-app debug menu is sparse | **Already approximated** by the persisted-env-override decision; consider extending the debug menu in the Flutter port (within v1 scope) to show `runId`, queue depth, last upload result, current env. ~1-2 hours, large field-support payoff. |
| **Driver identifier (some label they can verify on the device)** | Multi-vehicle fleets normally identify who's driving | Not present — device = vehicle, identity is implicit via device assignment | **Defer**; current model is fine if device assignment is 1:1 with operator. Flag for customer to confirm. |
| **Long-press / hidden way to recover from a hung run** | Sometimes a run stops being uploaded because the app got into a bad state; field-support recovery hatch | Not present | Out of scope for v1; manageable via the existing "Stop" + clean relaunch. Document in README. |
| **Battery telemetry visible to ops** | When battery drain becomes an issue, ops need data | Not present | Out of scope; field test (Work Package #7) provides the first dataset. |

### Known-Bad-in-2026 Patterns in Android Source (Flag, Don't Fix)

Patterns in the Android app that are dated by modern standards. The parity decision means we keep them — but the Flutter team should know they're known-dated.

| Pattern | Why Dated | Why Keep | Mitigation |
|---------|-----------|----------|------------|
| **1-second GPS sampling for entire shift** | Modern guidance (Apple Energy Guide, Hypertrack, fleet best-practice articles) recommends adaptive sampling — coarse when stationary, fine when moving, leverage `significantLocationChanges` or motion detection. 1 Hz across an 8-hour shift is roughly 5-10× the energy budget of an adaptive approach. GPS *transmission* is 5-10× more expensive than collection. | The vKK measurement program needs the high-resolution traces; this is a data-collection app, not a navigation app. Reducing the rate changes what's measured. | Field-test battery on real devices (Work Package #7). If unacceptable, raise change request — do not silently reduce sampling. |
| **5-second polling for prediction status** | Long-poll or server-push (SSE / WebSocket) is the modern way to surface server-side state. 2 s polling is cheap on Wi-Fi, expensive on cellular over an 8-hour shift. | Backend is locked (OFFERTE §2 "no API changes"). | Document for v2 backend redesign. |
| **5-second polling for nearest depot (while DRIVING)** | Same as above | Same as above | Same as above |
| **Plain `Float` capacity (no unit type, no clamp upper bound)** | Modern field apps use stronger validation (e.g., max plausibility check 0 < x < 100 m³ for kippers) | Domain-acceptable; backend can clamp | Add a soft sanity upper bound (e.g., 0 < x ≤ 50 m³) on the Flutter port — same UX, friendlier error. Validate with customer if 50 is plausible. |
| **No request idempotency keys on `/create-feedback` / `/create-dump-size`** | Modern offline-first guidance recommends an idempotency key per outbound event so retries don't double-write. Currently feedback is fire-and-forget; double-writes would silently corrupt training data. | Backend is locked. | Backend already accepts duplicates as-is; flag for v2. |
| **No exponential backoff on upload retry (fixed 5 s)** | Modern queue drain uses exponential backoff with jitter (e.g., Android WorkManager pattern). Constant 5 s wastes battery in long outages. | Parity says keep. | Acceptable for now; consider exponential backoff in v1.x if telemetry shows long outages. |

---

## Feature Dependencies

Critical ordering for roadmap phases — A → B means A must work before B can be built or tested.

```
Permissions screen (location + notifications)
    └──required-by──> LocationService
                          └──required-by──> Run lifecycle (create-run / GPS / stop-run)
                                                  └──required-by──> Position queue + batched upload
                                                  └──required-by──> Prediction polling
                                                                          └──required-by──> Dump-size dialog (triggered by DUMPING prediction)
                                                  └──required-by──> Feedback grid
                                                                          └──required-by──> Nearest-depot polling (DRIVING feedback only)
                                                                          └──required-by──> Dump-size dialog (also triggered by DUMPING feedback)

Connectivity stream (connectivity_plus)
    └──drives──> NoNetworkDialog
    └──drives──> Upload-retry timing (drain on reconnect)

EXITED_CORRECTLY flag
    └──drives──> Crash screen + log upload

Dio + env config
    └──required-by──> All 10 endpoints

shared_preferences
    └──required-by──> Setup persistence (machine type + capacity)
    └──required-by──> Env override (debug menu)
    └──required-by──> EXITED_CORRECTLY flag
    └──required-by──> Cached machine types

IsoClock (single time abstraction)
    └──required-by──> Every endpoint with a time field (almost all)
    └──required-by──> TrackingPosition validation

Manual data models (domain entities)
    └──required-by──> DTOs (data layer)
                            └──required-by──> Repositories
                                                  └──required-by──> Controllers (Riverpod)
                                                                          └──required-by──> Widgets
```

### Dependency Notes (Roadmap-Critical)

- **Dump-size dialog requires DUMPING activity state from either prediction service or feedback grid.** Either path can trigger it; both must be wired before the dialog itself can be tested end-to-end. Implication: build the activity state machine *first*, then the dump dialog as a consumer.
- **Position queue must exist before LocationService is useful.** The LocationService writes to the queue; without persistence, GPS events vanish on backgrounding. Build sqflite queue + DAO before wiring the location plugin.
- **Connectivity stream must precede SendingService.** Drain logic listens to it; otherwise SendingService either always-tries (wasteful) or never-tries (broken).
- **Permission flow must precede everything else operational.** No permissions → no location → no run → no anything. This is the natural first phase after scaffolding.
- **EXITED_CORRECTLY flag must be set before LocationService starts** and only cleared on clean shutdown. Crash detection on next launch depends on this ordering being correct — easy to get wrong.
- **`shownDumpsizeDialogThisDump` reset depends on activity state transitions** (typically DUMPING → LOADING). The state machine in §5.2 is small but precise — test transitions exhaustively.
- **All 10 endpoints depend on the Dio client + env config.** Build env switch + Dio scaffold before any feature-level repository.

### Conflicts (Features That Cannot Coexist)

- **Nearest-depot polling vs non-DRIVING feedback.** Polling must stop when feedback leaves DRIVING (per §5.3) — failure to do so leaks bandwidth and battery and is testable as a regression.
- **`background_location` vs `flutter_background_geolocation` (Transistor).** Two background-location plugins cannot coexist on one device. Decision is `background_location`; do not add Transistor "for safety."
- **Multiple `Notifier`-style flutter_foreground_task instances.** Only one foreground service binding; combine LocationService + SendingService + PredictionService logic under a single service host or use Dart isolates with one bound foreground task.

---

## MVP Definition

### Launch With (v1 — the 59-hour build)

This entire list is non-negotiable because parity is the contract. Items are sequenced for the roadmap, not by importance.

- [ ] **Project scaffold** — Flutter + Riverpod 3 (manual) + Dio + sqflite + go_router + Clean Architecture layering per FEATURES.md §13
- [ ] **Env config + Dio interceptors** — `kReleaseMode` default + persisted debug-menu override
- [ ] **IsoClock + manual data models for domain entities** — `TrackingPosition`, `MachineType`, `Run`, `Feedback`, `DumpSize`, `ActivityState`, `NearestDepot`
- [ ] **Permission flow** (location + notifications, rationale, settings deep-link, queue-based prompts) — table stakes
- [ ] **MainScreen → SetupScreen → TrackingScreen navigation** with `go_router` redirect-based permission gating
- [ ] **SetupScreen** — `/get-machine-types` load, validation (capacity > 0), persistence
- [ ] **LocationService** — 1 Hz GPS with foreground notification, writing to sqflite queue
- [ ] **Position queue + SendingService** — batch of 5, 5 s retry, drain on reconnect
- [ ] **Run lifecycle** — `/create-run` on mount, `/stop-run` on confirm
- [ ] **PredictionService** — 2 s poll of `/get-status`, predicted-state badge
- [ ] **Feedback grid** with `/create-feedback` fire-and-forget
- [ ] **Nearest-depot polling** — 10 s, DRIVING-only, label render
- [ ] **Dump-size dialog** — 5 options + 5-min auto-FULL + parallel `/create-dump-size` and `/sync-run-data` + one-dump-per-cycle guard
- [ ] **NoNetworkDialog** driven by connectivity stream
- [ ] **Crash detection** — `EXITED_CORRECTLY` flag + rotating file logs (1 MB × 3) + `/forward-logs` upload flow
- [ ] **wakelock_plus + PopScope back-disable** on TrackingScreen
- [ ] **Dutch UI copy verbatim** from FEATURES.md §12
- [ ] **New Relic SDK** initialization in `main.dart`
- [ ] **Tests** — domain unit, repository tests with `MockAdapter` + `sqflite_common_ffi`, controller tests via `ProviderContainer`, key widget tests
- [ ] **README** with build/release instructions for iOS `.ipa` + Android `.aab`/`.apk`
- [ ] **Structured feedback round** (OFFERTE Work Package #7)

### Suggested Tiny Additions Within v1 Scope (Low-Cost, High Field-Support Payoff)

These are NOT in the Android source but are very cheap to add and pay back during the test round / first weeks of operation. Confirm with customer; if any is declined, simply skip.

- [ ] **Extended debug menu** showing `runId`, last-upload-result + timestamp, position-queue depth, current env, build number. ~1-2 h. Massive field-support payoff. The Android app's debug menu is sparse; the port has a chance to make remote diagnosis much easier without changing user-facing UX.
- [ ] **Soft upper bound on capacity input** (e.g., 0 < x ≤ 50 m³) with a friendlier error than the current `>0` check. ~15 min. Confirm 50 with customer.

### Add After v1 Validation (v1.x — Customer-Backlog Candidates)

Trigger: customer asks for it after the test build, or field telemetry justifies it.

- [ ] **Upload-queue depth indicator** in the tracking UI ("47 positions pending")
- [ ] **Privacy / GDPR transparency screen** (only if works-council DPIA needs it in-app)
- [ ] **Adaptive GPS sampling** (motion-aware) — *only* if Work Package #7 battery telemetry forces it
- [ ] **Exponential backoff with jitter** on upload retry
- [ ] **Soft upper bound on capacity input** if not added in v1
- [ ] **Switch to `flutter_background_geolocation`** — *only* if `background_location` battery posture is unacceptable on real devices

### Future Consideration (v2+ — Out of Scope of This Quote)

Defer regardless. Bring up only if explicitly requested by customer.

- [ ] In-app live map / breadcrumb view
- [ ] Driver login / multi-driver-per-device
- [ ] Run history view on device
- [ ] Push notifications for dispatch
- [ ] DVIR / pre-trip inspection
- [ ] Dashcam integration
- [ ] Driver-behavior scoring
- [ ] Geofencing
- [ ] Offline maps
- [ ] Backend redesign for SSE / WebSocket (eliminating 2 s polling)
- [ ] Request idempotency keys
- [ ] Localization beyond Dutch

---

## Feature Prioritization Matrix

All v1 features are P1 (parity is the contract). Listing the cross-cutting "extras" considered above for explicit triage.

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Permission flow with rationale | HIGH | LOW | P1 (parity) |
| Background GPS + foreground notification | HIGH | HIGH | P1 (parity) |
| Offline queue + batched upload | HIGH | HIGH | P1 (parity) |
| Prediction polling + feedback grid | HIGH | MEDIUM | P1 (parity) |
| Dump-size dialog with auto-confirm | HIGH | MEDIUM | P1 (parity) |
| Nearest-depot polling (DRIVING-only) | MEDIUM | LOW | P1 (parity) |
| NoNetworkDialog | MEDIUM | LOW | P1 (parity) |
| Crash detection + log upload | MEDIUM | MEDIUM | P1 (parity) |
| Dutch copy verbatim | HIGH | LOW | P1 (parity) |
| Env switch with debug-menu override | MEDIUM | LOW | P1 (parity decision) |
| **Extended debug menu (runId, queue, last upload)** | MEDIUM (field-support) | LOW | **P2 (add if time allows in v1)** |
| **Soft upper bound on capacity** | LOW | LOW | **P2 (add if time allows in v1)** |
| Upload-queue depth indicator (visible to driver) | MEDIUM | MEDIUM | P3 (v1.x) |
| GDPR / privacy transparency screen | LOW (in-app) | LOW | P3 (depends on customer DPIA position) |
| Adaptive GPS sampling | HIGH (if battery is a problem) | HIGH | P3 (data-driven trigger) |
| Exponential backoff with jitter | LOW | LOW | P3 (v1.x) |
| In-app map view | MEDIUM | HIGH | P3+ (out of scope) |
| Driver login | MEDIUM | HIGH | P3+ (out of scope) |
| Dashcam / behavior scoring / DVIR | LOW (for this customer) | HIGH | NEVER (anti-feature) |

---

## Competitor Feature Analysis

Reference points are stock commercial fleet apps in 2026. The intent of this table is to show what those products do that *we deliberately don't* — to ground the anti-feature list.

| Feature | Verizon Connect / Motive / Azuga (commercial fleet apps) | Track & Trace (this app) | Why We Diverge |
|---------|---------------------------------------------------------|--------------------------|----------------|
| GPS sampling rate | 15-30 s typical; some 10 s premium | 1 s | Measurement app, not a fleet-management app; vKK needs density |
| Driver authentication | Mandatory (PIN / biometric) | None | Single-device-per-driver assignment; works-council-blessed scope |
| Live map view | Always present | None | Backend dashboard responsibility |
| Activity / status reporting | Trip auto-detected from telematics events (engine on/off, harsh events) | Operator labels (LOADING/DRIVING/DUMPING/STANDING_STILL) + server-side ML prediction | We are *generating* labelled training data, not consuming it |
| Quantity capture (dump size) | Not a thing in commercial apps | Core feature with 5-option radio + auto-FULL | Domain-specific (waste-collection measurement) |
| Vehicle inspection (DVIR) | Standard 2026 feature | None | Different domain; not regulated DOT/FMCSA equivalent |
| Push notifications | Heavy use (dispatch, alerts, geofences) | None | Driver-initiated workflow; no dispatch loop |
| Offline-first | Variable; some products tolerate offline poorly | Strong — local sqflite queue, batch drain | Field operates in rural Netherlands with cellular dead zones |
| Crash self-report | Crashlytics / Sentry server-side (silent) | Active driver-confirmed log upload | Field devices remote; ops needs explicit recovery path |
| Localization | Multi-language | Dutch only | Single customer |
| Background-location plugin | Heavily-licensed commercial SDKs | `background_location` (MIT) | Cost / licensing avoided in v1 |
| Crash reporter | Sentry / Crashlytics typical | New Relic | Mirror existing Android setup |
| Map data | Google / Mapbox | None on device | Backend rendering only |

---

## Implications for Roadmap

Concrete recommendations the roadmap phase can act on.

1. **Phase ordering must follow dependencies**: Scaffold/Env → Permissions → Setup → Run lifecycle + LocationService + Queue → Upload (SendingService) → Prediction + Feedback → Dump dialog + Depot polling → Crash → Hardening + Tests + Release. (This roughly matches OFFERTE's WP1-WP7 split.)
2. **The "boring" foundations are HIGH-complexity**: LocationService + Queue + SendingService is where most of the schedule risk sits, not the UI. Allocate buffer accordingly within the 59-hour budget.
3. **Treat parity as a checklist gate, not a goal**: Every feature item above (the v1 list) is verifiable against the Android source — make the test plan reference the exact section of FEATURES.md root document.
4. **Surface the "customer-surprise gaps"** (queue indicator, privacy screen) in the kickoff or test-round notes so the customer signs off on their absence proactively.
5. **Reserve a quick win**: the extended debug menu addition (P2, ~1-2 h) is a high-leverage low-cost item that should be slotted into WP5 or WP6 if there is any slack.
6. **Field-test priority items** (Work Package #7): battery posture at 1 Hz GPS, queue drain behavior under intermittent cellular, dump-dialog auto-confirm reliability after 5 minutes background, crash-self-report path. These are the only items where Android parity does *not* automatically transfer because the runtime differs.

---

## Sources

- [Mobile Fleet Management App for Construction Teams: Field-Ready Features in 2026 — Fleetrabbit](https://fleetrabbit.com/industry/construction-management-system/mobile-fleet-management-app-construction-teams-2026)
- [Best 2026 Fleet Management Apps for Android & iOS — Oxmaint](https://oxmaint.com/industries/fleet-management/best-fleet-management-apps-android-ios-2026)
- [Best Fleet Management App 2026: Complete Buyer's Guide](https://heavyvehicleinspection.com/article/best-fleet-management-app)
- [6 Best Fleet Tracking Apps for Real-Time GPS Monitoring — Fleetio](https://www.fleetio.com/blog/fleet-tracking-app-7-must-have-features)
- [Choosing a waste management telematics product — Motive](https://gomotive.com/blog/waste-management-telematics/)
- [Revolutionizing Waste Management through GPS Fleet Management & Telematics — LVM Tech](https://www.lvmtech.com/revolutionizing-waste-management-through-gps-fleet-management-telematics/)
- [Apple Energy Efficiency Guide for iOS Apps — Location Best Practices](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/LocationBestPractices.html)
- [Real-time location tracking with near-zero battery impact — Hypertrack](https://hypertrack.com/blog/2017/06/10/zero-battery-location-tracking/)
- [Optimizing iOS location services — Rangle](https://rangle.io/blog/optimizing-ios-location-services)
- [Build an offline-first app — Android Developers](https://developer.android.com/topic/architecture/data-layer/offline-first)
- [Offline-First Mobile App Architecture: Syncing, Caching, and Conflict Resolution — DEV](https://dev.to/odunayo_dada/offline-first-mobile-app-architecture-syncing-caching-and-conflict-resolution-518n)
- [Offline Sync for Field Teams: Which Mobile Apps Actually Work in Dead Zones — Wednesday](https://mobile.wednesday.is/writing/offline-sync-mobile-apps-field-teams-dead-zones-2026)
- [Foreground service types — Android Developers](https://developer.android.com/develop/background-work/services/fgs/service-types)
- [Foreground service types are required — Android Developers](https://developer.android.com/about/versions/14/changes/fgs-types-required)
- [Employee Monitoring And Privacy In The Netherlands — Law & More](https://lawandmore.eu/employee-monitoring-and-privacy-in-the-netherlands-what-employers-may-and-may-not-do/)
- [Monitoring employees — Autoriteit Persoonsgegevens (Dutch DPA)](https://www.autoriteitpersoonsgegevens.nl/en/themes/employment-and-benefits/monitoring-employees)
- [Works councils and data privacy rights — HewardMills](https://www.hewardmills.com/works-councils-and-data-privacy-rights/)
- [2026: 10 Mobile App Features That Improve Field Productivity — Skillcat](https://www.skillcatapp.com/post/mobile-app-features-improve-field-technician-productivity)
- [5 Best Field Service Mobile Apps for Technicians in 2026 — Arrivy](https://www.arrivy.com/blog/best-field-service-mobile-apps-for-technicians/)

---
*Feature research for: field-ops GPS tracking app (Track & Trace Flutter port)*
*Researched: 2026-06-04*
*Confidence: HIGH (parity inventory canonical; ecosystem gaps verified against current sources)*
