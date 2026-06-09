import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String selectedEnvKey = 'app.selected_env';

/// Holds the env name currently *selected* in preferences. Distinct from
/// [AppEnv.name] (the env active in the running app) when a switch is pending
/// a restart.
class EnvSwitcherNotifier extends AsyncNotifier<String> {
  IPreferenceService get _prefs => inject();

  @override
  Future<String> build() async => (await _prefs.readString(selectedEnvKey)) ?? AppEnv.fallbackName;

  Future<void> select(String envName) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _prefs.writeString(selectedEnvKey, envName);
      return envName;
    });
  }
}

final envSwitcherProvider = AsyncNotifierProvider<EnvSwitcherNotifier, String>(EnvSwitcherNotifier.new);
