import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';
import 'utils/firebase_exception_handler.dart';
import 'utils/loading_indicator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isButtonEnabled = false;
  bool showEmailError = false;
  bool _isLoading = false; // State to control loading indicator

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
    _opacityAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(_animationController);
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false); // Hide loading indicator
        return; // User canceled the login
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // User exists, proceed to the main app
          if (mounted) GoRouter.of(context).go('/root');
        } else {
          // User does not exist, redirect to onboarding
          if (mounted) {
            GoRouter.of(context).go('/complete_signup', extra: {
              'email': user.email,
              'name': user.displayName,
              'profilePicture': user.photoURL,
            });
          }
        }
      }
    } catch (e) {
      _showErrorDialog(
          AppLocalizations.of(context).translate('login_error_generic'));
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  Future<void> _loginWithFacebook() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success || result.accessToken == null) {
        setState(() => _isLoading = false); // Hide loading indicator
        return; // Login failed or accessToken is null
      }

      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // User exists, proceed to the main app
          if (mounted) GoRouter.of(context).go('/root');
        } else {
          // User does not exist, redirect to onboarding
          if (mounted) {
            GoRouter.of(context).go('/complete_signup', extra: {
              'email': user.email,
              'name': user.displayName,
              'profilePicture': user.photoURL,
            });
          }
        }
      }
    } catch (e) {
      _showErrorDialog(
          AppLocalizations.of(context).translate('login_error_generic'));
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  Future<void> _loginWithEmailAndPassword() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      GoRouter.of(context).go('/root');
    } on FirebaseAuthException catch (e) {
      final errorMessage =
          FirebaseExceptionHandler.logInErrorMessage(context, e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog(
          AppLocalizations.of(context).translate('login_error_generic'));
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('login_failed')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('ok')),
          ),
        ],
      ),
    );
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

    return Stack(
      children: [
        Scaffold(
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
                          showEmailError =
                              !_isValidEmail(emailController.text.trim());
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
                    onSubmitted: (_) {
                      if (isButtonEnabled) {
                        _loginWithEmailAndPassword();
                      }
                    },
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
                              ? _loginWithEmailAndPassword
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(double.infinity, 50), // Full width
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                    onPressed: (kIsWeb || Platform.isAndroid || Platform.isIOS)
                        ? _loginWithGoogle
                        : null, // Disable button on unsupported platforms
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
                    onPressed: (kIsWeb || Platform.isAndroid || Platform.isIOS)
                        ? _loginWithFacebook
                        : null, // Disable button on unsupported platforms
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
                      GoRouter.of(context)
                          .go('/signup'); // Navigate to Signup Page
                    },
                    child: Text(
                      localizations.translate('dont_have_account'),
                      style: const TextStyle(
                          color: Colors.blueGrey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading) const LoadingIndicator(), // Show loading indicator
      ],
    );
  }
}
