import 'package:flutter/material.dart';
import 'settings_page.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ),
          const Spacer(flex: 1),
          CircleAvatar(
            radius: 50,
            backgroundImage: const AssetImage('images/djungelskog.jpg'),
            child: Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  // Add functionality to change the avatar
                },
              ),
            ),
          ),
          const Text('UserName'),
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Name Surname'),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Email'),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: const Text('Verify'),
              ),
            ],
          ),
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Phone number'),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: const Text('Verify'),
              ),
            ],
          ),
          const Spacer(flex: 4),

        ],
      ),
    );
  }
}

