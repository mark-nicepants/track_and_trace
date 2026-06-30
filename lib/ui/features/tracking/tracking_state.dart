import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/entities/nearest_depot.dart';
import 'package:equatable/equatable.dart';

/// Snapshot of the tracking screen's run lifecycle + activity state
/// machine. [runId] is non-null once `/create-run` succeeds; tracking is
/// active iff [runId] is non-null (LocationService + SendingService +
/// PredictionService are all running). [predictedState] is the latest
/// activity from PredictionService polling `/get-status`; [feedbackState]
/// is the operator-confirmed activity from the 4-way grid (the
/// `_selectedFeedbackIndex` is implicit via the enum's `.index` order).
///
/// [shownDumpsizeDialogThisDump] is the one-dump-per-cycle guard: set when
/// the dump dialog is shown for a DUMPING transition, cleared when the
/// state machine transitions out of DUMPING. US-008 ships the guard
/// itself; US-009 wires the dialog to it.
///
/// [machineTypeName] and [capacity] mirror the operator's saved
/// vehicle/capacity (read from prefs on build, refreshed after an in-place
/// edit). They drive the settings label in the AppBar area and are
/// independent of the run lifecycle — editing them mid-run changes only the
/// *next* run, never the active one.
class TrackingState(
  final String? runId,
  final ActivityState? predictedState,
  final ActivityState? feedbackState,
  final NearestDepot? nearestDepot,
  final bool shownDumpsizeDialogThisDump,
  final bool stopping,
  final Object? startError,
  final String? machineTypeName,
  final num? capacity,
) extends Equatable {
  static final TrackingState initial = TrackingState(null, null, null, null, false, false, null, null, null);

  bool get isTracking => runId != null;

  int get selectedFeedbackIndex => feedbackState == null ? -1 : feedbackState!.index;

  TrackingState copyWith({
    String? runId,
    bool clearRunId = false,
    ActivityState? predictedState,
    bool clearPredictedState = false,
    ActivityState? feedbackState,
    bool clearFeedbackState = false,
    NearestDepot? nearestDepot,
    bool clearNearestDepot = false,
    bool? shownDumpsizeDialogThisDump,
    bool? stopping,
    Object? startError,
    bool clearStartError = false,
    String? machineTypeName,
    num? capacity,
  }) => TrackingState(
    clearRunId ? null : (runId ?? this.runId),
    clearPredictedState ? null : (predictedState ?? this.predictedState),
    clearFeedbackState ? null : (feedbackState ?? this.feedbackState),
    clearNearestDepot ? null : (nearestDepot ?? this.nearestDepot),
    shownDumpsizeDialogThisDump ?? this.shownDumpsizeDialogThisDump,
    stopping ?? this.stopping,
    clearStartError ? null : (startError ?? this.startError),
    machineTypeName ?? this.machineTypeName,
    capacity ?? this.capacity,
  );

  @override
  List<Object?> get props => [
    runId,
    predictedState,
    feedbackState,
    nearestDepot,
    shownDumpsizeDialogThisDump,
    stopping,
    startError,
    machineTypeName,
    capacity,
  ];
}
