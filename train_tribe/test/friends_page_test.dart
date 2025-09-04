import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/friends_page.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _wrap(Widget child, AppServices services) => AppServicesScope(
      services: services,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: Scaffold(body: child),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FriendsPage', () {
    testWidgets('accept friend request updates documents', (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'username': 'me',
        'friends': <String, dynamic>{},
        'receivedRequests': ['u2'],
        'sentRequests': <String>[],
      });
      await firestore.collection('users').doc('u2').set(<String, dynamic>{
        'username': 'other',
        'friends': <String, dynamic>{},
        'receivedRequests': <String>[],
        'sentRequests': ['u1'],
      });

      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'), signedIn: true);
      final services = AppServices(
        firestore: firestore,
        auth: auth,
        userRepository: FirestoreUserRepository(firestore),
      );

      await tester.pumpWidget(_wrap(const FriendsPage(), services));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('friendRequestsContainer')), findsOneWidget);
      await tester.tap(find.byKey(const Key('acceptRequest_u2')));
      await tester.pumpAndSettle();

      final u1 = await firestore.collection('users').doc('u1').get();
      final u2 = await firestore.collection('users').doc('u2').get();
      expect((u1.data()?['friends'] as Map).containsKey('u2'), isTrue);
      expect((u2.data()?['friends'] as Map).containsKey('u1'), isTrue);
      expect(List<String>.from(u1.data()?['receivedRequests'] ?? []).contains('u2'), isFalse);
      expect(List<String>.from(u2.data()?['sentRequests'] ?? []).contains('u1'), isFalse);
    });

    testWidgets('search and send friend request', (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'username': 'me',
        'friends': <String, dynamic>{},
        'receivedRequests': <String>[],
        'sentRequests': <String>[],
      });
      await firestore.collection('users').doc('u2').set(<String, dynamic>{
        'username': 'canduser',
        'friends': <String, dynamic>{},
        'receivedRequests': <String>[],
        'sentRequests': <String>[],
      });
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'), signedIn: true);
      final services = AppServices(
        firestore: firestore,
        auth: auth,
        userRepository: FirestoreUserRepository(firestore),
      );

      await tester.pumpWidget(_wrap(const FriendsPage(), services));
      await tester.pumpAndSettle();

      // Enter partial username and submit
      await tester.enterText(find.byKey(const Key('friendsSearchField')), 'cand');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Candidate appears with add button
      expect(find.byKey(const Key('addFriend_u2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('addFriend_u2')));
      await tester.pumpAndSettle();

      final u1 = await firestore.collection('users').doc('u1').get();
      final u2 = await firestore.collection('users').doc('u2').get();
      expect(List<String>.from(u1.data()?['sentRequests'] ?? []).contains('u2'), isTrue);
      expect(List<String>.from(u2.data()?['receivedRequests'] ?? []).contains('u1'), isTrue);
    });

    testWidgets('decline friend request removes from arrays', (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'username': 'me',
        'friends': <String, dynamic>{},
        'receivedRequests': ['u2'],
        'sentRequests': <String>[],
      });
      await firestore.collection('users').doc('u2').set(<String, dynamic>{
        'username': 'other',
        'friends': <String, dynamic>{},
        'receivedRequests': <String>[],
        'sentRequests': ['u1'],
      });
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'), signedIn: true);
      final services = AppServices(
        firestore: firestore,
        auth: auth,
        userRepository: FirestoreUserRepository(firestore),
      );
      await tester.pumpWidget(_wrap(const FriendsPage(), services));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('friendRequestsContainer')), findsOneWidget);
      await tester.tap(find.byKey(const Key('declineRequest_u2')));
      await tester.pumpAndSettle();
      final u1 = await firestore.collection('users').doc('u1').get();
      final u2 = await firestore.collection('users').doc('u2').get();
      expect(List<String>.from(u1.data()?['receivedRequests'] ?? []).contains('u2'), isFalse);
      expect(List<String>.from(u2.data()?['sentRequests'] ?? []).contains('u1'), isFalse);
    });

    testWidgets('toggle ghost status updates friend map', (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'username': 'me',
        'friends': <String, dynamic>{
          'u2': {'ghosted': false}
        },
        'receivedRequests': <String>[],
        'sentRequests': <String>[],
      });
      await firestore.collection('users').doc('u2').set(<String, dynamic>{
        'username': 'other',
        'friends': <String, dynamic>{
          'u1': {'ghosted': false}
        },
        'receivedRequests': <String>[],
        'sentRequests': <String>[],
      });
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'), signedIn: true);
      final services = AppServices(
        firestore: firestore,
        auth: auth,
        userRepository: FirestoreUserRepository(firestore),
      );
      await tester.pumpWidget(_wrap(const FriendsPage(), services));
      await tester.pumpAndSettle();
      // Ensure friend tile loaded
      expect(find.byKey(const Key('friendsSearchField')), findsOneWidget);
      // Toggle ghost (button generated per friend inside FutureBuilder)
      // Wait a frame for FutureBuilders
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('toggleGhost_u2'));
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final u1 = await firestore.collection('users').doc('u1').get();
      final friends = (u1.data()?['friends'] as Map?) ?? {};
      expect((friends['u2'] as Map)['ghosted'], isTrue);
    });
  });
}
