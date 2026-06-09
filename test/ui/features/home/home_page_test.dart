import 'package:app/ui/features/home/home_notifier.dart';
import 'package:app/ui/features/home/home_page.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../helpers/di_test_helper.dart';
import '../../../helpers/fixtures.dart';

void main() {
  setUp(setupTestDi);
  tearDown(tearDownTestDi);

  testWidgets('renders the loaded user name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWith((ref) async => user(name: 'Alice'))],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              L10n.init(context);
              return const HomePage();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello, Alice'), findsOneWidget);
  });
}
