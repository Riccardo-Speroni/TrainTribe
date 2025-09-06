import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/profile_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: child,
    );

Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (c, s) => child),
    GoRoute(path: '/login', builder: (c, s) => const Scaffold(body: Text('login'))),
    GoRoute(path: '/onboarding', builder: (c, s) => const Scaffold(body: Text('onboarding'))),
  ]);
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('it')],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfilePage simplified', () {
    testWidgets('shows fallback when firebase not initialized', (tester) async {
      ProfilePageTestOverrides.debugOverrideInitialized = false;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = null;
      await tester.pumpWidget(_wrap(const ProfilePage()));
      await tester.pump();
      expect(find.text('Firebase not initialized'), findsOneWidget);
      ProfilePageTestOverrides.reset();
    });

    testWidgets('shows error when user null but firebase initialized', (tester) async {
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = null;
      await tester.pumpWidget(_wrap(const ProfilePage()));
      await tester.pump();
      expect(find.textContaining('Error'), findsOneWidget);
      ProfilePageTestOverrides.reset();
    });
    testWidgets('renders user data with overrides (narrow)', (tester) async {
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u1', email: 'a@b.c');
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      await fake.collection('users').doc('u1').set({
        'username': 'tester',
        'name': 'Test',
        'surname': 'User',
        'email': 'a@b.c'
      });
      await tester.pumpWidget(_wrap(const MediaQuery(
          data: MediaQueryData(size: Size(500, 800)), child: ProfilePage())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.text('tester'), findsAtLeastNWidgets(1),
          reason: 'username should appear once data snapshot arrives');
      ProfilePageTestOverrides.reset();
    });

    testWidgets('renders user data with overrides (wide)', (tester) async {
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u2', email: 'z@b.c');
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      await fake.collection('users').doc('u2').set({
        'username': 'wideuser',
        'name': 'Wide',
        'surname': 'Layout',
        'email': 'z@b.c'
      });
      await tester.pumpWidget(_wrap(const MediaQuery(
          data: MediaQueryData(size: Size(900, 800)), child: ProfilePage())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.text('wideuser'), findsAtLeastNWidgets(1));
      ProfilePageTestOverrides.reset();
    });

    testWidgets('logout button triggers signOut hook', (tester) async {
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u3', email: 'l@o.g');
      int signOutCalls = 0;
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      ProfilePageTestOverrides.debugSignOutFn = () async { signOutCalls++; };
      await fake.collection('users').doc('u3').set({'username': 'lo_user'});
  await tester.pumpWidget(_wrapWithRouter(const MediaQuery(data: MediaQueryData(size: Size(800, 800)), child: ProfilePage())));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
  final logoutFinder = find.byKey(const Key('profile_logout_button'));
  await tester.ensureVisible(logoutFinder);
  await tester.tap(logoutFinder);
      await tester.pump();
      expect(signOutCalls, 1);
      ProfilePageTestOverrides.reset();
    });

    testWidgets('logout navigates to login page', (tester) async {
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u_nav', email: 'n@v.g');
      bool signOutCalls = false;
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      ProfilePageTestOverrides.debugSignOutFn = () async { signOutCalls = true; };
      await fake.collection('users').doc('u_nav').set({'username': 'navuser'});
      await tester.pumpWidget(_wrapWithRouter(const MediaQuery(data: MediaQueryData(size: Size(700, 900)), child: ProfilePage())));
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  final logoutFinder = find.byKey(const Key('profile_logout_button'));
  await tester.ensureVisible(logoutFinder);
  await tester.tap(logoutFinder, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(signOutCalls, isTrue);
      expect(find.text('login'), findsOneWidget);
      ProfilePageTestOverrides.reset();
    });

  testWidgets('reset onboarding button present and clickable', (tester) async {
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u4', email: 'r@o.g');
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      await fake.collection('users').doc('u4').set({'username': 'resetuser'});
  await tester.pumpWidget(_wrapWithRouter(const MediaQuery(data: MediaQueryData(size: Size(600, 1200)), child: ProfilePage())));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final resetFinder = find.byKey(const Key('profile_reset_onboarding_button'));
      expect(resetFinder, findsOneWidget);
  await tester.ensureVisible(resetFinder);
  await tester.tap(resetFinder, warnIfMissed: false);
      // We don't assert navigation here (GoRouter), just that tap doesn't throw and button exists.
      ProfilePageTestOverrides.reset();
    });

    testWidgets('reset onboarding clears onboarding_complete preference', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u_reset_nav', email: 'r@n.v');
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      await fake.collection('users').doc('u_reset_nav').set({'username': 'resetnav'});
      await tester.pumpWidget(_wrapWithRouter(const MediaQuery(data: MediaQueryData(size: Size(500, 900)), child: ProfilePage())));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final resetFinder = find.byKey(const Key('profile_reset_onboarding_button'));
      await tester.ensureVisible(resetFinder);
      await tester.tap(resetFinder, warnIfMissed: false);
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isFalse);
      ProfilePageTestOverrides.reset();
    });


    testWidgets('wide layout uses Row when wide', (tester) async {
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u6', email: 'w@i.d');
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      await fake.collection('users').doc('u6').set({'username': 'wideagain'});
  await tester.pumpWidget(_wrapWithRouter(const MediaQuery(data: MediaQueryData(size: Size(1000, 800)), child: ProfilePage())));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final actionsParent = tester.widget(find.byKey(const Key('profile_bottom_actions')));
      expect(actionsParent, isA<Row>());
      ProfilePageTestOverrides.reset();
    });

    testWidgets('narrow layout uses Column for bottom actions', (tester) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(250, 900);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });
      final fake = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u_col', email: 'c@o.l');
      ProfilePageTestOverrides.debugOverrideInitialized = true;
      ProfilePageTestOverrides.debugBypassFirebaseAuth = true;
      ProfilePageTestOverrides.debugUser = user;
      ProfilePageTestOverrides.debugFirestore = fake;
      await fake.collection('users').doc('u_col').set({'username': 'coluser'});
      await tester.pumpWidget(_wrapWithRouter(const ProfilePage()));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      final widgetObj = tester.widget(find.byKey(const Key('profile_bottom_actions')));
      expect(widgetObj, isA<Column>());
      ProfilePageTestOverrides.reset();
    });
  });
}
