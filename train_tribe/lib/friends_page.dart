import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'widgets/responsive_card_list.dart';
import 'widgets/friend_card.dart';
import 'dart:io' show Platform;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final List<String> _allFriends = [
    'Alice',
    'Bob',
    'Charlie',
    'David',
    'Djungo',
    'Eve',
    'Federico',
    'Giulia'
  ];

  // Mock friend requests and users to add
  final List<String> _friendRequests = ['Marco', 'Elena'];
  List<String> _filteredFriends = [];
  final Map<String, bool> _isGhostedMap = {};
  List<String> _usersToAdd = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _friendRequestSent = {};

  @override
  void initState() {
    super.initState();
    _filteredFriends = List.from(_allFriends);
    for (var friend in _allFriends) {
      _isGhostedMap[friend] = false;
    }
    for (var user in ['Luca', 'Martina', 'Simone']) {
      _friendRequestSent[user] = false;
    }
  }

  void _filterFriends(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _filteredFriends = _allFriends
            .where(
                (friend) => friend.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _filteredFriends = List.from(_allFriends);
        _usersToAdd = [];
      }
    });
  }

  void _onSearchSubmitted(String query) {
    // Simulate loading users to add (not in friends)
    final allPossibleUsers = ['Luca', 'Martina', 'Simone', 'Alice', 'Bob'];
    setState(() {
      _usersToAdd = allPossibleUsers
          .where((user) =>
              !_allFriends.contains(user) &&
              user.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleVisibility(String friend) {
    setState(() {
      _isGhostedMap[friend] = !_isGhostedMap[friend]!;
    });
  }

  void _acceptFriendRequest(String user) {
    setState(() {
      _allFriends.add(user);
      _filteredFriends.add(user);
      _isGhostedMap[user] = false;
      _friendRequests.remove(user);
    });
  }

  void _declineFriendRequest(String user) {
    setState(() {
      _friendRequests.remove(user);
    });
  }

  void _sendFriendRequest(String user) {
    setState(() {
      _friendRequestSent[user] = true;
    });
  }

  void _showFriendDialog(BuildContext context, String friend) {
    showDialog(
      context: context,
      builder: (context) => FriendPopupDialog(
        friend: friend,
        isGhosted: _isGhostedMap[friend] ?? false,
        onDelete: () {
          setState(() {
            _allFriends.remove(friend);
            _filteredFriends.remove(friend);
            _isGhostedMap.remove(friend);
          });
          Navigator.pop(context);
        },
        onToggleGhost: () {
          _toggleVisibility(friend);
          Navigator.pop(context);
        },
        hasPhone: friend == 'Alice' || friend == 'Bob',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
              // Friend Requests Section
              if (_friendRequests.isNotEmpty)
                FriendRequestsContainer(
                  friendRequests: _friendRequests,
                  onAccept: _acceptFriendRequest,
                  onDecline: _declineFriendRequest,
                ),
              // Friends List Section
              FriendsSearchContainer(
                searchController: _searchController,
                onSearchChanged: _filterFriends,
                onSearchSubmitted: _onSearchSubmitted,
                filteredFriends: _filteredFriends,
                usersToAdd: _usersToAdd,
                isGhostedMap: _isGhostedMap,
                friendRequestSent: _friendRequestSent,
                onToggleVisibility: _toggleVisibility,
                onShowFriendDialog: _showFriendDialog,
                onSendFriendRequest: _sendFriendRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          ...friendRequests.map((user) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('images/djungelskog.jpg'),
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(user, style: const TextStyle(fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      tooltip: localizations.translate('decline'),
                      onPressed: () => onDecline(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: localizations.translate('accept'),
                      onPressed: () => onAccept(user),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class FriendsSearchContainer extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final void Function(String) onSearchSubmitted;
  final List<String> filteredFriends;
  final List<String> usersToAdd;
  final Map<String, bool> isGhostedMap;
  final Map<String, bool> friendRequestSent;
  final void Function(String) onToggleVisibility;
  final void Function(BuildContext, String) onShowFriendDialog;
  final void Function(String) onSendFriendRequest;

  const FriendsSearchContainer({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.filteredFriends,
    required this.usersToAdd,
    required this.isGhostedMap,
    required this.friendRequestSent,
    required this.onToggleVisibility,
    required this.onShowFriendDialog,
    required this.onSendFriendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
            ...filteredFriends.map((friend) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('images/djungelskog.jpg'),
                    ),
                    title: Text(friend),
                    trailing: IconButton(
                      icon: Icon(
                        isGhostedMap[friend] == true
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isGhostedMap[friend] == true
                            ? Colors.redAccent
                            : Colors.green,
                      ),
                      tooltip: isGhostedMap[friend] == true
                          ? localizations.translate('unghost')
                          : localizations.translate('ghost'),
                      onPressed: () => onToggleVisibility(friend),
                    ),
                    onTap: () => onShowFriendDialog(context, friend),
                  ),
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
                      user,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: friendRequestSent[user] == true
                        ? const Icon(Icons.check, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            tooltip: localizations.translate('add_friend'),
                            onPressed: () => onSendFriendRequest(user),
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
