import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:train_tribe/complete_signup.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'fakes/fake_user_repository.dart';

Widget _make(AppServices services) {
  final router = GoRouter(
    initialLocation: '/complete_signup',
    routes: [
      GoRoute(path: '/root', builder: (c, s) => const Scaffold(body: Center(child: Text('Root', key: Key('rootPage'))))),
      GoRoute(path: '/complete_signup', builder: (c, s) => const CompleteSignUpPage(email: 'a@b.com', name: 'X')),
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
  testWidgets('shows error dialog on repository failure', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'uErr', email: 'a@b.com'), signedIn: true);
    final fakeRepo = FakeUserRepository()..throwOnSave = true;
    final services = AppServices(firestore: firestore, auth: auth, userRepository: fakeRepo);

    await tester.pumpWidget(_make(services));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nameField')), 'Err');
    await tester.enterText(find.byKey(const Key('surnameField')), 'User');
    await tester.enterText(find.byKey(const Key('usernameField')), 'erruser');
    await tester.pump();
    final btn = find.byKey(const Key('actionButton'));
    await tester.ensureVisible(btn);
    await tester.tap(btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Expect an error dialog
    expect(find.byType(AlertDialog), findsOneWidget);
    // Ensure we did not navigate
    expect(find.byKey(const Key('rootPage')), findsNothing);
  });
}
