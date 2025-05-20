import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/profile_picture_widget.dart';
import 'utils/loading_indicator.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text(localizations.translate('error_loading_profile')));
        }
        final data = snapshot.data!;
        final username = data['username'] ?? '';
        final name = data['name'] ?? '';
        final surname = data['surname'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phone'];
        final picture = data['picture']; // URL or initials

        return Center(
          child: Column(
            children: [
              const Spacer(flex: 1),
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
              ProfilePicture(
                picture: picture,
                size: 50,
              ),
              Text(username.isNotEmpty ? username : localizations.translate('username')),
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$name $surname'),
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
                  Text(email),
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
                  Text((phone != null && phone.toString().isNotEmpty)
                      ? phone
                      : localizations.translate('phone_number')),
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
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut(); // Sign out from Firebase
                  GoRouter.of(context).go('/login'); // Redirect to login page using GoRouter
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red button for disconnect
                  foregroundColor: Colors.white,
                ),
                child: Text(localizations.translate('logout')), // Localized text for Logout
              ),
              const Spacer(flex: 1),
            ],
          ),
        );
      },
    );
  }
}

