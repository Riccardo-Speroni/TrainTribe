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

Widget _wrapFriends(FakeFirebaseFirestore firestore, MockFirebaseAuth auth) {
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
  testWidgets('Friends legend dialog opens and closes', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true);
    await firestore.collection('users').doc('u1').set({
      'friends': <String, dynamic>{},
      'receivedRequests': <String>[],
      'sentRequests': <String>[],
    });

    await tester.pumpWidget(_wrapFriends(firestore, auth));
    await tester.pumpAndSettle();

    // Tap the info icon in the AppBar to open the legend dialog
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legend_dialog')), findsOneWidget);

    // Close the dialog
    await tester.tap(find.byKey(const Key('legend_ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legend_dialog')), findsNothing);
  });

  testWidgets('Search and add friend triggers send request updates', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true);
    await firestore.collection('users').doc('u1').set({
      'username': 'me',
      'friends': <String, dynamic>{},
      'receivedRequests': <String>[],
      'sentRequests': <String>[],
    });
    await firestore.collection('users').doc('u4').set({
      'username': 'Al',
      'phone': '+391111',
    });

    await tester.pumpWidget(_wrapFriends(firestore, auth));
    await tester.pumpAndSettle();

    // Type query and submit to trigger _searchUsers
    final field = find.byKey(const Key('friendsSearchField'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'Al');
    // Simulate pressing Enter/Done
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Tap the add friend button for u4
    final addBtn = find.byKey(const Key('addFriend_u4'));
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify Firestore updates
    final u1 = await firestore.collection('users').doc('u1').get();
    final u4 = await firestore.collection('users').doc('u4').get();
    expect(List<String>.from(u1.data()!['sentRequests'] ?? []), contains('u4'));
    expect(List<String>.from(u4.data()!['receivedRequests'] ?? []), contains('u1'));
    // Notification created
    final notifs = await firestore.collection('notifications').get();
    expect(notifs.docs.where((d) => d.data()['userId'] == 'u4').length, 1);
  });

  testWidgets('Toggle ghost on friend updates Firestore', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true);
    await firestore.collection('users').doc('u1').set({
      'username': 'me',
      'friends': {
        'u2': {'ghosted': false}
      },
      'receivedRequests': <String>[],
      'sentRequests': <String>[],
    });
    await firestore.collection('users').doc('u2').set({
      'username': 'Alice',
    });

    await tester.pumpWidget(_wrapFriends(firestore, auth));
    await tester.pumpAndSettle();

    // Tap the toggle ghost button for u2
    final toggle = find.byKey(const Key('toggleGhost_u2'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final u1 = await firestore.collection('users').doc('u1').get();
    expect((u1.data()!['friends'] as Map)['u2']['ghosted'], true);
  });

  testWidgets('Accept and decline friend requests update Firestore', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true);
    await firestore.collection('users').doc('u1').set({
      'username': 'me',
      'friends': <String, dynamic>{},
      'receivedRequests': ['u3'],
      'sentRequests': <String>[],
    });
    await firestore.collection('users').doc('u3').set({
      'username': 'Bob',
      'friends': <String, dynamic>{},
      'receivedRequests': <String>[],
      'sentRequests': ['u1'],
    });

    await tester.pumpWidget(_wrapFriends(firestore, auth));
    await tester.pumpAndSettle();

    // Accept
    final accept = find.byKey(const Key('acceptRequest_u3'));
    expect(accept, findsOneWidget);
    await tester.tap(accept);
    await tester.pumpAndSettle();

    var u1 = await firestore.collection('users').doc('u1').get();
    var u3 = await firestore.collection('users').doc('u3').get();
    expect(List<String>.from(u1.data()!['receivedRequests'] ?? []), isNot(contains('u3')));
    expect((u1.data()!['friends'] as Map).containsKey('u3'), true);
    expect(List<String>.from(u3.data()!['sentRequests'] ?? []), isNot(contains('u1')));
    expect((u3.data()!['friends'] as Map).containsKey('u1'), true);

    // Add another request then decline
    await firestore.collection('users').doc('u1').update({
      'receivedRequests': ['u4']
    });
    await firestore.collection('users').doc('u4').set({'username': 'Al'});
    await tester.pumpAndSettle();

    final decline = find.byKey(const Key('declineRequest_u4'));
    expect(decline, findsOneWidget);
    await tester.tap(decline);
    await tester.pumpAndSettle();

    u1 = await firestore.collection('users').doc('u1').get();
    final u4 = await firestore.collection('users').doc('u4').get();
    expect(List<String>.from(u1.data()!['receivedRequests'] ?? []), isNot(contains('u4')));
    expect(List<String>.from(u4.data()!['sentRequests'] ?? []), isNot(contains('u1')));
  });
}
