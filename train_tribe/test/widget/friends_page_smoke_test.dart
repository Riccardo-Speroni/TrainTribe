import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/friends_page.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _wrapFriends() {
  final firestore = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'), signedIn: true);
  // Seed a minimal user doc so the StreamBuilder gets data
  firestore.collection('users').doc('u1').set({
    'friends': <String, dynamic>{},
    'receivedRequests': <String>[],
    'sentRequests': <String>[],
  });
  final services = AppServices(
    firestore: firestore,
    auth: auth,
    userRepository: FirestoreUserRepository(firestore),
  );
  return AppServicesScope(
    services: services,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: const FriendsPage(),
    ),
  );
}

void main() {
  testWidgets('FriendsPage renders and shows search container', (tester) async {
    await tester.pumpWidget(_wrapFriends());
    await tester.pumpAndSettle();
    expect(find.text('Friends'), findsWidgets);
    expect(find.byKey(const Key('friendsSearchContainer')), findsOneWidget);
  });
}
