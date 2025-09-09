import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/signup_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: child,
    );

void main() {
  testWidgets('signup flow: email -> password page next enabled only when valid', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    final nextEmail = find.byKey(const Key('signupEmailNextButton'));
    expect(nextEmail, findsOneWidget);
    final ElevatedButton btnEmail = tester.widget(nextEmail);
    expect(btnEmail.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'invalid');
    await tester.pumpAndSettle();
    expect((tester.widget(nextEmail) as ElevatedButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'user@test.com');
    await tester.pumpAndSettle();
    expect((tester.widget(nextEmail) as ElevatedButton).onPressed, isNotNull);
  });

  testWidgets('signup password step enables next only when all conditions satisfied', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    // Enter valid email and proceed
    await tester.enterText(find.byType(TextField).first, 'user@test.com');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signupEmailNextButton')));
    await tester.pumpAndSettle();

    // Now on password page: find password next button
    final nextPwd = find.byKey(const Key('signupPasswordNextButton'));
    expect(nextPwd, findsOneWidget);
    ElevatedButton btn = tester.widget(nextPwd);
    expect(btn.onPressed, isNull);

    // Insert password missing uppercase
    await tester.enterText(find.byKey(const Key('signupPasswordField')), 'password1');
    await tester.enterText(find.byKey(const Key('signupConfirmPasswordField')), 'password1');
    await tester.pumpAndSettle();
    btn = tester.widget(nextPwd);
    expect(btn.onPressed, isNull);

    // Add uppercase & number & length ok
    await tester.enterText(find.byKey(const Key('signupPasswordField')), 'Password1');
    await tester.enterText(find.byKey(const Key('signupConfirmPasswordField')), 'Password1');
    await tester.pumpAndSettle();
    btn = tester.widget(nextPwd);
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('back from password step returns to email step', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    // Enter valid email and go to password page
    await tester.enterText(find.byType(TextField).first, 'user@test.com');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signupEmailNextButton')));
    await tester.pumpAndSettle();

    // On password page there is a back icon
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // We should be back on the email page with the logo and email TextField visible first
    expect(find.textContaining('Enter email'), findsOneWidget);
  });
}
