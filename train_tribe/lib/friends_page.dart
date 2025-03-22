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
      if (lowerQuery.isNotEmpty) {
        _filteredFriends = _allFriends
            .where((friend) => friend.toLowerCase().contains(lowerQuery))
            .toList();
      } else {
        _filteredFriends = List.from(_allFriends);
      }
    });
  }

  void _toggleVisibility(String friend) {
    setState(() {
      _visibilityMap[friend] = !_visibilityMap[friend]!;
    });
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
                  return Card(
                    child: ListTile(
                      leading: Image.asset(
                        'images/djungelskog.jpg',
                        height: 40,
                        width: 40,
                      ),
                      title: Text(friend),
                      trailing: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _toggleVisibility(friend),
                        icon: Icon(
                          _visibilityMap[friend]! 
                              ? MdiIcons.eye 
                              : MdiIcons.ghost, 
                          color: Colors.blue,
                        ),
                        label: const Text(""),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(friend),
                              insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 20),
                              content: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 300,
                                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'images/djungelskog.jpg',
                                      height: 150,
                                      width: 150,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                              actions: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        label: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.visibility_off, color: Colors.white),
                                        label: const Text('Ghost', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.chat, color: Colors.white),
                                        label: const Text('Whatsapp', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              )
            : const Center(child: Text('No friends found')),
      ),
    );
  }
}
