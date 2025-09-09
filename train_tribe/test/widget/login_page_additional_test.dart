import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:train_tribe/login_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/auth_adapter.dart';

class _SuccessAuthAdapter implements AuthAdapter {
  bool called = false;
  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    called = true;
    return _FakeUserCredential();
  }

  @override
  User? get currentUser => null;
}

class _FailAuthAdapter implements AuthAdapter {
  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    throw FirebaseAuthException(code: 'invalid-credential', message: 'x');
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

// Simple GoRouter wrapper for navigation tests.
Widget _routerApp(Widget child) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (c, s) => child),
      GoRoute(path: '/signup', builder: (c, s) => const Placeholder(key: Key('signupPage'))),
      GoRoute(path: '/root', builder: (c, s) => const Placeholder(key: Key('rootPage'))),
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

  testWidgets('opacity animation changes when inputs become valid', (tester) async {
    final auth = _SuccessAuthAdapter();
    await tester.pumpWidget(_routerApp(LoginPage(authAdapter: auth)));
    await tester.pumpAndSettle();
    final loginBtnFinder = find.byKey(const Key('loginButton'));
    // Initial opacity should be starting tween (0.5) -> within tolerance
    final animatedOpacity1 = tester.widget<Opacity>(find.ancestor(of: loginBtnFinder, matching: find.byType(Opacity)).first);
    expect(animatedOpacity1.opacity, lessThan(0.9));
    await tester.enterText(find.byKey(const Key('emailField')), 'valid@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'Pass12345');
    await tester.pumpAndSettle();
    final animatedOpacity2 = tester.widget<Opacity>(find.ancestor(of: loginBtnFinder, matching: find.byType(Opacity)).first);
    expect(animatedOpacity2.opacity, greaterThan(animatedOpacity1.opacity));
  });

  testWidgets('pressing enter in password field triggers login when enabled', (tester) async {
    final auth = _SuccessAuthAdapter();
    await tester.pumpWidget(_routerApp(LoginPage(authAdapter: auth)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'StrongPass1');
    // Advance animation frames until button fully enabled
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  // Wait extra frames for animation + navigation
  await tester.pump(const Duration(milliseconds: 400));
  expect(auth.called, isTrue);
  });

  testWidgets('auth exception shows error dialog with localized title', (tester) async {
    await tester.pumpWidget(_routerApp(LoginPage(authAdapter: _FailAuthAdapter())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'StrongPass1');
    // Let listeners update button state & animation
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 70));
    }
    final ElevatedButton btn = tester.widget(find.byKey(const Key('loginButton')));
    expect(btn.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  // Allow dialog animation
  await tester.pump(const Duration(milliseconds: 300));
    // Dialog appears
  expect(find.byType(AlertDialog), findsOneWidget);
  // Localized title
  expect(find.text('Login failed'), findsOneWidget);
    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('signup link navigates to signup page (mobile layout includes social buttons)', (tester) async {
    final auth = _SuccessAuthAdapter();
    await tester.pumpWidget(_routerApp(LoginPage(authAdapter: auth)));
    await tester.pumpAndSettle();
    // Tap signup text at bottom
    await tester.tap(find.textContaining("Don't have an account"));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signupPage')), findsOneWidget);
  });
}
