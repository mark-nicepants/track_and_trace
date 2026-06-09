import 'dart:async';

import 'package:app/data/models/get_status_request_dto.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/contracts/i_prediction_service.dart';
import 'package:app/shared/inject.dart';

/// Polls `/get-status` for the active run every [pollInterval] and emits
/// each newly-distinct prediction. Mirrors the Android reference's
/// `PredictionService` while parking inside one `while (_running)` loop
/// (the SendingService pattern from US-007).
///
/// On any error — network failure, unknown activity string, server
/// non-200 — the loop logs and continues; failures do not surface to the
/// notifier (the prediction stream simply stays silent until the next
/// successful poll).
class PredictionService implements IPredictionService {
  PredictionService({this.pollInterval = const Duration(seconds: 2)});

  /// Polling cadence between successful or failed `/get-status` calls.
  /// Production uses 2 s (Android parity); tests override with a shorter
  /// duration to keep the suite fast.
  final Duration pollInterval;

  TrackAndTraceRepository get _api => inject();
  IsoClock get _clock => inject();
  ILogger get _log => inject();

  bool _running = false;
  String? _runId;
  String? _latestActivity;
  Future<void>? _loopFuture;
  Completer<void>? _wake;
  final StreamController<String> _predictionsController = StreamController<String>.broadcast();

  @override
  bool get isRunning => _running;

  @override
  Stream<String> get predictions => _predictionsController.stream;

  @override
  Future<void> start(String runId) async {
    if (_running) return;
    _running = true;
    _runId = runId;
    _latestActivity = null;
    _loopFuture = _runLoop();
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
    _wake = null;
    final loop = _loopFuture;
    _loopFuture = null;
    await loop;
    _runId = null;
    _latestActivity = null;
  }

  Future<void> _runLoop() async {
    while (_running) {
      try {
        final runId = _runId;
        if (runId == null) break;
        final request = GetStatusRequestDto(runId, _clock.nowIso(), _latestActivity ?? '');
        final response = await _api.getStatus(request);
        final activity = response.activity;
        if (_isKnownActivity(activity) && activity != _latestActivity) {
          _latestActivity = activity;
          _predictionsController.add(activity);
        }
      } catch (e, st) {
        _log.warning('PredictionService: getStatus failed', e, st);
      }
      await _wait(pollInterval);
    }
  }

  Future<void> _wait(Duration maxDelay) async {
    if (!_running) return;
    final wake = Completer<void>();
    _wake = wake;
    Timer? timer;
    timer = Timer(maxDelay, () {
      if (!wake.isCompleted) wake.complete();
    });
    await wake.future;
    timer.cancel();
    if (identical(_wake, wake)) _wake = null;
  }

  static const Set<String> _knownActivities = {'LOADING', 'DRIVING', 'DUMPING', 'STANDING_STILL'};

  bool _isKnownActivity(String s) => _knownActivities.contains(s);
}
