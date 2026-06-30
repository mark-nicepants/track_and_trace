import 'dart:async';
import 'dart:convert';

import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/use_cases/enqueue_position.dart';
import 'package:app/domain/use_cases/get_nearest_depot.dart';
import 'package:app/domain/use_cases/send_feedback.dart';
import 'package:app/domain/use_cases/start_run.dart';
import 'package:app/domain/use_cases/stop_run.dart';
import 'package:app/shared/contracts/i_foreground_tracking_service.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:app/shared/contracts/i_log_export_service.dart';
import 'package:app/shared/contracts/i_prediction_service.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/contracts/i_sending_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:app/ui/features/tracking/tracking_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives the whole tracking screen lifecycle:
///   1. On [start]: reads saved machine type + capacity, POSTs
///      `/create-run`, retains the runId, sets `EXITED_CORRECTLY=false`,
///      starts LocationService + SendingService + PredictionService.
///   2. Subscribes to [ILocationClient] and enqueues each GPS fix.
///   3. Subscribes to [IPredictionService.predictions] and folds the
///      predicted [ActivityState] into [TrackingState]. Resets the
///      `shownDumpsizeDialogThisDump` guard on transitions OUT of
///      `DUMPING`.
///   4. Operator feedback ([selectFeedback]) updates `feedbackState`
///      immediately, fires `/create-feedback` fire-and-forget, and toggles
///      the nearest-depot polling job iff the chosen state is `DRIVING`.
///   5. On [stop]: cancels everything, POSTs `/stop-run`, sets
///      `EXITED_CORRECTLY=true`.
///
/// Widgets must read state through this notifier — they never touch
/// platform plugins, repositories, or use cases directly.
class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<LocationFix>? _locationSub;
  StreamSubscription<String>? _predictionSub;
  Future<void> _writeChain = Future.value();
  Timer? _depotTimer;
  Future<void>? _depotInFlight;

  IPreferenceService get _prefs => inject();
  ILocationClient get _client => inject();
  IForegroundTrackingService get _fg => inject();
  ISendingService get _sender => inject();
  IPredictionService get _prediction => inject();
  ILogExportService get _logExport => inject();

  /// Set in [ref.onDispose] so the async [_loadSettings] read can't push a
  /// `state =` after the provider is torn down (which would throw).
  bool _disposed = false;

  /// Polling cadence for `/get-nearest-depot` while feedbackState is
  /// DRIVING. Production = 5 s (per FEATURES.md §6.3). Overridable for
  /// tests; declared as a field so the test can shrink it.
  Duration nearestDepotPollInterval = const Duration(seconds: 5);

  @override
  TrackingState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      unawaited(_locationSub?.cancel());
      _locationSub = null;
      unawaited(_predictionSub?.cancel());
      _predictionSub = null;
      _stopDepotPolling();
    });
    // Surface the saved vehicle/capacity for the settings label as soon as
    // the screen mounts, before any run is started.
    unawaited(_loadSettings());
    return TrackingState.initial;
  }

  bool get isTracking => state.isTracking;

  /// Boots the run. Reads machine type + capacity from prefs, POSTs
  /// `/create-run`, and starts the location/sending/prediction services.
  /// Idempotent — re-entrant calls while a run is already active are
  /// no-ops.
  Future<void> start() async {
    if (state.isTracking || state.starting) return;

    final saved = await _readSavedMachine();
    if (saved == null) return;
    final (machineTypeId, capacity) = saved;

    // Flip into the "starting" state so the screen can disable the Start
    // button and show "Aan het starten" while `/create-run` is in flight.
    state = state.copyWith(starting: true);

    await _prefs.writeString(exitedCorrectlyKey, 'false');

    final String runId;
    try {
      runId = await StartRun(machineTypeId, capacity).call();
    } catch (e) {
      // Roll back the EXITED_CORRECTLY flag so a future, successful start
      // can re-prime crash detection, and surface the failure so the
      // screen can show a dialog with the HTTP status code.
      await _prefs.writeString(exitedCorrectlyKey, 'true');
      state = state.copyWith(starting: false, startError: e);
      return;
    }

    await _fg.start(title: trackingNotificationTitle, body: trackingNotificationBody);
    await _sender.start();

    _writeChain = Future.value();
    _locationSub = _client.watch(interval: const Duration(seconds: 1)).listen((fix) {
      _writeChain = _writeChain.then((_) async {
        await EnqueuePosition(fix, runId).call();
      });
    });

    _predictionSub = _prediction.predictions.listen(_onPrediction);
    await _prediction.start(runId);

    state = state.copyWith(runId: runId, starting: false);
  }

  /// Stops the run: cancels GPS + prediction, flushes pending queue
  /// writes, stops the sender + foreground notification, POSTs `/stop-run`
  /// for the active runId, then flips `EXITED_CORRECTLY=true`. Returns
  /// `true` on success, `false` if `/stop-run` threw. The notifier is
  /// reset back to [TrackingState.initial] regardless so the screen can
  /// navigate away.
  Future<bool> stop() async {
    final runId = state.runId;
    if (runId == null) return true;
    state = state.copyWith(stopping: true);

    await _locationSub?.cancel();
    _locationSub = null;
    await _writeChain;

    await _predictionSub?.cancel();
    _predictionSub = null;
    await _prediction.stop();
    _stopDepotPolling();

    await _sender.stop();
    await _fg.stop();

    var success = true;
    try {
      await StopRun(runId).call();
    } catch (_) {
      success = false;
    }

    await _prefs.writeString(exitedCorrectlyKey, 'true');

    // Clear run-specific state but keep the saved vehicle/capacity: they are
    // independent of the run lifecycle (see TrackingState doc). Wiping them
    // here left the settings label showing `trackingVehicleNone` when the
    // (keep-alive) provider was reused on a later visit to the screen.
    state = TrackingState.initial.copyWith(machineTypeName: state.machineTypeName, capacity: state.capacity);
    return success;
  }

  /// Clears the create-run failure once the screen has surfaced it, so a
  /// retry can raise a fresh error.
  void clearStartError() {
    if (state.startError != null) state = state.copyWith(clearStartError: true);
  }

  /// Reloads the saved vehicle/capacity into [TrackingState] after an
  /// in-place edit so the settings label reflects the new values.
  Future<void> refreshSettings() => _loadSettings();

  /// Zips the on-disk log files into an archive and returns its path for
  /// the platform share sheet, or `null` when there are no logs yet.
  Future<String?> prepareLogArchive() => _logExport.exportLogArchive();

  Future<void> _loadSettings() async {
    final (name, capacity) = await _readSavedSettings();
    if (_disposed) return;
    if (name == null && capacity == null) return;
    state = state.copyWith(machineTypeName: name, capacity: capacity);
  }

  Future<(String?, num?)> _readSavedSettings() async {
    final typeRaw = await _prefs.readString(machineTypeKey);
    final capacityRaw = await _prefs.readString(machineCapacityKey);
    String? name;
    if (typeRaw != null && typeRaw.isNotEmpty) {
      try {
        final json = jsonDecode(typeRaw) as Map<String, Object?>;
        final displayName = json['displayName'];
        if (displayName is String) name = displayName;
      } catch (_) {
        // Ignore malformed JSON — the label simply stays empty.
      }
    }
    final capacity = capacityRaw == null ? null : num.tryParse(capacityRaw);
    return (name, capacity);
  }

  /// US-009 wiring hook: once the dump-size dialog is actually displayed,
  /// US-009 will call this to flip the one-dump-per-cycle guard to `true`.
  /// US-008 ships only the reset side (cleared on transitions out of
  /// DUMPING) — the setter is here so the guard is testable end-to-end.
  void markDumpDialogShown() {
    state = state.copyWith(shownDumpsizeDialogThisDump: true);
  }

  /// Records operator feedback. Updates [TrackingState.feedbackState]
  /// immediately, fires `/create-feedback` fire-and-forget, and
  /// starts/stops nearest-depot polling iff the new state is
  /// [ActivityState.driving]. Tapping the same row twice clears the
  /// selection.
  void selectFeedback(ActivityState? activity) {
    final runId = state.runId;
    if (runId == null) return;

    if (activity == null || state.feedbackState == activity) {
      _stopDepotPolling();
      state = state.copyWith(clearFeedbackState: true, clearNearestDepot: true);
      return;
    }

    state = state.copyWith(feedbackState: activity, clearNearestDepot: true);

    if (activity == ActivityState.driving) {
      _startDepotPolling(runId);
    } else {
      _stopDepotPolling();
    }

    unawaited(SendFeedback(runId, activity).call().catchError((_) {}));
  }

  void _onPrediction(String wire) {
    final ActivityState next;
    try {
      next = ActivityState.fromWire(wire);
    } catch (_) {
      return;
    }
    final previous = state.predictedState;
    final leavingDumping = previous == ActivityState.dumping && next != ActivityState.dumping;
    state = state.copyWith(
      predictedState: next,
      shownDumpsizeDialogThisDump: leavingDumping ? false : state.shownDumpsizeDialogThisDump,
    );
  }

  void _startDepotPolling(String runId) {
    _stopDepotPolling();
    _fetchDepot(runId);
    _depotTimer = Timer.periodic(nearestDepotPollInterval, (_) => _fetchDepot(runId));
  }

  void _stopDepotPolling() {
    _depotTimer?.cancel();
    _depotTimer = null;
  }

  void _fetchDepot(String runId) {
    if (_depotInFlight != null) return;
    _depotInFlight = () async {
      try {
        final depot = await GetNearestDepot(runId).call();
        if (state.feedbackState == ActivityState.driving && state.runId == runId) {
          state = state.copyWith(nearestDepot: depot);
        }
      } catch (_) {
        // Swallow — failures don't surface to the UI; next tick retries.
      } finally {
        _depotInFlight = null;
      }
    }();
  }

  Future<(String, num)?> _readSavedMachine() async {
    final typeRaw = await _prefs.readString(machineTypeKey);
    final capacityRaw = await _prefs.readString(machineCapacityKey);
    if (typeRaw == null || capacityRaw == null) return null;
    try {
      final json = jsonDecode(typeRaw) as Map<String, Object?>;
      final id = json['id'];
      if (id is! String) return null;
      final capacity = num.tryParse(capacityRaw);
      if (capacity == null) return null;
      return (id, capacity);
    } catch (_) {
      return null;
    }
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);
