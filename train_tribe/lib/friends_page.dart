import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
                    text: 'Delete',
                    icon: Icons.delete,
                    color: Colors.redAccent,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextButton(
                    text: 'Ghost',
                    icon: Icons.visibility_off,
                    color: Colors.grey,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextButton(
                    text: 'Whatsapp',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              leading: const Icon(Icons.search),
              hintText: 'Add or search friends',
              onChanged: _filterFriends,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _filteredFriends.isNotEmpty
            ? ListView.builder(
                itemCount: _filteredFriends.length,
                itemBuilder: (context, index) {
                  String friend = _filteredFriends[index];
                  return FriendCard(
                    friend: friend,
                    isVisible: _visibilityMap[friend]!,
                    onToggleVisibility: () => _toggleVisibility(friend),
                    onTap: () => _showFriendDialog(context, friend),
                  );
                },
              )
            : const Center(child: Text('No friends found')),
      ),
    );
  }
}

class FriendCard extends StatelessWidget {
  final String friend;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onTap;

  const FriendCard({
    super.key,
    required this.friend,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.asset('images/djungelskog.jpg', height: 40, width: 40),
        title: Text(friend),
        trailing: TextButton.icon(
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
          onPressed: onToggleVisibility,
          icon: Icon(isVisible ? MdiIcons.eye : MdiIcons.ghost, color: Colors.blue),
          label: const Text(""),
        ),
        onTap: onTap,
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
