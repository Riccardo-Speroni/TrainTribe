import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:train_tribe/signup_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _routerApp(Widget home) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (c, s) => home),
      GoRoute(path: '/login', builder: (c, s) => const Placeholder(key: Key('loginPage'))),
      GoRoute(path: '/signup', builder: (c, s) => const SignUpPage()),
    ],
    initialLocation: '/',
  );
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [AppLocalizations.delegate],
    supportedLocales: const [Locale('en')],
  );
}

void main() {
  testWidgets('Signup page link navigates to Login', (tester) async {
    await tester.pumpWidget(_routerApp(const SignUpPage()));
    await tester.pumpAndSettle();

    // Desktop/web path shows link within the card on first page as well
    // Look for the localized text fragment
    final linkFinder = find.textContaining('Already have an account');
    expect(linkFinder, findsOneWidget);
    await tester.tap(linkFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginPage')), findsOneWidget);
  });
}
