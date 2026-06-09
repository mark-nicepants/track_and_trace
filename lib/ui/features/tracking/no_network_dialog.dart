import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Modal that surfaces an offline state to the driver. Dutch copy is
/// FEATURES.md §12 verbatim (mirrors the Android reference's
/// `NoNetworkDialog`). Auto-dismissed by the tracking page when
/// connectivity returns — see `tracking_page.dart`.
///
/// The dialog is uncloseable by the user: `barrierDismissible: false` at
/// the `showDialog` site + we intercept the system back gesture via
/// `PopScope(canPop: false)`. Drivers stop a run via the screen's main
/// Stop button, not by tapping out of the dialog.
class NoNetworkDialog extends StatelessWidget {
  const NoNetworkDialog({super.key});

  static const Key dialogKey = Key('noNetworkDialog');

  @override
  Widget build(BuildContext context) {
    final l = L10n.translate;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: dialogKey,
        title: Text(l.noNetworkTitle),
        content: SingleChildScrollView(child: Text(l.noNetworkBody)),
      ),
    );
  }
}
