import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/signup_page.dart';
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
  testWidgets('Signup next buttons enable only when valid (email & password pages)', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pumpAndSettle();

    // Email page
    final next1 = find.byKey(const Key('signupEmailNextButton'));
    expect(tester.widget<ElevatedButton>(next1).onPressed, isNull);
    // Enter invalid email -> still disabled
    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(next1).onPressed, isNull);
    // Enter valid email -> enabled
    await tester.enterText(find.byType(TextField).first, 'a@b.com');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(next1).onPressed, isNotNull);
    await tester.tap(next1);
    await tester.pumpAndSettle();

    // Password page
    final pwdField = find.byKey(const Key('signupPasswordField'));
    final confirmField = find.byKey(const Key('signupConfirmPasswordField'));
    final next2 = find.byKey(const Key('signupPasswordNextButton'));
    expect(tester.widget<ElevatedButton>(next2).onPressed, isNull);
    await tester.enterText(pwdField, 'Abcd1234');
    await tester.enterText(confirmField, 'Abcd1234');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(next2).onPressed, isNotNull);
  });
}
