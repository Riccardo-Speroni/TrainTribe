import 'package:flutter/material.dart';

/// Reusable bottom navigation bar widget.
class AppBottomNavBar extends StatelessWidget {
  final List<String> titles;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavBar({
    super.key,
    required this.titles,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: [
        for (int i = 0; i < titles.length; i++)
          NavigationDestination(
            icon: Icon([
              Icons.home,
              Icons.people,
              Icons.train,
              Icons.calendar_today,
              Icons.person,
            ][i]),
            label: titles[i],
          ),
      ],
      onDestinationSelected: onDestinationSelected,
      selectedIndex: currentIndex,
    );
  }
}
