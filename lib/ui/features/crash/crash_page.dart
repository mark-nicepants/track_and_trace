import 'dart:async';

import 'package:app/ui/features/crash/crash_notifier.dart';
import 'package:app/ui/features/crash/crash_state.dart';
import 'package:app/ui/features/main/main_page.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Standalone "previous session crashed" screen. Reachable only when the
/// EXITED_CORRECTLY flag is `false` at app boot (see [crashDetectedAtLaunchProvider]).
///
/// Flow per FEATURES.md §8.3:
///   1. Ask user "Wilt u een crash rapport versturen?" (Ja / Nee).
///   2. On Ja: transition through Dutch progress labels while the
///      [CrashNotifier] zips logs + POSTs to `/forward-logs`.
///   3. On success show the success confirmation; on failure offer
///      "Opnieuw" retry.
///   4. "Sluiten" / "Nee" route to [MainPage] so the redirect picks up
///      the next destination (permissions / setup / tracking).
class CrashPage extends ConsumerWidget {
  const CrashPage({super.key});

  static const String path = '/crash';
  static const String name = 'crash';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const CrashPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crashProvider);
    final notifier = ref.read(crashProvider.notifier);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: Text(L10n.translate.crashDetectedTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: switch (state.status) {
                CrashReportStatus.choice => _ChoiceView(
                  onYes: () => unawaited(
                    notifier.sendReport(
                      gettingLogFilesLabel: L10n.translate.crashGettingLogFiles,
                      zippingLabel: L10n.translate.crashZippingFiles,
                      sendingLabel: L10n.translate.crashSendingReport,
                    ),
                  ),
                  onNo: () async {
                    await notifier.decline();
                    if (context.mounted) MainPage.go(context);
                  },
                ),
                CrashReportStatus.busy => _BusyView(label: state.busyLabel),
                CrashReportStatus.success => _SuccessView(onClose: () => MainPage.go(context)),
                CrashReportStatus.failed => _FailedView(onRetry: notifier.retry, onClose: () => MainPage.go(context)),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceView extends StatelessWidget {
  const _ChoiceView({required this.onYes, required this.onNo});

  final VoidCallback onYes;
  final Future<void> Function() onNo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(L10n.translate.crashBody, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              key: const Key('crashDecline'),
              onPressed: () => unawaited(onNo()),
              child: Text(L10n.translate.crashNo),
            ),
            FilledButton(key: const Key('crashAccept'), onPressed: onYes, child: Text(L10n.translate.crashYes)),
          ],
        ),
      ],
    );
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${L10n.translate.crashSendingReport}…', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (label != null) Text(label!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          L10n.translate.crashSentSuccessfully,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton(key: const Key('crashClose'), onPressed: onClose, child: Text(L10n.translate.crashClose)),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(L10n.translate.crashFailed, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(key: const Key('crashClose'), onPressed: onClose, child: Text(L10n.translate.crashClose)),
            FilledButton(key: const Key('crashRetry'), onPressed: onRetry, child: Text(L10n.translate.crashTryAgain)),
          ],
        ),
      ],
    );
  }
}
