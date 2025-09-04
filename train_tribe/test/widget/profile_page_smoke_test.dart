import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/profile_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

void main() {
  testWidgets('ProfilePage shows error text when user is null', (tester) async {
    // FirebaseAuth.instance.currentUser will be null in this test environment.
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [AppLocalizations.delegate],
      supportedLocales: [Locale('en'), Locale('it')],
      home: ProfilePage(),
    ));
    await tester.pump();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.textContaining('Firebase not initialized'), findsOneWidget);
  });
}
