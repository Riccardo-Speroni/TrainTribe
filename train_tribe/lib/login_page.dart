import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main.dart';
import 'l10n/app_localizations.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context); 
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo
              Image.asset(
                'images/djungelskog.jpg',
                height: 100,
              ),

              const SizedBox(height: 60),

              // Username Field
              TextField(
                decoration: InputDecoration(
                  labelText: localizations.translate('username'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              
              const SizedBox(height: 20),

              // Password Field
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                onPressed: () {
                  // Simulate successful login
                  isLoggedIn.value = true;
                  print("User logged in"); // Debug log
                  GoRouter.of(context).go('/root');
                  // TODO: Handle login logic
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Full width
                ),
                child: Text(localizations.translate('login')),
              ),
              const SizedBox(height: 40),

              // Login with Google
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Handle Google login
                },
                icon: const Icon(Icons.login),
                label: Text(localizations.translate('login_google')),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Login with Facebook
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Handle Facebook login
                },
                icon: const Icon(Icons.facebook),
                label: Text(localizations.translate('login_facebook')),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 60),

              // Signup Redirection
              GestureDetector(
                onTap: () {
                  GoRouter.of(context).go('/signup'); // Navigate to Signup Page
                },
                child: Text(
                  localizations.translate('dont_have_account'),
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
