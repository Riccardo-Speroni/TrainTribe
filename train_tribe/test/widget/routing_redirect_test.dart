import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_tribe/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Reset hooks before each test
    app.testCurrentUserUidGetter = null;
    app.testUserDataGetter = null;
  });

  GoRouter makeTestRouter({
    required String initialLocation,
    required Future<String?> Function() getUid,
    required Future<Map<String, dynamic>?> Function(String) getUserData,
  }) {
    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: initialLocation,
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

        if (!onboardingComplete && state.fullPath != '/onboarding') {
          return '/onboarding';
        }

        final uid = await getUid();
        if (uid == null) {
          final path = state.fullPath ?? '';
          const allowedUnauthed = ['/onboarding', '/login', '/signup'];
          if (!allowedUnauthed.contains(path)) {
            return '/login';
          }
        } else {
          final data = await getUserData(uid);
          if (data == null || data['username'] == null) {
            return '/complete_signup';
          } else if (state.fullPath == '/login' || state.fullPath == '/signup') {
            return '/root';
          }
        }
        return null;
      },
      routes: [
        GoRoute(path: '/onboarding', builder: (_, __) => const Text('onboarding')),
        GoRoute(path: '/login', builder: (_, __) => const Text('login')),
        GoRoute(path: '/signup', builder: (_, __) => const Text('signup')),
        GoRoute(path: '/root', builder: (_, __) => const Text('root')),
        GoRoute(path: '/complete_signup', builder: (_, __) => const Text('complete_signup')),
      ],
    );
  }

  Future<Widget> makeApp({String initialLocation = '/root', String? uid, Map<String, dynamic>? userData}) async {
    final router = makeTestRouter(
      initialLocation: initialLocation,
      getUid: () async => uid,
      getUserData: (id) async => userData,
    );
    return app.MyApp(router: router);
  }

  group('GoRouter redirects', () {
    testWidgets('Unauthenticated with onboarding incomplete -> onboarding page', (tester) async {
      await tester.pumpWidget(await makeApp(uid: null));
      await tester.pumpAndSettle();
      expect(find.text('onboarding'), findsOneWidget);
    });

    testWidgets('Unauthenticated with onboarding complete -> login page', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      await tester.pumpWidget(await makeApp(uid: null));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('Authenticated with incomplete profile -> complete_signup', (tester) async {
      // Onboarding complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      // Mock auth + user data via hooks
      await tester.pumpWidget(await makeApp(uid: 'uid-1', userData: null));
      await tester.pumpAndSettle();
      expect(find.text('complete_signup'), findsOneWidget);
    });

    testWidgets('Authenticated with complete profile and navigating to login redirects to root', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      // Start at login; since already logged in with complete profile, should redirect to root
      await tester.pumpWidget(await makeApp(initialLocation: '/login', uid: 'uid-2', userData: {'username': 'test'}));
      await tester.pumpAndSettle();
      expect(find.text('root'), findsOneWidget);
    });
  });
}
