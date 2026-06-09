import 'package:app/data/models/create_locations_request_dto.dart';
import 'package:app/data/models/dump_size_dto.dart';
import 'package:app/data/models/feedback_dto.dart';
import 'package:app/data/models/get_nearest_depot_request_dto.dart';
import 'package:app/data/models/get_status_request_dto.dart';
import 'package:app/data/models/machine_type_dto.dart';
import 'package:app/data/models/nearest_depot_dto.dart';
import 'package:app/data/models/run_dto.dart';
import 'package:app/data/models/start_run_request_dto.dart';
import 'package:app/data/models/status_timestamp_dto.dart';
import 'package:app/data/models/stop_run_request_dto.dart';
import 'package:app/data/models/sync_run_data_request_dto.dart';
import 'package:app/data/models/tracking_position_dto.dart';
import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/entities/feedback.dart';
import 'package:app/domain/entities/machine_type.dart';
import 'package:app/domain/entities/nearest_depot.dart';
import 'package:app/domain/entities/run.dart';
import 'package:app/domain/entities/status_timestamp.dart';
import 'package:app/domain/entities/tracking_position.dart';

const String _iso = '2026-06-09T12:34:56.789';

TrackingPositionDto trackingPositionDto({
  String time = _iso,
  num lat = 52.37,
  num lon = 4.89,
  String? runId = 'run-1',
}) => TrackingPositionDto(time, lat, lon, runId);

TrackingPosition trackingPosition({
  String time = _iso,
  num latitude = 52.37,
  num longitude = 4.89,
  String? runId = 'run-1',
}) => TrackingPosition(time, latitude, longitude, runId);

MachineTypeDto machineTypeDto({String id = 'mt-1', String displayName = 'Loader'}) => MachineTypeDto(id, displayName);

MachineType machineType({String id = 'mt-1', String displayName = 'Loader'}) => MachineType(id, displayName);

RunDto runDto({
  String id = 'run-1',
  String startTime = _iso,
  String machineTypeId = 'mt-1',
  num capacity = 12,
  String? endTime,
}) => RunDto(id, startTime, machineTypeId, capacity, endTime);

Run run({
  String id = 'run-1',
  String startTime = _iso,
  String machineTypeId = 'mt-1',
  num capacity = 12,
  String? endTime,
}) => Run(id, startTime, machineTypeId, capacity, endTime);

FeedbackDto feedbackDto({String runId = 'run-1', String time = _iso, String? name = 'DRIVING'}) =>
    FeedbackDto(runId, time, name);

Feedback feedback({String runId = 'run-1', String time = _iso, String? name = 'DRIVING'}) =>
    Feedback(runId, time, name);

DumpSizeDto dumpSizeDto({String runId = 'run-1', String time = _iso, String quantity = 'HALF'}) =>
    DumpSizeDto(runId, time, quantity);

NearestDepotDto nearestDepotDto({String name = 'Depot A'}) => NearestDepotDto(name);

NearestDepot nearestDepot({String name = 'Depot A'}) => NearestDepot(name);

StatusTimestampDto statusTimestampDto({String time = _iso, String name = 'DRIVING'}) => StatusTimestampDto(time, name);

StatusTimestamp statusTimestamp({String time = _iso, ActivityState name = ActivityState.driving}) =>
    StatusTimestamp(time, name);

StartRunRequestDto startRunRequestDto({String startTime = _iso, String machineTypeId = 'mt-1', num capacity = 12}) =>
    StartRunRequestDto(startTime, machineTypeId, capacity);

StopRunRequestDto stopRunRequestDto({String runId = 'run-1', String endTime = _iso}) =>
    StopRunRequestDto(runId, endTime);

CreateLocationsRequestDto createLocationsRequestDto({List<TrackingPositionDto>? locations}) =>
    CreateLocationsRequestDto(locations ?? [trackingPositionDto()]);

GetStatusRequestDto getStatusRequestDto({String runId = 'run-1', String time = _iso, String activity = 'DRIVING'}) =>
    GetStatusRequestDto(runId, time, activity);

GetNearestDepotRequestDto getNearestDepotRequestDto({String runId = 'run-1', String time = _iso}) =>
    GetNearestDepotRequestDto(runId, time);

SyncRunDataRequestDto syncRunDataRequestDto({String runId = 'run-1', String time = _iso, String quantity = 'HALF'}) =>
    SyncRunDataRequestDto(runId, time, quantity);
