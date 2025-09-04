import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:train_tribe/complete_signup.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _buildRouter(AppServices services) {
  final router = GoRouter(
    initialLocation: '/complete_signup',
    routes: [
      GoRoute(path: '/root', builder: (c, s) => const Scaffold(body: Center(child: Text('Root', key: Key('rootPage'))))),
      GoRoute(
        path: '/complete_signup',
        builder: (c, s) => CompleteSignUpPage(email: 'a@b.com', name: 'Alice'),
      ),
    ],
  );
  return AppServicesScope(
    services: services,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
    ),
  );
}

void main() {
  group('CompleteSignUpPage', () {
    testWidgets('saves profile and navigates to /root', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'), signedIn: true);
      final services = AppServices(
        firestore: firestore,
        auth: auth,
        userRepository: FirestoreUserRepository(firestore),
      );

      await tester.pumpWidget(_buildRouter(services));
      await tester.pumpAndSettle();

      // Fill mandatory fields
      await tester.enterText(find.byKey(const Key('nameField')), 'Alice');
      await tester.enterText(find.byKey(const Key('surnameField')), 'Smith');
      await tester.enterText(find.byKey(const Key('usernameField')), 'alicesmith');
      await tester.pump();

      final actionFinder = find.byKey(const Key('actionButton'));
      await tester.ensureVisible(actionFinder);
      await tester.tap(actionFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Navigation occurred
      expect(find.byKey(const Key('rootPage')), findsOneWidget);
      final saved = await firestore.collection('users').doc('u1').get();
      expect(saved.exists, isTrue);
      expect(saved.data()!['username'], 'alicesmith');
    });
  });
}
