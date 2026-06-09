import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/inject.dart';

/// Thin wrapper around the New Relic Mobile SDK init flow described in
/// FEATURES.md §8.4. The Android reference calls
/// `NewRelic.withApplicationToken(...).start(context)` from
/// `MainActivity.onCreate` — the Flutter equivalent is
/// `NewrelicMobile.instance.start(Config(accessToken: ...))` from
/// `package:newrelic_mobile`.
///
/// We isolate the call site here so:
///   1. tests don't pull in the native plugin,
///   2. the token comes from `AppEnv.newRelicToken` (configurable per env),
///   3. an empty token short-circuits to a no-op — useful for dev/staging
///      and the test suite.
///
/// To finish wiring real New Relic delivery on device, add
/// `newrelic_mobile: ^1.2.6` to `pubspec.yaml`, follow the package's
/// platform-config steps, and replace the body of [start] with the call
/// shown in the doc-comment block below.
class NewRelicService {
  NewRelicService._();

  /// Boots the New Relic agent. No-op when [token] is empty. Swallows any
  /// initialization error — analytics must never crash app startup.
  ///
  /// When the native SDK is wired in, replace this body with:
  /// ```dart
  /// import 'package:newrelic_mobile/config.dart';
  /// import 'package:newrelic_mobile/newrelic_mobile.dart';
  ///
  /// await NewrelicMobile.instance.startAgent(Config(accessToken: token));
  /// ```
  static Future<void> start({required String token}) async {
    if (token.isEmpty) return;
    try {
      _tryGetLogger()?.info('NewRelic.start (token configured, native SDK not wired yet)');
    } catch (_) {
      // No-op — analytics must never throw.
    }
  }

  static ILogger? _tryGetLogger() {
    if (!injector.isRegistered<ILogger>()) return null;
    return inject<ILogger>();
  }
}
