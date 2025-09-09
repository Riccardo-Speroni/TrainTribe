import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/login_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/auth_adapter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _FakeAuthAdapter implements AuthAdapter {
  bool called = false;
  String? email;
  String? password;
  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    called = true;
    this.email = email;
    this.password = password;
    await Future.delayed(const Duration(milliseconds: 10));
    // Return a minimal fake using a throwaway implementation via a fake credential.
    // For tests that only check call, we can throw UnimplementedError for fields if accessed.
    return Future.value(FakeUserCredential());
  }

  @override
  User? get currentUser => null;
}

class FakeUserCredential implements UserCredential {
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
  @override
  AuthCredential? get credential => null;
  @override
  User? get user => null;
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: child,
    );

void main() {
  testWidgets('login button disabled until valid email & password entered', (tester) async {
    final fakeAuth = _FakeAuthAdapter();
    await tester.pumpWidget(_wrap(LoginPage(authAdapter: fakeAuth)));
    // Allow first frame & localization load
    await tester.pump();

    final loginButton = find.byKey(const Key('loginButton'));
    expect(loginButton, findsOneWidget, reason: 'Login button with Key(loginButton) should be in widget tree');

    // Initially disabled
    final ElevatedButton btnWidget = tester.widget(loginButton);
    expect(btnWidget.onPressed, isNull, reason: 'Button must be disabled before valid inputs');

    await tester.enterText(find.byKey(const Key('emailField')), 'user@test.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'Password1');
    await tester.pumpAndSettle();

    final ElevatedButton btnEnabled = tester.widget(loginButton);
    expect(btnEnabled.onPressed, isNotNull, reason: 'Button should enable after valid inputs');

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(fakeAuth.called, true);
    expect(fakeAuth.email, 'user@test.com');
  });

  testWidgets('invalid email keeps login button disabled', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pump();
    final loginButton = find.byKey(const Key('loginButton'));
    expect(loginButton, findsOneWidget);

    await tester.enterText(find.byKey(const Key('emailField')), 'invalid_email');
    await tester.enterText(find.byKey(const Key('passwordField')), 'whatever');
    await tester.pumpAndSettle();

    final ElevatedButton btn = tester.widget(loginButton);
    expect(btn.onPressed, isNull, reason: 'Button must remain disabled for invalid email');
  });
}
