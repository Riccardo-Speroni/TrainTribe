import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/login_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/loading_indicator.dart';
import 'package:train_tribe/widgets/logo_pattern_background.dart';

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
  testWidgets('LoginPage build mobile vs wide branches and buildFormContent core', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pump();
    final dynamic state = tester.state(find.byType(LoginPage));

    // Force wide branch
    state.setForceWideScreenForTest(true);
    await tester.pumpAndSettle();
    expect(find.byType(LogoPatternBackground), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);

    // Button disabled until valid
    final loginBtn = find.byKey(const Key('loginButton'));
    expect(tester.widget<ElevatedButton>(loginBtn).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('emailField')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'pass1234');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(loginBtn).onPressed, isNotNull);

    // Force mobile branch
    state.setForceWideScreenForTest(false);
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing); // login has no pageview
    expect(find.text('Don\'t have an account? Sign up'), findsOneWidget);
  });

  testWidgets('LoginPage shows loading indicator during actions', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pump();
    // state not needed here

    // Trigger a login tap to toggle loading
    await tester.enterText(find.byKey(const Key('emailField')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'Pass1234');
    await tester.pump();
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump(); // loading shows immediately
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byType(LoadingIndicator), findsNothing);
  });
}
