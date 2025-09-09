import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/widgets/legend_dialog.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('legend dialog shows items and closes', (tester) async {
    await tester.pumpWidget(_wrap(Center(
      child: TextButton(
        key: const Key('open_legend'),
        onPressed: () => showLegendDialog(
          context: tester.element(find.byType(TextButton)),
          title: 'Legend',
          items: const [
            LegendItem(ringColor: Colors.green, glowColor: Colors.green, label: 'You', showCheck: true),
            LegendItem(ringColor: Colors.amber, glowColor: Colors.amber, label: 'Friend', icon: Icons.person_outline),
          ],
          infoText: 'Some info',
          okLabel: 'Close',
        ),
        child: const Text('Open'),
      ),
    )));
    await tester.pump();
    expect(find.byKey(const Key('open_legend')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open_legend')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legend_dialog')), findsOneWidget);
    expect(find.byKey(const Key('legend_item_0')), findsOneWidget);
    expect(find.byKey(const Key('legend_item_1')), findsOneWidget);
    expect(find.byKey(const Key('legend_info')), findsOneWidget);

    await tester.tap(find.byKey(const Key('legend_ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legend_dialog')), findsNothing);
  });
}
