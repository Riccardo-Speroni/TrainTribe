import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_tribe/main.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';

Widget _wrap(GoRouter router) {
  final firestore = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth();
  final services = AppServices(
    firestore: firestore,
    auth: auth,
    userRepository: FirestoreUserRepository(firestore),
  );
  return AppServicesScope(
    services: services,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('it')],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('onboarding incomplete redirects to /onboarding', (tester) async {
    // No onboarding_complete set
    final router = createAppRouter(
      getUid: () async => null,
      getUserData: (uid) async => null,
    );
    await tester.pumpWidget(_wrap(router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
  });

  testWidgets('unauthenticated redirects to /login when onboarding complete', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final router = createAppRouter(getUid: () async => null, getUserData: (uid) async => null);
    await tester.pumpWidget(_wrap(router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('authenticated with incomplete profile goes to /complete_signup', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final router = createAppRouter(getUid: () async => 'uid1', getUserData: (uid) async => null);
    await tester.pumpWidget(_wrap(router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/complete_signup');
  });

  testWidgets('authenticated and complete profile redirect away from /login to /root', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final router = createAppRouter(
      getUid: () async => 'uid1',
      getUserData: (uid) async => {'username': 'ok'},
    );
    await tester.pumpWidget(_wrap(router));
    // Navigate to /login to trigger redirect-away rule
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/root');
  });
}
