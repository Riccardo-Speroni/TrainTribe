import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App imports
import 'package:train_tribe/main.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:train_tribe/utils/app_globals.dart';
import 'package:train_tribe/widgets/mood_toggle.dart';
import 'package:train_tribe/complete_signup.dart';
import 'package:train_tribe/login_page.dart';
import 'package:train_tribe/utils/auth_adapter.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Test fakes
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    resetAppGlobals();
  });

  Future<void> _pumpUntilSettled(WidgetTester tester, {Duration timeout = const Duration(seconds: 8)}) async {
    final end = DateTime.now().add(timeout);
    await tester.pumpAndSettle();
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame) {
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        if (!tester.binding.hasScheduledFrame) return;
      }
    }
  }

  Future<void> _waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 8)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);
  }

  group('User flows', () {
    testWidgets('Complete Sign Up saves user and navigates to Home', (tester) async {
      // Onboarding already completed
      SharedPreferences.setMockInitialValues(<String, Object>{'onboarding_complete': true});

      final uid = 'uid_abc';
      final mockAuth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid, email: 'u@e.com'));
      final repo = _InMemoryUserRepositoryWithGet();
      final services = AppServices(
        firestore: FakeFirebaseFirestore(),
        auth: mockAuth,
        userRepository: repo,
      );

      final router = createAppRouter(
        getUid: () async => uid,
        // Return current user data from the in-memory repo; initially incomplete,
        // after Save it will include 'username' and allow navigation to /root.
        getUserData: (u) async {
          final data = repo.getByUid(u);
          return data.isEmpty ? {'email': 'u@e.com'} : data;
        },
      );

      await tester.pumpWidget(AppServicesScope(services: services, child: MyApp(router: router)));
      await _pumpUntilSettled(tester);

      // On CompleteSignUpPage now
      await _waitFor(tester, find.byType(CompleteSignUpPage));

      await tester.enterText(find.byKey(const Key('nameField')), 'John');
      await tester.enterText(find.byKey(const Key('surnameField')), 'Doe');
      await tester.enterText(find.byKey(const Key('usernameField')), 'johndoe');
      // Allow async uniqueness check to complete and button state to update
      await tester.pump(const Duration(milliseconds: 400));

      // Wait until Save becomes enabled
      final saveFinder = find.byKey(const Key('actionButton'));
      await _waitFor(tester, saveFinder);
      ElevatedButton saveBtn = tester.widget(saveFinder);
      // give a frame for validation
      final end = DateTime.now().add(const Duration(seconds: 3));
      while (saveBtn.onPressed == null && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
        saveBtn = tester.widget(saveFinder);
      }
      expect(saveBtn.onPressed, isNotNull);
      await tester.tap(saveFinder);
      await _pumpUntilSettled(tester);

      // Should navigate to Root (Home) containing MoodToggle
      await _waitFor(tester, find.byType(MoodToggle));

      // Verify repo saved
      final saved = repo.getByUid(uid);
      expect(saved['username'], 'johndoe');
      expect(saved['name'], 'John');
      expect(saved['surname'], 'Doe');
    });

    testWidgets('Login form enablement and simple login flow via custom router', (tester) async {
      // Minimal custom router for the page to navigate to '/root' after login
      final testAdapter = _TestAuthAdapter();
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(authAdapter: testAdapter),
          ),
          GoRoute(
            path: '/root',
            builder: (context, state) => const Scaffold(body: Center(child: Text('ROOT'))),
          ),
        ],
      );

      // Provide services scope (not required for login, but keeps app wiring consistent)
      final services = AppServices(
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(),
        userRepository: _InMemoryUserRepositoryWithGet(),
      );

      await tester.pumpWidget(AppServicesScope(services: services, child: MyApp(router: router)));
      await _pumpUntilSettled(tester);

      // Initially disabled
      final loginBtn = find.byKey(const Key('loginButton'));
      expect(loginBtn, findsOneWidget);

      // Enter invalid email -> still disabled
      await tester.enterText(find.byKey(const Key('emailField')), 'foo');
      await tester.enterText(find.byKey(const Key('passwordField')), 'pass');
      await tester.pump(const Duration(milliseconds: 150));
      ElevatedButton btn = tester.widget(loginBtn);
      expect(btn.onPressed, isNull);

      // Enter valid email -> enabled
      await tester.enterText(find.byKey(const Key('emailField')), 'foo@example.com');
      await tester.pump(const Duration(milliseconds: 200));
      btn = tester.widget(loginBtn);
      expect(btn.onPressed, isNotNull);

      // Tap login and expect navigation to ROOT text
      await tester.tap(loginBtn);
      await _pumpUntilSettled(tester);
      await _waitFor(tester, find.text('ROOT'));

      // Verify adapter was called
      expect(testAdapter.lastEmail, 'foo@example.com');
      expect(testAdapter.lastPassword, 'pass');
    });
  });
}

class _InMemoryUserRepositoryWithGet implements IUserRepository {
  final Map<String, Map<String, dynamic>> _db = {};

  Map<String, dynamic> getByUid(String uid) => _db[uid] ?? <String, dynamic>{};

  @override
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    _db[uid] = {...data};
  }

  @override
  Future<bool> isUsernameUnique(String username) async {
    return !_db.values.any((m) => m['username'] == username);
  }
}

class _TestAuthAdapter implements AuthAdapter {
  final MockFirebaseAuth _auth = MockFirebaseAuth();
  String? lastEmail;
  String? lastPassword;

  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  get currentUser => _auth.currentUser;
}
