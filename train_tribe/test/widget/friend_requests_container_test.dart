import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:train_tribe/widgets/friends_widget/friend_requests_container.dart';

class _FakeUserRepo implements IUserRepository {
  @override
  Future<bool> isUsernameUnique(String username) async => true;
  @override
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {}
}
class _FakeAuth extends Fake implements FirebaseAuth {}

class _StubFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw UnimplementedError();
}

// Firestore classes removed; using debugUserDataResolver instead.

Widget _wrap(AppServices services, Widget child) => AppServicesScope(
  services: services,
  child: MaterialApp(
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    supportedLocales: const [Locale('en'), Locale('it')],
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('friend requests accept/decline callbacks', (tester) async {
  final userData = {'r1': {'username': 'charlie'}};
  final services = AppServices(firestore: _StubFirestore(), auth: _FakeAuth(), userRepository: _FakeUserRepo());
    final accepted = <String>[];
    final declined = <String>[];

    await tester.pumpWidget(_wrap(services, FriendRequestsContainer(
      friendRequests: const ['r1'],
      onAccept: (id) => accepted.add(id),
      onDecline: (id) => declined.add(id),
      debugUserDataResolver: () => userData,
    )));
    await tester.pump();

    await tester.tap(find.byKey(const Key('acceptRequest_r1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('declineRequest_r1')));
    await tester.pump();
    expect(accepted, ['r1']);
    expect(declined, ['r1']);
  });
}
