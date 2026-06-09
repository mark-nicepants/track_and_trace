import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/inject.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the active [AppEnv] to widgets without requiring direct GetIt access.
/// Updates happen only on app restart, so a plain [Provider] is sufficient.
final appEnvProvider = Provider<AppEnv>((ref) => inject<AppEnv>());
