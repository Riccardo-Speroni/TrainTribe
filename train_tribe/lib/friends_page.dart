import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'widgets/responsive_card_list.dart';
import 'widgets/friend_card.dart';
import 'dart:io' show Platform;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get current user ID
  String get _uid => _auth.currentUser?.uid ?? '';

  // Streams for friends, requests, and sent requests
  Stream<DocumentSnapshot<Map<String, dynamic>>> get _userDocStream =>
      _db.collection('users').doc(_uid).snapshots();

  // Search results for new users
  List<Map<String, dynamic>> _usersToAdd = [];
  bool _searching = false;

  // Add the missing search controller
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Firestore logic ---

  Future<void> _sendFriendRequest(String targetUid) async {
    final myData = await _db.collection('users').doc(_uid).get();
    final targetData = await _db.collection('users').doc(targetUid).get();
    if (!targetData.exists) return;

    // Add to my sent requests
    await _db.collection('users').doc(_uid).update({
      'sentRequests': FieldValue.arrayUnion([targetUid])
    });
    // Add to target's received requests
    await _db.collection('users').doc(targetUid).update({
      'receivedRequests': FieldValue.arrayUnion([_uid])
    });
  }

  Future<void> _acceptFriendRequest(String requesterUid) async {
    // Remove from requests
    await _db.collection('users').doc(_uid).update({
      'receivedRequests': FieldValue.arrayRemove([requesterUid]),
      'friends.$requesterUid': {'ghosted': false}
    });
    await _db.collection('users').doc(requesterUid).update({
      'sentRequests': FieldValue.arrayRemove([_uid]),
      'friends.${_uid}': {'ghosted': false}
    });
  }

  Future<void> _declineFriendRequest(String requesterUid) async {
    await _db.collection('users').doc(_uid).update({
      'receivedRequests': FieldValue.arrayRemove([requesterUid])
    });
    await _db.collection('users').doc(requesterUid).update({
      'sentRequests': FieldValue.arrayRemove([_uid])
    });
  }

  Future<void> _toggleVisibility(String friendUid, bool currentGhosted) async {
    await _db.collection('users').doc(_uid).update({
      'friends.$friendUid.ghosted': !currentGhosted
    });
  }

  Future<void> _deleteFriend(String friendUid) async {
    await _db.collection('users').doc(_uid).update({
      'friends.$friendUid': FieldValue.delete()
    });
    await _db.collection('users').doc(friendUid).update({
      'friends.${_uid}': FieldValue.delete()
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _searching = true;
      _usersToAdd = [];
    });
    final results = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    final myDoc = await _db.collection('users').doc(_uid).get();
    final myFriends = (myDoc.data()?['friends'] ?? {}).keys.toSet();
    final receivedReqs = Set<String>.from(myDoc.data()?['receivedRequests'] ?? []);
    setState(() {
      _usersToAdd = results.docs
          .where((doc) =>
              doc.id != _uid &&
              !myFriends.contains(doc.id) &&
              //!sentReqs.contains(doc.id) && // <-- REMOVE this line to allow showing users with sent requests
              !receivedReqs.contains(doc.id))
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
      _searching = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _usersToAdd = <Map<String, dynamic>>[]; // Ensure correct type
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      _searchUsers(query);
    }
  }

  void _showFriendDialog(BuildContext context, String friendUid, String friendName, bool isGhosted, bool hasPhone) {
    showDialog(
      context: context,
      builder: (context) => FriendPopupDialog(
        friend: friendName,
        isGhosted: isGhosted,
        onDelete: () {
          _deleteFriend(friendUid);
          Navigator.pop(context);
        },
        onToggleGhost: () {
          _toggleVisibility(friendUid, isGhosted);
          Navigator.pop(context);
        },
        hasPhone: hasPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final userData = snapshot.data!.data() ?? {};
        final friends = userData['friends'] as Map<String, dynamic>? ?? {};
        final receivedRequests = List<String>.from(userData['receivedRequests'] ?? []);
        final sentRequests = List<String>.from(userData['sentRequests'] ?? []);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.translate('friends')),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (receivedRequests.isNotEmpty)
                    FriendRequestsContainer(
                      friendRequests: receivedRequests,
                      onAccept: _acceptFriendRequest,
                      onDecline: _declineFriendRequest,
                    ),
                  FriendsSearchContainer(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onSearchSubmitted: _onSearchSubmitted,
                    filteredFriends: friends.entries.toList(),
                    usersToAdd: _usersToAdd,
                    sentRequests: sentRequests,
                    onToggleVisibility: (friendUid, isGhosted) => _toggleVisibility(friendUid, isGhosted),
                    onShowFriendDialog: (ctx, friendUid, friendName, isGhosted, hasPhone) =>
                        _showFriendDialog(ctx, friendUid, friendName, isGhosted, hasPhone),
                    onSendFriendRequest: _sendFriendRequest,
                    searching: _searching,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// FriendRequestsContainer: fetch user info for each request
class FriendRequestsContainer extends StatelessWidget {
  final List<String> friendRequests;
  final void Function(String) onAccept;
  final void Function(String) onDecline;

  const FriendRequestsContainer({
    super.key,
    required this.friendRequests,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('friend_requests'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...friendRequests.map((uid) => FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 48);
                  final user = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage('images/djungelskog.jpg'),
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(user['username'] ?? 'Unknown', style: const TextStyle(fontSize: 16)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          tooltip: localizations.translate('decline'),
                          onPressed: () => onDecline(uid),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: localizations.translate('accept'),
                          onPressed: () => onAccept(uid),
                        ),
                      ],
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

// FriendsSearchContainer: update to use Firestore data
class FriendsSearchContainer extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final void Function(String) onSearchSubmitted;
  final List<MapEntry<String, dynamic>> filteredFriends;
  final List<Map<String, dynamic>> usersToAdd;
  final List<String> sentRequests;
  final void Function(String, bool) onToggleVisibility;
  final void Function(BuildContext, String, String, bool, bool) onShowFriendDialog;
  final void Function(String) onSendFriendRequest;
  final bool searching;

  const FriendsSearchContainer({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.filteredFriends,
    required this.usersToAdd,
    required this.sentRequests,
    required this.onToggleVisibility,
    required this.onShowFriendDialog,
    required this.onSendFriendRequest,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar + Helper Row
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: localizations.translate('add_or_search_friends'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: localizations.translate('search_and_add_friends_tooltip'),
                  child: IconButton(
                    icon: const Icon(Icons.person_add_alt_1),
                    onPressed: () => onSearchSubmitted(searchController.text),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: Text(
                localizations.translate('search_and_add_friends_hint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Friends List
          if (filteredFriends.isNotEmpty)
            ...filteredFriends.map((entry) => FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(entry.key).get(),
                  builder: (context, snapshot) {
                    final friendData = entry.value as Map<String, dynamic>;
                    final isGhosted = friendData['ghosted'] == true;
                    final user = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final username = user['username'] ?? 'Unknown';
                    final hasPhone = (user['phone'] ?? '').toString().isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage('images/djungelskog.jpg'),
                        ),
                        title: Text(username),
                        trailing: IconButton(
                          icon: Icon(
                            isGhosted ? Icons.visibility_off : Icons.visibility,
                            color: isGhosted ? Colors.redAccent : Colors.green,
                          ),
                          tooltip: isGhosted
                              ? localizations.translate('unghost')
                              : localizations.translate('ghost'),
                          onPressed: () => onToggleVisibility(entry.key, isGhosted),
                        ),
                        onTap: () => onShowFriendDialog(context, entry.key, username, isGhosted, hasPhone),
                      ),
                    );
                  },
                )),
          if (filteredFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  localizations.translate('no_friends_found'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          // Separator and users to add
          if (searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (usersToAdd.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      localizations.translate('add_new_friends'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            ...usersToAdd.map((user) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('images/djungelskog.jpg'),
                    ),
                    title: Text(
                      user['username'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: sentRequests.contains(user['uid'])
                        ? const Icon(Icons.check, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            tooltip: localizations.translate('add_friend'),
                            onPressed: () => onSendFriendRequest(user['uid']),
                          ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class FriendPopupDialog extends StatelessWidget {
  final String friend;
  final bool isGhosted;
  final VoidCallback onDelete;
  final VoidCallback onToggleGhost;
  final bool hasPhone;

  const FriendPopupDialog({
    super.key,
    required this.friend,
    required this.isGhosted,
    required this.onDelete,
    required this.onToggleGhost,
    required this.hasPhone,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Always show the three buttons vertically, in the requested order
    List<Widget> buttons = [
      if (hasPhone && (Platform.isAndroid || Platform.isIOS))
        SizedBox(
          height: 44,
          child: CustomTextButton(
            text: 'Whatsapp',
            iconWidget: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 18),
            color: Colors.green,
            onPressed: () {
              // Implement WhatsApp launch logic here
              Navigator.pop(context);
            },
          ),
        ),
      SizedBox(
        height: 44,
        child: CustomTextButton(
          text: isGhosted
              ? localizations.translate('unghost')
              : localizations.translate('ghost'),
          icon: isGhosted ? Icons.visibility : Icons.visibility_off,
          color: isGhosted ? Colors.green : Colors.redAccent,
          onPressed: onToggleGhost,
        ),
      ),
      SizedBox(
        height: 44,
        child: CustomTextButton(
          text: localizations.translate('delete'),
          icon: Icons.delete,
          color: Colors.redAccent,
          onPressed: onDelete,
        ),
      ),
    ];

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              friend,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('images/djungelskog.jpg'),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...buttons.expand((btn) => [btn, const SizedBox(height: 8)]).toList()..removeLast(),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? iconWidget;
  final Color color;
  final VoidCallback onPressed;

  const CustomTextButton({
    super.key,
    required this.text,
    this.icon,
    this.iconWidget,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      icon: iconWidget ?? (icon != null ? Icon(icon, color: Colors.white, size: 18) : const SizedBox.shrink()),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
