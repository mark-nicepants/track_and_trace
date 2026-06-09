import 'package:app/domain/entities/dump_size.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Modal that asks the driver how full the dump load was. Five radio
/// options match the Android reference's `DumpedMaterialFeedbackDialog`
/// 1:1 (Kwart bak / Halve bak / Driekwart bak / Hele bak / Niet
/// gespecificeerd). Default selection is FULL — the same value the 5-min
/// auto-confirm timer will pick if the operator never interacts.
///
/// Confirm + Dismiss are reported back through [onConfirm] / [onDismiss];
/// the dialog itself is stateless about its visibility — `TrackingPage`
/// owns the showDialog/Navigator.pop choreography by listening to the
/// `dumpSizeProvider`.
///
/// `barrierDismissible: false` is set at the showDialog site and
/// `PopScope(canPop: false)` here suppresses the system back gesture —
/// the dialog is uncloseable except via the two buttons or the auto-FULL
/// timer.
class DumpSizeDialog extends HookWidget {
  const DumpSizeDialog({super.key, required this.onConfirm, required this.onDismiss});

  final void Function(DumpSize) onConfirm;
  final VoidCallback onDismiss;

  static const Key dialogKey = Key('dumpSizeDialog');
  static const Key confirmKey = Key('dumpSizeConfirm');
  static const Key dismissKey = Key('dumpSizeDismiss');

  @override
  Widget build(BuildContext context) {
    final l = L10n.translate;
    final selected = useState<DumpSize>(DumpSize.full);

    final options = <(DumpSize, String, Key)>[
      (DumpSize.quarter, l.dumpSizeQuarter, const Key('dumpSizeOptionQuarter')),
      (DumpSize.half, l.dumpSizeHalf, const Key('dumpSizeOptionHalf')),
      (DumpSize.threeQuarter, l.dumpSizeThreeQuarter, const Key('dumpSizeOptionThreeQuarter')),
      (DumpSize.full, l.dumpSizeFull, const Key('dumpSizeOptionFull')),
      (DumpSize.unspecified, l.dumpSizeUnspecified, const Key('dumpSizeOptionUnspecified')),
    ];

    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: dialogKey,
        title: Text(l.dumpSizeTitle, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: RadioGroup<DumpSize>(
            groupValue: selected.value,
            onChanged: (v) {
              if (v != null) selected.value = v;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (size, label, key) in options)
                  ListTile(
                    key: key,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    leading: Radio<DumpSize>(value: size),
                    title: Text(label),
                    onTap: () => selected.value = size,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(key: dismissKey, onPressed: onDismiss, child: Text(l.dumpSizeDismiss)),
          TextButton(key: confirmKey, onPressed: () => onConfirm(selected.value), child: Text(l.dumpSizeConfirm)),
        ],
      ),
    );
  }
}
