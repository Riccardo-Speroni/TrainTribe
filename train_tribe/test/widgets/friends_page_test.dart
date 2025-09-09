import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/widgets/friends_widget/friend_requests_container.dart';
import 'package:train_tribe/widgets/friends_widget/friends_search_container.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: child),
    );

class _FriendRequestsHarness extends StatefulWidget {
  const _FriendRequestsHarness({required this.initialRequests});
  final List<String> initialRequests;
  @override
  State<_FriendRequestsHarness> createState() => _FriendRequestsHarnessState();
}

class _FriendRequestsHarnessState extends State<_FriendRequestsHarness> {
  late final List<String> _requests = List.of(widget.initialRequests);
  final Map<String, Map<String, dynamic>> _userData = {
    'reqA': {'username': 'alice'},
    'reqB': {'username': 'bob'},
  };

  @override
  Widget build(BuildContext context) {
    return FriendRequestsContainer(
      friendRequests: _requests,
      onAccept: (u) => setState(() => _requests.remove(u)),
      onDecline: (u) => setState(() => _requests.remove(u)),
      debugUserDataResolver: () => _userData,
    );
  }
}

class _FriendsSearchHarness extends StatefulWidget {
  const _FriendsSearchHarness();
  @override
  State<_FriendsSearchHarness> createState() => _FriendsSearchHarnessState();
}

class _FriendsSearchHarnessState extends State<_FriendsSearchHarness> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, dynamic> _friendState = {'friend1': {'ghosted': false}};
  final List<Map<String, dynamic>> _usersToAdd = [
    {'uid': 'zoeUser', 'username': 'zoe'},
  ];
  final List<String> _sentRequests = <String>[];
  final Map<String, Map<String, dynamic>> _userData = {
    'friend1': {'username': 'buddy', 'phone': '+39123123'},
    'zoeUser': {'username': 'zoe'},
  };

  @override
  Widget build(BuildContext context) {
    return FriendsSearchContainer(
      searchController: _controller,
      onSearchChanged: (q) => setState(() {}),
      onSearchSubmitted: (q) => setState(() {}),
      filteredFriends: _friendState.entries.map((e) => MapEntry(e.key, e.value)).toList(),
      usersToAdd: _usersToAdd,
      sentRequests: _sentRequests,
      onToggleVisibility: (uid, isGhosted) => setState(() => _friendState[uid]['ghosted'] = !isGhosted),
      onShowFriendDialog: (_, __, ___, ____, _____) {},
      onSendFriendRequest: (uid) => setState(() => _sentRequests.add(uid)),
      searching: false,
      debugUserDataResolver: () => _userData,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FriendRequestsContainer', () {
    testWidgets('shows and accepts requests', (tester) async {
      await tester.pumpWidget(_wrap(const _FriendRequestsHarness(initialRequests: ['reqA'])));
      await tester.pump();
      // Container key from implementation is friend_requests_container
      expect(find.byKey(const Key('friend_requests_container')), findsOneWidget);
      final accept = find.byKey(const Key('acceptRequest_reqA'));
      expect(accept, findsOneWidget);
      await tester.tap(accept);
      await tester.pump();
      expect(find.byKey(const Key('acceptRequest_reqA')), findsNothing);
    });
  });

  group('FriendsSearchContainer', () {
    testWidgets('renders friend tile and toggles ghost', (tester) async {
      await tester.pumpWidget(_wrap(const _FriendsSearchHarness()));
      await tester.pump();
      expect(find.byKey(const Key('friend_tile_friend1')), findsOneWidget);
      final toggle = find.byKey(const Key('toggleGhost_friend1'));
      await tester.tap(toggle);
      await tester.pump();
      // Tapping again should still find the tile (state updated)
      expect(find.byKey(const Key('friend_tile_friend1')), findsOneWidget);
    });

    testWidgets('adds friend from usersToAdd list', (tester) async {
      await tester.pumpWidget(_wrap(const _FriendsSearchHarness()));
      await tester.pump();
      final addBtn = find.byKey(const Key('addFriend_zoeUser'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pump();
      // IconButton disabled after request sent (icon changes to check, still same key)
      expect(addBtn, findsOneWidget);
    });

    testWidgets('search filter hides non matching friend', (tester) async {
      await tester.pumpWidget(_wrap(const _FriendsSearchHarness()));
      await tester.pump();
      expect(find.byKey(const Key('friend_tile_friend1')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('friendsSearchField')), 'zzz');
      await tester.pump();
      expect(find.byKey(const Key('friend_tile_friend1')), findsNothing);
    });
  });
}
