import 'dart:io';

import 'package:app/data/http/guard_dio.dart';
import 'package:app/data/models/create_locations_request_dto.dart';
import 'package:app/data/models/dump_size_dto.dart';
import 'package:app/data/models/feedback_dto.dart';
import 'package:app/data/models/get_nearest_depot_request_dto.dart';
import 'package:app/data/models/get_status_request_dto.dart';
import 'package:app/data/models/get_status_response_dto.dart';
import 'package:app/data/models/machine_type_dto.dart';
import 'package:app/data/models/nearest_depot_dto.dart';
import 'package:app/data/models/start_run_request_dto.dart';
import 'package:app/data/models/start_run_response_dto.dart';
import 'package:app/data/models/stop_run_request_dto.dart';
import 'package:app/data/models/sync_run_data_request_dto.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';

/// One method per backend endpoint. Method names mirror the Android
/// reference's `Api.kt` interface so cross-reading the two is trivial.
///
/// All calls flow through [guardDio] so callers never see raw
/// [DioException]s — only sealed [DataException] subtypes.
class TrackAndTraceRepository {
  Dio get _dio => inject();

  Future<StartRunResponseDto> sendStartRun(StartRunRequestDto request) => guardDio(() async {
    final response = await _dio.post<Map<String, Object?>>('/create-run', data: request.toJson());
    return StartRunResponseDto.fromJson(response.data!);
  });

  Future<void> sendStopRun(StopRunRequestDto request) =>
      guardDio(() => _dio.post<void>('/stop-run', data: request.toJson()));

  Future<void> createLocations(CreateLocationsRequestDto request) =>
      guardDio(() => _dio.post<void>('/create-locations', data: request.toJson()));

  Future<void> sendFeedback(FeedbackDto feedback) =>
      guardDio(() => _dio.post<void>('/create-feedback', data: feedback.toJson()));

  Future<GetStatusResponseDto> getStatus(GetStatusRequestDto request) => guardDio(() async {
    final response = await _dio.post<Map<String, Object?>>('/get-status', data: request.toJson());
    return GetStatusResponseDto.fromJson(response.data!);
  });

  Future<void> sendDumpSize(DumpSizeDto request) =>
      guardDio(() => _dio.post<void>('/create-dump-size', data: request.toJson()));

  Future<NearestDepotDto> getNearestDepot(GetNearestDepotRequestDto request) => guardDio(() async {
    final response = await _dio.post<Map<String, Object?>>('/get-nearest-depot', data: request.toJson());
    return NearestDepotDto.fromJson(response.data!);
  });

  Future<void> sendSyncRunData(SyncRunDataRequestDto request) =>
      guardDio(() => _dio.post<void>('/sync-run-data', data: request.toJson()));

  /// Multipart upload of [file] under the form-data part name [fieldName].
  /// Mirrors the Android reference's `@Multipart @POST("/forward-logs")`.
  Future<void> uploadLogfile(File file, {required String fieldName}) => guardDio(() async {
    final form = FormData.fromMap({fieldName: await MultipartFile.fromFile(file.path)});
    await _dio.post<void>('/forward-logs', data: form);
  });

  Future<List<MachineTypeDto>> getMachineTypes() => guardDio(() async {
    final response = await _dio.post<List<Object?>>('/get-machine-types');
    return response.data!.map((e) => MachineTypeDto.fromJson(e! as Map<String, Object?>)).toList(growable: false);
  });
}
