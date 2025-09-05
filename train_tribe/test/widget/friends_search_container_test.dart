import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:train_tribe/widgets/friends_widget/friends_search_container.dart';

class _FakeUserRepo implements IUserRepository {
  @override
  Future<bool> isUsernameUnique(String username) async => true;
  @override
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {}
}

class _FakeAuth extends Fake implements FirebaseAuth {}

// Minimal fake only to satisfy AppServices; never invoked thanks to debugUserDataResolver.
class _StubFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw UnimplementedError();
}

// Firestore no longer needed directly thanks to debugUserDataResolver.

Widget _wrap(AppServices services, Widget child) => AppServicesScope(
  services: services,
  child: MaterialApp(
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    supportedLocales: const [Locale('en'), Locale('it')],
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders friend tiles and toggles ghost', (tester) async {
    final userData = {
      'f1': {'username': 'alice', 'name': 'Alice', 'surname': 'A'},
    };
  // Provide a dummy firestore via existing service (not used due to debugUserDataResolver)
  final services = AppServices(firestore: _StubFirestore(), auth: _FakeAuth(), userRepository: _FakeUserRepo());
    String? toggledId;
    bool? toggledState;

    final controller = TextEditingController(text: 'a');

    await tester.pumpWidget(_wrap(services, FriendsSearchContainer(
      searchController: controller,
      onSearchChanged: (_) {},
      onSearchSubmitted: (_) {},
      filteredFriends: [MapEntry('f1', {'ghosted': false})],
      usersToAdd: const [],
      sentRequests: const [],
      onToggleVisibility: (id, isGhosted) { toggledId = id; toggledState = isGhosted; },
      onShowFriendDialog: (_, __, ___, ____, _____) {},
      onSendFriendRequest: (_) {},
      searching: false,
      debugUserDataResolver: () => userData,
    )));
    await tester.pump();

    expect(find.byKey(const Key('friend_tile_f1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggleGhost_f1')));
    await tester.pump();
    expect(toggledId, 'f1');
    expect(toggledState, false);
  });
}
