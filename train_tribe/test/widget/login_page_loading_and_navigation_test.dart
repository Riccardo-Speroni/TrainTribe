import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:train_tribe/login_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/auth_adapter.dart';

class _SlowSuccessAuth implements AuthAdapter {
  final Duration delay;
  bool called = false;
  _SlowSuccessAuth({this.delay = const Duration(milliseconds: 250)});
  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    called = true;
    await Future.delayed(delay);
    return _FakeUserCredential();
  }

  @override
  User? get currentUser => null;
}

class _FakeUserCredential implements UserCredential {
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
  @override
  AuthCredential? get credential => null;
  @override
  User? get user => null;
}

Widget _routerApp(Widget child) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (c, s) => child),
      GoRoute(path: '/root', builder: (c, s) => const Placeholder(key: Key('rootPage'))),
      GoRoute(path: '/signup', builder: (c, s) => const Placeholder(key: Key('signupPage'))),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('email login shows loading overlay then navigates to /root on success', (tester) async {
    final auth = _SlowSuccessAuth(delay: const Duration(milliseconds: 400));
    await tester.pumpWidget(_routerApp(LoginPage(authAdapter: auth)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emailField')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'Password1');
    // Let enable animation progress a bit
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 70));
    }

    // Tap login
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    // Loading overlay should appear during async auth
    expect(find.byType(Overlay), findsWidgets); // overlay host exists
    // Our app shows a LoadingIndicator widget when _isLoading is true
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString().contains('LoadingIndicator')), findsOneWidget);

    // Advance time to complete auth
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    // Navigated to root
    expect(find.byKey(const Key('rootPage')), findsOneWidget);
    expect(auth.called, isTrue);
  });
}
