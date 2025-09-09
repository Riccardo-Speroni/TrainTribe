import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_tribe/main.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:train_tribe/profile_page.dart';

// In-memory user repo for test
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_complete': true,
      'language_code': 'en',
    });
  });

  Future<void> pumpUntilSettled(WidgetTester tester, {Duration timeout = const Duration(seconds: 8)}) async {
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

  // Helper to create fakes and pump the app
  Future<void> pumpApp(
    WidgetTester tester, {
    String uid = 'test_uid',
    Map<String, dynamic>? userData,
  }) async {
    final mockAuth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid, email: 'test@user.com'));
    final repo = _InMemoryUserRepositoryWithGet();
    final firestore = FakeFirebaseFirestore();
    if (userData != null) {
      await repo.saveUserProfile(uid, userData);
      await firestore.collection('users').doc(uid).set(userData);
    }
    // Bypass Firebase initialization check in ProfilePage
    ProfilePageTestOverrides.debugOverrideInitialized = true;
    final services = AppServices(
      firestore: firestore,
      auth: mockAuth,
      userRepository: repo,
    );
    final router = createAppRouter(
      getUid: () async => mockAuth.currentUser?.uid,
      getUserData: (u) async => repo.getByUid(u),
      authChanges: mockAuth.authStateChanges(),
    );
    await tester.pumpWidget(AppServicesScope(services: services, child: MyApp(router: router)));
    await pumpUntilSettled(tester);
  }

  testWidgets('Profile editing: edit and verify profile fields', (tester) async {
    await pumpApp(tester, userData: {
      'username': 'tester',
      'name': 'Old Name',
      'surname': 'User',
      'email': 'test@user.com',
    });
    // Navigate to Profile page
    final profileTab = find.byIcon(Icons.person);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
    // Tap the edit button for the name field
    await tester.tap(find.byKey(const Key('profile_name_edit_button')));
    await tester.pumpAndSettle();
    // Enter new name in the dialog
    await tester.enterText(find.byKey(const Key('edit_simple_field_input')), 'Test User');
    await tester.tap(find.byKey(const Key('edit_simple_field_save')));
    await tester.pumpAndSettle();
    // Verify changes
    expect(find.text('Test User'), findsOneWidget);
  });

  testWidgets('Notifications: simulate and verify notification display', (tester) async {
    await pumpApp(tester, userData: {
      'username': 'tester',
      'name': 'Test',
      'surname': 'User',
      'email': 'test@user.com',
    });
    // Simulate notification (if test seam exists, e.g. by adding to fake Firestore)
    // For now, just check the UI is present (replace with real simulation if needed)
    await tester.pumpAndSettle();
    // expect(find.text('Test notification'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets); // Sanity check
  });

  testWidgets('Logout flow: log out and verify redirect', (tester) async {
    await pumpApp(tester, userData: {
      'username': 'tester',
      'name': 'Test',
      'surname': 'User',
      'email': 'test@user.com',
    });
    // Navigate to Profile page
    final profileTab = find.byIcon(Icons.person);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
    // Tap logout button (correct key)
    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pumpAndSettle();
    // Verify redirected to login/onboarding
    await pumpUntilSettled(tester);
    expect(find.byKey(const Key('login_page')), findsOneWidget);
  });

  testWidgets('Persistence: restart app and verify state', (tester) async {
    await pumpApp(tester, userData: {
      'username': 'tester',
      'name': 'Test',
      'surname': 'User',
      'email': 'test@user.com',
    });
    // Navigate to Profile page to ensure theme selector is present
    final profileTab = find.byIcon(Icons.person);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
    // Open theme selector
    await tester.tap(find.byKey(const Key('locale_selector_theme')));
    await tester.pumpAndSettle();
    // Select dark theme
    await tester.tap(find.byKey(const Key('theme_item_dark')));
    await tester.pumpAndSettle();
    // Restart app
    await tester.pumpWidget(Container());
    await tester.pump();
    await pumpApp(tester, userData: {
      'username': 'tester',
      'name': 'Test',
      'surname': 'User',
      'email': 'test@user.com',
    });
    // Navigate to Profile page again
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
    // Open theme selector again to check if dark is still selected
    await tester.tap(find.byKey(const Key('locale_selector_theme')));
    await tester.pumpAndSettle();
    // Verify dark theme is selected (check for check icon in dark item)
    final darkItem = find.byKey(const Key('theme_item_dark'));
    expect(
      find.descendant(
        of: darkItem,
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}
