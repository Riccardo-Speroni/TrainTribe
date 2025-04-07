import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'l10n/app_localizations.dart';
import 'widgets/responsive_card_list.dart'; // Importa il widget ResponsiveCardList
import 'widgets/friend_card.dart'; // Importa il widget FriendCard

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

  List<String> _filteredFriends = [];
  final Map<String, bool> _visibilityMap = {};

  @override
  void initState() {
    super.initState();
    _filteredFriends = List.from(_allFriends);
    for (var friend in _allFriends) {
      _visibilityMap[friend] = false;
    }
  }

  void _filterFriends(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredFriends = lowerQuery.isNotEmpty
          ? _allFriends.where((friend) => friend.toLowerCase().contains(lowerQuery)).toList()
          : List.from(_allFriends);
    });
  }

  void _toggleVisibility(String friend) {
    setState(() {
      _visibilityMap[friend] = !_visibilityMap[friend]!;
    });
  }

  void _showFriendDialog(BuildContext context, String friend) {
    final localizations = AppLocalizations.of(context); 
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(friend),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('images/djungelskog.jpg', height: 150, width: 150),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: CustomTextButton(
                    text: localizations.translate('delete'), 
                    icon: Icons.delete,
                    color: Colors.redAccent,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextButton(
                    text: localizations.translate('ghost'), 
                    icon: Icons.visibility_off,
                    color: Colors.grey,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextButton(
                    text: localizations.translate('whatsapp'), 
                    icon: Icons.chat,
                    color: Colors.green,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Genera le card degli amici
    final friendCards = _filteredFriends.map((friend) {
      return FriendCard(
        friend: friend,
        isVisible: _visibilityMap[friend]!,
        onToggleVisibility: () => _toggleVisibility(friend),
        onTap: () => _showFriendDialog(context, friend),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('friends')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              leading: const Icon(Icons.search),
              hintText: localizations.translate('add_or_search_friends'),
              onChanged: _filterFriends,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _filteredFriends.isNotEmpty
            ? ResponsiveCardList(
                cards: friendCards,
              )
            : const Center(child: Text('No friends found')),
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
