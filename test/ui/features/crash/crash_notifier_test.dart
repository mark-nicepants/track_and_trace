import 'package:app/data/services/in_memory_preference_service.dart';
import 'package:app/shared/contracts/i_crash_report_service.dart';
import 'package:app/ui/features/crash/crash_detected_provider.dart';
import 'package:app/ui/features/crash/crash_notifier.dart';
import 'package:app/ui/features/crash/crash_state.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/di_test_helper.dart';

class _FakeCrashService implements ICrashReportService {
  _FakeCrashService(this.result);

  final bool result;
  int callCount = 0;

  @override
  Future<bool> uploadLogs() async {
    callCount++;
    return result;
  }
}

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  tearDown(tearDownTestDi);

  test('sendReport: success path flips state to success and writes EXITED_CORRECTLY=true', () async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(exitedCorrectlyKey, 'false');
    final fake = _FakeCrashService(true);
    await setupTestDi(prefs: prefs, crashReports: fake);

    final container = _container();
    expect(container.read(crashProvider).status, CrashReportStatus.choice);

    await container
        .read(crashProvider.notifier)
        .sendReport(gettingLogFilesLabel: 'log', zippingLabel: 'zip', sendingLabel: 'send');

    expect(fake.callCount, 1);
    expect(container.read(crashProvider).status, CrashReportStatus.success);
    expect(await prefs.readString(exitedCorrectlyKey), 'true');
  });

  test('sendReport: failure path flips state to failed but still clears the flag', () async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(exitedCorrectlyKey, 'false');
    final fake = _FakeCrashService(false);
    await setupTestDi(prefs: prefs, crashReports: fake);

    final container = _container();
    await container
        .read(crashProvider.notifier)
        .sendReport(gettingLogFilesLabel: 'log', zippingLabel: 'zip', sendingLabel: 'send');

    expect(container.read(crashProvider).status, CrashReportStatus.failed);
    expect(await prefs.readString(exitedCorrectlyKey), 'true');
  });

  test('decline: marks the flag handled without invoking the service', () async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(exitedCorrectlyKey, 'false');
    final fake = _FakeCrashService(true);
    await setupTestDi(prefs: prefs, crashReports: fake);

    final container = _container();
    await container.read(crashProvider.notifier).decline();

    expect(fake.callCount, 0);
    expect(await prefs.readString(exitedCorrectlyKey), 'true');
  });

  test('retry resets state to choice', () async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(exitedCorrectlyKey, 'false');
    final fake = _FakeCrashService(false);
    await setupTestDi(prefs: prefs, crashReports: fake);

    final container = _container();
    await container
        .read(crashProvider.notifier)
        .sendReport(gettingLogFilesLabel: 'log', zippingLabel: 'zip', sendingLabel: 'send');
    expect(container.read(crashProvider).status, CrashReportStatus.failed);

    container.read(crashProvider.notifier).retry();
    expect(container.read(crashProvider).status, CrashReportStatus.choice);
  });

  test('crashDetectedAtLaunchProvider: true when EXITED_CORRECTLY=false', () async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(exitedCorrectlyKey, 'false');
    await setupTestDi(prefs: prefs);

    final container = _container();
    final detected = await container.read(crashDetectedAtLaunchProvider.future);
    expect(detected, isTrue);
  });

  test('crashDetectedAtLaunchProvider: false when EXITED_CORRECTLY=true', () async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(exitedCorrectlyKey, 'true');
    await setupTestDi(prefs: prefs);

    final container = _container();
    final detected = await container.read(crashDetectedAtLaunchProvider.future);
    expect(detected, isFalse);
  });

  test('crashDetectedAtLaunchProvider: false when the flag is missing (no prior run)', () async {
    final prefs = InMemoryPreferenceService();
    await setupTestDi(prefs: prefs);

    final container = _container();
    final detected = await container.read(crashDetectedAtLaunchProvider.future);
    expect(detected, isFalse);
  });

  test('sendReport invalidates crashDetectedAtLaunchProvider so the router redirect re-evaluates', () async {
    final p = InMemoryPreferenceService();
    await p.writeString(exitedCorrectlyKey, 'false');
    final fake = _FakeCrashService(true);
    await setupTestDi(prefs: p, crashReports: fake);

    final container = _container();
    expect(await container.read(crashDetectedAtLaunchProvider.future), isTrue);

    await container
        .read(crashProvider.notifier)
        .sendReport(gettingLogFilesLabel: 'log', zippingLabel: 'zip', sendingLabel: 'send');

    // Provider invalidated → re-resolves against the now-updated flag.
    expect(await container.read(crashDetectedAtLaunchProvider.future), isFalse);
  });
}
