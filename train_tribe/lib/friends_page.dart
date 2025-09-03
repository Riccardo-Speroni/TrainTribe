import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'utils/phone_number_helper.dart';
import 'widgets/legend_dialog.dart';
import 'widgets/friends_widget/friend_requests_container.dart';
import 'widgets/friends_widget/friends_search_container.dart';
import 'widgets/friends_widget/friend_popup_dialog.dart';
import 'widgets/friends_widget/suggestions_section.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageState extends State<FriendsPage> {
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
  final localizations = AppLocalizations.of(context); // capture early if needed later
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

    // Create a Notification for the receiver
    final myUsername = myData.data()?['username'] ?? 'Unknown';
    await _db.collection('notifications').add({
      'userId': targetUid,
      'title': localizations.translate('new_friend_request'),
      'description': '$myUsername ${localizations.translate('new_friend_request_body')}',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _acceptFriendRequest(String requesterUid) async {
  final localizations = AppLocalizations.of(context);
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

    // Create a Notification for the requester
    final myUsername = myData.data()?['username'] ?? 'Unknown';
    await _db.collection('notifications').add({
      'userId': requesterUid,
      'title': localizations.translate('new_friend'),
      'description': '$myUsername ${localizations.translate('request_accepted')}',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() {
      _usersToAdd.removeWhere((u) => u['uid'] == requesterUid);
      _contactSuggestions.removeWhere((u) => u['uid'] == requesterUid);
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
    if (!mounted) return;
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
    if (!mounted) return;
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
  final localizations = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context); // capture before awaits
  final myDocPre = await _db.collection('users').doc(_uid).get();
    final myPhone = (myDocPre.data()?['phone'] ?? '').toString();
    if (myPhone.isEmpty) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(localizations.translate('phone_required_for_suggestions'))),
        );
      }
      return;
    }
    setState(() {
      _loadingContacts = true;
      _contactSuggestions = [];
      _contactsRequested = true;
      _contactNameByE164.clear();
    });
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(localizations.translate('contacts_permission_denied'))),
          );
          setState(() => _loadingContacts = false);
        }
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
    if (mounted) setState(() => _loadingContacts = false);
        return;
      }

      // Fetch my doc to filter out existing relationships
      final myDoc = await _db.collection('users').doc(_uid).get();
      final myFriends = (myDoc.data()?['friends'] ?? {}).keys.toSet();
      // sent/received requests not needed in suggestions filtering here

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
      if (mounted) {
        setState(() {
          _contactSuggestions = unique;
          _loadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  // Modifica: recupera anche la foto profilo dell'amico e passala al dialog
  void _showFriendDialog(BuildContext context, String friendUid, String friendName, bool isGhosted, bool hasPhone) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(friendUid).get();
    final picture = (doc.data()?['picture'] ?? '').toString();
    // Retrieve first name and surname so we can render two initials consistently
    final firstName = (doc.data()?['name'] ?? '').toString();
    final lastName = (doc.data()?['surname'] ?? '').toString();
    final phone = (doc.data()?['phone'] ?? '').toString();
    if (!mounted) return;
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
        picture: picture, // passa la foto profilo
        firstName: firstName,
        lastName: lastName,
        phone: phone,
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

        // Filtra gli utenti che sono già amici dalla ricerca e dai suggerimenti contatti
        final friendUids = friends.keys.toSet();
        final filteredUsersToAdd = _usersToAdd.where((u) => !friendUids.contains(u['uid'])).toList();
        final filteredContactSuggestions = _contactSuggestions.where((u) => !friendUids.contains(u['uid'])).toList();

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(localizations.translate('friends')),
            actions: [
              IconButton(
                tooltip: localizations.translate('friends_ghost_legend_title'),
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showLegendDialog(
                    context: context,
                    title: localizations.translate('friends_ghost_legend_title'),
                    okLabel: localizations.translate('ok'),
                    infoText: localizations.translate('friends_ghost_legend_info'),
                    items: [
                      LegendItem(
                        ringColor: Theme.of(context).colorScheme.primary,
                        glowColor: Colors.transparent,
                        label: localizations.translate('friends_ghost_legend_visible'),
                        icon: Icons.visibility,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      LegendItem(
                        ringColor: Colors.redAccent,
                        glowColor: Colors.transparent,
                        label: localizations.translate('friends_ghost_legend_ghosted'),
                        icon: Icons.visibility_off,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ],
                  );
                },
              ),
            ],
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
                    usersToAdd: filteredUsersToAdd,
                    sentRequests: sentRequests,
                    onToggleVisibility: (friendUid, isGhosted) => _toggleVisibility(friendUid, isGhosted),
                    onShowFriendDialog: (ctx, friendUid, friendName, isGhosted, hasPhone) =>
                        _showFriendDialog(ctx, friendUid, friendName, isGhosted, hasPhone),
                    onSendFriendRequest: _sendFriendRequest,
                    searching: _searching,
                  ),
                  const SizedBox(height: 16),
                  if (Platform.isAndroid || Platform.isIOS)
                    SuggestionsSection(
                      title: localizations.translate('find_from_contacts'),
                      subtitle: filteredContactSuggestions.isNotEmpty ? localizations.translate('suggested_from_contacts') : null,
                      loading: _loadingContacts,
                      contactsRequested: _contactsRequested,
                      suggestions: filteredContactSuggestions,
                      sentRequests: sentRequests,
                      onRefresh: _findFriendsFromContacts,
                      onAdd: (uid) async {
                        await _sendFriendRequest(uid);
                        setState(() {});
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