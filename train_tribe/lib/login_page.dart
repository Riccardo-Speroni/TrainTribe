import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              
              const SizedBox(height: 20),

              // Password Field
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
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
                child: const Text("Login"),
              ),
              const SizedBox(height: 40),

              // Login with Google
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Handle Google login
                },
                icon: const Icon(Icons.login),
                label: const Text("Login with Google"),
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
                label: const Text("Login with Facebook"),
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
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
