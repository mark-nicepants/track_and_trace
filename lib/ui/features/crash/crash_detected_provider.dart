import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads the `EXITED_CORRECTLY` flag exactly once at boot and exposes:
///   - `true`  when the previous launch crashed (flag was `false`)
///   - `false` when the previous launch exited cleanly
///
/// Per FEATURES.md §8.1, the flag defaults to `true` when missing (no
/// previous run = no crash to report). The lookup happens lazily — the
/// router redirect reads it via [crashDetectedAtLaunchProvider] and the
/// crash page consumes the boolean to decide whether to render itself.
final crashDetectedAtLaunchProvider = FutureProvider<bool>((ref) async {
  final prefs = inject<IPreferenceService>();
  final raw = await prefs.readString(exitedCorrectlyKey);
  // A missing value means "no previous run", not a crash.
  return raw == 'false';
});
