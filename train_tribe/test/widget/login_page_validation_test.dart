import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/login_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: child,
    );

void main() {
  testWidgets('Login button enables only with valid email and password', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pumpAndSettle();

    final email = find.byKey(const Key('emailField'));
    final pass = find.byKey(const Key('passwordField'));
    final btn = find.byKey(const Key('loginButton'));

    // Initially disabled
    var button = tester.widget<ElevatedButton>(btn);
    expect(button.onPressed, isNull);

    // Invalid email keeps disabled
    await tester.enterText(email, 'invalid');
    await tester.enterText(pass, 'pw');
    await tester.pumpAndSettle();
    button = tester.widget<ElevatedButton>(btn);
    expect(button.onPressed, isNull);

    // Valid email enables button
    await tester.enterText(email, 'a@b.com');
    await tester.pumpAndSettle();
    button = tester.widget<ElevatedButton>(btn);
    expect(button.onPressed, isNotNull);
  });
}
