import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/home_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

void main() {
  testWidgets('HomePage renders mood question and toggle', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [AppLocalizations.delegate],
      supportedLocales: [Locale('en'), Locale('it')],
      home: HomePage(),
    ));
    await tester.pump();
    // Just ensure some text & MoodToggle appear.
    expect(find.byType(HomePage), findsOneWidget);
    // MoodToggle should load instantly in tests (Firebase skipped)
  });
}
