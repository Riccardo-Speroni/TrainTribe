import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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