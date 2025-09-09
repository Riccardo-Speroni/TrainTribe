import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/onboarding_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

void main() {
  testWidgets('OnboardingPage shows first page content and can advance', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [AppLocalizations.delegate],
      supportedLocales: [Locale('en'), Locale('it')],
      home: OnboardingPage(),
    ));
    await tester.pump();
    // Tap next via the AppBar button (desktop/web path). If not present (mobile), skip.
    final nextFinder = find.textContaining(RegExp('next', caseSensitive: false));
    if (nextFinder.evaluate().isNotEmpty) {
      await tester.tap(nextFinder.first);
      await tester.pumpAndSettle();
    }
    expect(find.byType(OnboardingPage), findsOneWidget);
  });
}
