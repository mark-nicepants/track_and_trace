import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/http/dio_provider.dart';
import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/connectivity_service.dart';
import 'package:app/data/services/foreground_tracking_service.dart';
import 'package:app/data/services/permission_service.dart';
import 'package:app/data/services/prediction_service.dart';
import 'package:app/data/services/sending_service.dart';
import 'package:app/data/services/tracelet_location_client.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_connectivity_service.dart';
import 'package:app/shared/contracts/i_foreground_tracking_service.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/shared/contracts/i_prediction_service.dart';
import 'package:app/shared/contracts/i_sending_service.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Name of the on-device sqlite file backing [PositionQueueRepository].
const String positionQueueDatabaseName = 'position_queue.db';

/// Registers all data-layer singletons. Called from [main] AFTER:
///   - IPreferenceService is registered,
///   - ILogger is registered,
///   - IsoClock is registered,
///   - AppEnv is registered.
void registerDataModule() {
  final env = inject<AppEnv>();

  injector.registerSingleton<Dio>(buildDio(env));
  injector.registerSingleton<TrackAndTraceRepository>(TrackAndTraceRepository());
  injector.registerSingleton<IPermissionService>(const PermissionService());
  injector.registerSingleton<ILocationClient>(const TraceletLocationClient());
  injector.registerSingleton<IForegroundTrackingService>(const ForegroundTrackingService());
  injector.registerSingleton<IConnectivityService>(const ConnectivityService());

  injector.registerSingletonAsync<Database>(() async {
    final path = p.join(await getDatabasesPath(), positionQueueDatabaseName);
    return openDatabase(
      path,
      version: PositionQueueDao.schemaVersion,
      onCreate: (db, version) => db.execute(PositionQueueDao.createTableSql),
    );
  });

  injector.registerSingleton<PositionQueueRepository>(PositionQueueRepository());
  injector.registerSingleton<ISendingService>(SendingService());
  injector.registerSingleton<IPredictionService>(PredictionService());
}
