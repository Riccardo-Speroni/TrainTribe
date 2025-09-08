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
import 'package:train_tribe/widgets/locale_theme_selector.dart';
import 'package:train_tribe/widgets/mood_toggle.dart';
import 'package:train_tribe/complete_signup.dart';

// Test fakes
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Ensure clean SharedPreferences and global state before every test
    SharedPreferences.setMockInitialValues(<String, Object>{});
    resetAppGlobals();
  });

  // Wait helpers for async router redirects and page builds on desktop
  Future<void> _pumpUntilSettled(WidgetTester tester, {Duration timeout = const Duration(seconds: 8)}) async {
    final end = DateTime.now().add(timeout);
    // Initial settle
    await tester.pumpAndSettle();
    while (DateTime.now().isBefore(end)) {
      // Give router/async work time to progress
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame) {
        // One more settle to ensure no microtasks
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
    // One last settle before failing
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);
  }

  Future<void> pumpAppWithRouter(
    WidgetTester tester, {
    required GoRouter router,
    AppServices? services,
  }) async {
    final app = AppServicesScope(
      services: services ??
          AppServices(
            firestore: FakeFirebaseFirestore(),
            auth: MockFirebaseAuth(),
            userRepository: _InMemoryUserRepository(),
          ),
      child: MyApp(router: router),
    );

    await tester.pumpWidget(app);
    await _pumpUntilSettled(tester);
  }

  group('Router redirects', () {
    testWidgets('1) First launch goes to Onboarding when not completed', (tester) async {
      // onboarding_complete not set => should redirect to /onboarding
      final router = createAppRouter(
        getUid: () async => null,
        getUserData: (_) async => null,
      );

      await pumpAppWithRouter(tester, router: router);

      // Onboarding shows the locale/theme selector on first page
      await _waitFor(tester, find.byType(LocaleThemeSelector));
    });

    testWidgets('2) Completed onboarding + unauthenticated -> Login page', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{'onboarding_complete': true});

      final router = createAppRouter(
        getUid: () async => null,
        getUserData: (_) async => null,
      );

      await pumpAppWithRouter(tester, router: router);

      // Login page contains the email field keyed in the app
      await _waitFor(tester, find.byKey(const Key('emailField')));
      await _waitFor(tester, find.byKey(const Key('passwordField')));
    });

    testWidgets('3) Authenticated but incomplete profile -> Complete Sign Up', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{'onboarding_complete': true});

      final mockAuth = MockFirebaseAuth(signedIn: true);
      final fakeServices = AppServices(
        firestore: FakeFirebaseFirestore(),
        auth: mockAuth,
        userRepository: _InMemoryUserRepository(),
      );

      final router = createAppRouter(
        getUid: () async => 'uid_123',
        // No username => incomplete profile
        getUserData: (_) async => {'email': 'user@example.com'},
      );

      await pumpAppWithRouter(tester, router: router, services: fakeServices);

      // CompleteSignUp page composes a UserDetailsPage; assert the page type is present
      await _waitFor(tester, find.byType(CompleteSignUpPage));
    });

    testWidgets('4) Authenticated with complete profile -> Root (Home) page', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{'onboarding_complete': true});

      final mockAuth = MockFirebaseAuth(signedIn: true);
      final fakeServices = AppServices(
        firestore: FakeFirebaseFirestore(),
        auth: mockAuth,
        userRepository: _InMemoryUserRepository(),
      );

      final router = createAppRouter(
        getUid: () async => 'uid_123',
        getUserData: (_) async => {'email': 'user@example.com', 'username': 'foo'},
      );

      await pumpAppWithRouter(tester, router: router, services: fakeServices);

      // Root page first tab is HomePage containing a MoodToggle widget
      await _waitFor(tester, find.byType(MoodToggle));
    });

    testWidgets('5) Onboarding language change persists to SharedPreferences', (tester) async {
      // Start fresh (no onboarding_complete) to land on onboarding
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final router = createAppRouter(
        getUid: () async => null,
        getUserData: (_) async => null,
      );

      await pumpAppWithRouter(tester, router: router);

      // Open language menu and select Italian
      final languageButton = find.byKey(const Key('locale_selector_language'));
      await _waitFor(tester, languageButton);
      await tester.tap(languageButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('locale_item_it')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language_code'), 'it');
    });

    testWidgets('6) Completing onboarding while unauthenticated leads to Login', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final router = createAppRouter(
        getUid: () async => null,
        getUserData: (_) async => null,
      );

      await pumpAppWithRouter(tester, router: router);

      // Force English labels for stable button text (Next/Finish)
      final langBtn = find.byKey(const Key('locale_selector_language'));
      await _waitFor(tester, langBtn);
      await tester.tap(langBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('locale_item_en')));
      await tester.pumpAndSettle();

      // Tap Next until Finish appears, then tap Finish
      for (int i = 0; i < 4; i++) {
        if (find.text('Finish').evaluate().isNotEmpty) break;
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      if (find.text('Finish').evaluate().isEmpty) {
        // One more just in case
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      // Should redirect to Login
      await _waitFor(tester, find.byKey(const Key('emailField')));
    });

    testWidgets('7) Onboarding theme change persists to SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final router = createAppRouter(
        getUid: () async => null,
        getUserData: (_) async => null,
      );

      await pumpAppWithRouter(tester, router: router);

      final themeBtn = find.byKey(const Key('locale_selector_theme'));
      await _waitFor(tester, themeBtn);
      await tester.tap(themeBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme_item_dark')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode'), 1); // 0: light, 1: dark, 2: system
    });
  });
}

class _InMemoryUserRepository implements IUserRepository {
  final Map<String, Map<String, dynamic>> _db = {};

  @override
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    _db[uid] = {...data};
  }

  @override
  Future<bool> isUsernameUnique(String username) async {
    return !_db.values.any((m) => m['username'] == username);
  }
}
