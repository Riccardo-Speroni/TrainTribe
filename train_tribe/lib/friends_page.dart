import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'dart:io' show Platform;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'utils/phone_number_helper.dart';

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
  Stream<DocumentSnapshot<Map<String, dynamic>>> get _userDocStream => _db.collection('users').doc(_uid).snapshots();

  // Search results for new users
  List<Map<String, dynamic>> _usersToAdd = [];
  bool _searching = false;
  // Suggested users from contacts (mobile only)
  List<Map<String, dynamic>> _contactSuggestions = [];
  bool _loadingContacts = false;
  bool _contactsRequested = false;
  // Phone(E.164) -> Contact Display Name (from device)
  final Map<String, String> _contactNameByE164 = {};

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

    // Crea una notifica per il destinatario
    final myUsername = myData.data()?['username'] ?? 'Unknown';
    await _db.collection('notifications').add({
      'userId': targetUid,
      'title': 'Nuova richiesta di amicizia',
      'description': '$myUsername ti ha inviato una richiesta di amicizia.',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _acceptFriendRequest(String requesterUid) async {
    final myData = await _db.collection('users').doc(_uid).get();
    final targetData = await _db.collection('users').doc(requesterUid).get();
    if (!targetData.exists) return;

    // Remove from requests
    await _db.collection('users').doc(_uid).update({
      'receivedRequests': FieldValue.arrayRemove([requesterUid]),
      'friends.$requesterUid': {'ghosted': false}
    });
    await _db.collection('users').doc(requesterUid).update({
      'sentRequests': FieldValue.arrayRemove([_uid]),
      'friends.$_uid': {'ghosted': false}
    });

    // Crea una notifica per il destinatario
    final myUsername = myData.data()?['username'] ?? 'Unknown';
    await _db.collection('notifications').add({
      'userId': requesterUid,
      'title': 'Nuovo Amico',
      'description': '$myUsername ha accettato la tua richiesta di amicizia.',
      'timestamp': FieldValue.serverTimestamp(),
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
    await _db.collection('users').doc(_uid).update({'friends.$friendUid.ghosted': !currentGhosted});
  }

  Future<void> _deleteFriend(String friendUid) async {
    await _db.collection('users').doc(_uid).update({'friends.$friendUid': FieldValue.delete()});
    await _db.collection('users').doc(friendUid).update({'friends.$_uid': FieldValue.delete()});
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

  Future<void> _findFriendsFromContacts() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    // Require user to have a phone in DB first; otherwise notify and return.
    final myDocPre = await _db.collection('users').doc(_uid).get();
    final myPhone = (myDocPre.data()?['phone'] ?? '').toString();
    if (myPhone.isEmpty) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.translate('phone_required_for_suggestions'))),
      );
      return;
    }
    setState(() {
      _loadingContacts = true;
      _contactSuggestions = [];
      _contactsRequested = true;
      _contactNameByE164.clear();
    });
    final localizations = AppLocalizations.of(context);
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('contacts_permission_denied'))),
        );
        setState(() => _loadingContacts = false);
        return;
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final numbers = <String>{};
      for (final c in contacts) {
        for (final p in c.phones) {
          final e164 = normalizeRawToE164(p.number, defaultPrefix: kItalyPrefix);
          if (e164 != null) {
            numbers.add(e164);
            // Save first seen display name for this number
            _contactNameByE164.putIfAbsent(e164, () => c.displayName);
          }
        }
      }
      if (numbers.isEmpty) {
        setState(() => _loadingContacts = false);
        return;
      }

      // Fetch my doc to filter out existing relationships
      final myDoc = await _db.collection('users').doc(_uid).get();
      final myFriends = (myDoc.data()?['friends'] ?? {}).keys.toSet();
      final sentReqs = Set<String>.from(myDoc.data()?['sentRequests'] ?? []);
      final receivedReqs = Set<String>.from(myDoc.data()?['receivedRequests'] ?? []);

      // Chunked Firestore queries (whereIn limit conservative 10)
      final all = numbers.toList();
      const chunk = 10;
      final List<Map<String, dynamic>> matches = [];
      for (var i = 0; i < all.length; i += chunk) {
        final slice = all.sublist(i, (i + chunk).clamp(0, all.length));
        final snap = await _db.collection('users').where('phone', whereIn: slice).limit(30).get();
        for (final doc in snap.docs) {
          if (doc.id == _uid) continue;
          if (myFriends.contains(doc.id)) continue;
          if (sentReqs.contains(doc.id)) continue;
          if (receivedReqs.contains(doc.id)) continue;
          final data = doc.data();
          final phone = (data['phone'] ?? '').toString();
          final contactName = _contactNameByE164[phone];
          matches.add({'uid': doc.id, 'contactName': contactName, ...data});
        }
      }

      // Deduplicate by uid
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in matches) {
        final uid = (m['uid'] ?? '') as String;
        if (uid.isEmpty || seen.contains(uid)) continue;
        seen.add(uid);
        unique.add(m);
      }
      setState(() {
        _contactSuggestions = unique;
        _loadingContacts = false;
      });
    } catch (e) {
      setState(() => _loadingContacts = false);
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
                  const SizedBox(height: 16),
                  if (Platform.isAndroid || Platform.isIOS)
                    _SuggestionsSection(
                      title: localizations.translate('find_from_contacts'),
                      subtitle: _contactSuggestions.isNotEmpty ? localizations.translate('suggested_from_contacts') : null,
                      loading: _loadingContacts,
                      contactsRequested: _contactsRequested,
                      suggestions: _contactSuggestions,
                      onRefresh: _findFriendsFromContacts,
                      onAdd: (uid) async {
                        await _sendFriendRequest(uid);
                        // remove from UI after sending
                        setState(() {
                          _contactSuggestions.removeWhere((e) => e['uid'] == uid);
                        });
                      },
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                    // Only render a friend if it matches the search query
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final friendData = entry.value as Map<String, dynamic>;
                    final isGhosted = friendData['ghosted'] == true;
                    final user = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final username = (user['username'] ?? 'Unknown').toString();
                    final hasPhone = (user['phone'] ?? '').toString().isNotEmpty;

                    final query = searchController.text.trim().toLowerCase();
                    final matches = query.isEmpty || username.toLowerCase().startsWith(query);
                    if (!matches) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundImage: AssetImage('images/djungelskog.jpg'),
                        ),
                        title: Text(username),
                        trailing: IconButton(
                          icon: Icon(
                            isGhosted ? Icons.visibility_off : Icons.visibility,
                            color: isGhosted ? Colors.redAccent : Colors.green,
                          ),
                          tooltip: isGhosted ? localizations.translate('unghost') : localizations.translate('ghost'),
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
          text: isGhosted ? localizations.translate('unghost') : localizations.translate('ghost'),
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

class _SuggestionsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool loading;
  final bool contactsRequested;
  final List<Map<String, dynamic>> suggestions;
  final VoidCallback onRefresh;
  final void Function(String uid) onAdd;

  const _SuggestionsSection({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.contactsRequested,
    required this.suggestions,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.contacts,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleMedium),
                          if (subtitle != null && suggestions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(loading ? 'Scanning' : 'Scan'),
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading && suggestions.isEmpty)
            Column(
              children: List.generate(3, (i) => i).map((_) => _loadingTile(context)).toList(),
            )
          else if (suggestions.isNotEmpty)
            Column(
              children: [
                ...suggestions.map((user) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _SuggestionCard(
                        username: (user['username'] ?? '').toString(),
                        contactName: (user['contactName'] ?? '').toString().isNotEmpty ? (user['contactName'] ?? '').toString() : null,
                        onAdd: () => onAdd((user['uid'] ?? '').toString()),
                      ),
                    )),
              ],
            )
          else if (!loading && contactsRequested)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.translate('no_contact_suggestions'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _loadingTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            _skeletonCircle(36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBar(width: 120, height: 12),
                  const SizedBox(height: 8),
                  _skeletonBar(width: 180, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _skeletonCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );

  Widget _skeletonBar({required double width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
}

class _SuggestionCard extends StatelessWidget {
  final String username;
  final String? contactName;
  final VoidCallback onAdd;

  const _SuggestionCard({
    required this.username,
    required this.contactName,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const CircleAvatar(
          backgroundImage: AssetImage('images/djungelskog.jpg'),
          radius: 20,
        ),
        title: Text(
          username,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: contactName != null
            ? Row(
                children: [
                  const Icon(Icons.contact_page, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      contactName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : null,
        trailing: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
        ),
      ),
    );
  }
}
