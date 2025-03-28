import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'l10n/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
          Text(localizations.translate('username')), 
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(localizations.translate('name_surname')), 
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: Text(localizations.translate('edit')), 
              ),
            ],
          ),
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(localizations.translate('email')), 
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: Text(localizations.translate('edit')), 
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: Text(localizations.translate('verify')), 
              ),
            ],
          ),
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(localizations.translate('phone_number')), 
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: Text(localizations.translate('edit')), 
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Add button functionality here
                },
                child: Text(localizations.translate('verify')), 
              ),
            ],
          ),
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}

