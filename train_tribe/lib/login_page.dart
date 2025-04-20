import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isButtonEnabled = false;
  bool showEmailError = false;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_updateButtonState);
    passwordController.addListener(_updateButtonState);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_animationController);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  void _updateButtonState() {
    final shouldEnable = emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        _isValidEmail(emailController.text.trim());

    if (shouldEnable != isButtonEnabled) {
      setState(() {
        isButtonEnabled = shouldEnable;
        if (isButtonEnabled) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    setState(() {
                      showEmailError = !_isValidEmail(emailController.text.trim());
                    });
                  }
                },
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('username'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    errorText: showEmailError
                        ? localizations.translate('invalid_email')
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: ElevatedButton(
                      onPressed: isButtonEnabled
                          ? () async {
                              try {
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();
                                await FirebaseAuth.instance.signInWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );
                                isLoggedIn.value = true; // Update the login state
                                print("User logged in"); // Debug log
                                GoRouter.of(context).go('/root');
                              } on FirebaseAuthException catch (e) {
                                String errorMessage;
                                if (e.code == 'user-not-found') {
                                  errorMessage = localizations.translate('login_error_user_not_found');
                                } else if (e.code == 'wrong-password') {
                                  errorMessage = localizations.translate('login_error_wrong_password');
                                } else if (e.code == 'network-request-failed') {
                                  errorMessage = localizations.translate('login_error_no_internet');
                                } else {
                                  errorMessage = localizations.translate('login_error_generic');
                                }
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(localizations.translate('login_failed')),
                                    content: Text(errorMessage),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text(localizations.translate('ok')),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(localizations.translate('login_failed')),
                                    content: Text(localizations.translate('login_error_generic')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text(localizations.translate('ok')),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50), // Full width
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: isButtonEnabled ? 4 : 0,
                      ),
                      child: Text(localizations.translate('login')),
                    ),
                  );
                },
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
