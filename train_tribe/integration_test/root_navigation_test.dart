import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App imports
import 'package:train_tribe/main.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:train_tribe/utils/app_globals.dart';
import 'package:train_tribe/widgets/mood_toggle.dart';
import 'package:train_tribe/widgets/locale_theme_selector.dart';
import 'package:train_tribe/profile_page.dart';

// Test fakes
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_complete': true,
      'language_code': 'en',
    });
    resetAppGlobals();
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

  Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 8)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);
  }

  group('Root navigation', () {
    testWidgets('Navigate to Profile and reset onboarding redirects to Onboarding', (tester) async {
      final uid = 'uid_profile';
      final mockUser = MockUser(uid: uid, email: 'u@e.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc(uid).set({
        'username': 'tester',
        'name': 'Test',
        'surname': 'User',
        'email': 'u@e.com',
      });

      // Override ProfilePage to avoid real Firebase
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = mockUser;
      ProfilePageTestOverrides.debugFirestore = firestore;

      final services = AppServices(
        firestore: firestore,
        auth: auth,
        userRepository: _InMemoryUserRepository(),
      );

      final router = createAppRouter(
        getUid: () async => uid,
        getUserData: (_) async => {'username': 'tester'},
      );

      await tester.pumpWidget(AppServicesScope(services: services, child: MyApp(router: router)));
      await pumpUntilSettled(tester);

      // On Home first
      await waitFor(tester, find.byType(MoodToggle));

      // Go to Profile via rail icon (or fallback to label text)
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
      } else {
        // Fallback for bottom nav: label text
        await tester.tap(find.text('Profile'));
      }
      await pumpUntilSettled(tester);

      // Reset onboarding -> should redirect to Onboarding page (LocaleThemeSelector present)
      await waitFor(tester, find.byKey(const Key('profile_reset_onboarding_button')));
      await tester.tap(find.byKey(const Key('profile_reset_onboarding_button')));
      await pumpUntilSettled(tester);
      await waitFor(tester, find.byType(LocaleThemeSelector));

      // SharedPreferences onboarding flag should be false now
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isFalse);
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
