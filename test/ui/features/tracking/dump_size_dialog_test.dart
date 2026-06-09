import 'package:app/domain/entities/dump_size.dart';
import 'package:app/ui/features/tracking/dump_size_dialog.dart';
import 'package:app/ui/shared/l10n/generated/app_localizations.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({required void Function(DumpSize) onConfirm, required VoidCallback onDismiss}) {
  return ProviderScope(
    child: MaterialApp(
      onGenerateTitle: (context) {
        L10n.init(context);
        return 'Test';
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DumpSizeDialog(onConfirm: onConfirm, onDismiss: onDismiss),
      ),
    ),
  );
}

void main() {
  testWidgets('renders all 5 radio options with the Dutch labels verbatim', (tester) async {
    await tester.pumpWidget(_harness(onConfirm: (_) {}, onDismiss: () {}));
    await tester.pumpAndSettle();

    expect(find.text('Hoeveel wordt er ongeveer gestort?'), findsOneWidget);
    expect(find.text('Kwart bak'), findsOneWidget);
    expect(find.text('Halve bak'), findsOneWidget);
    expect(find.text('Driekwart bak'), findsOneWidget);
    expect(find.text('Hele bak'), findsOneWidget);
    expect(find.text('Niet gespecificeerd'), findsOneWidget);
    expect(find.text('Bevestigen'), findsOneWidget);
    expect(find.text('Afwijzen'), findsOneWidget);
  });

  testWidgets('confirm defaults to FULL when the user does not change the selection', (tester) async {
    DumpSize? captured;
    await tester.pumpWidget(_harness(onConfirm: (s) => captured = s, onDismiss: () {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DumpSizeDialog.confirmKey));
    expect(captured, DumpSize.full);
  });

  testWidgets('selecting a different radio option changes the confirmed value', (tester) async {
    DumpSize? captured;
    await tester.pumpWidget(_harness(onConfirm: (s) => captured = s, onDismiss: () {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dumpSizeOptionQuarter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DumpSizeDialog.confirmKey));

    expect(captured, DumpSize.quarter);
  });

  testWidgets('dismiss button reports onDismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(_harness(onConfirm: (_) {}, onDismiss: () => dismissed = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DumpSizeDialog.dismissKey));
    expect(dismissed, isTrue);
  });
}
