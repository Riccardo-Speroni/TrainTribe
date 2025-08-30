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

    // Imposta la larghezza massima su desktop/web
    final bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    final double maxFormWidth = isWideScreen ? 400.0 : double.infinity;

    return Stack(
      children: [
        Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: isWideScreen
                  ? Card(
                      elevation: 2,
                      shadowColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32.0, horizontal: 32.0),
                        child: IntrinsicWidth(
                          child: IntrinsicHeight(
                            child: _LoginForm(
                              localizations: localizations,
                              emailController: emailController,
                              passwordController: passwordController,
                              showEmailError: showEmailError,
                              isButtonEnabled: isButtonEnabled,
                              opacityAnimation: _opacityAnimation,
                              loginWithEmailAndPassword: _loginWithEmailAndPassword,
                              loginWithGoogle: _loginWithGoogle,
                              loginWithFacebook: _loginWithFacebook,
                              isWideScreen: isWideScreen,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SafeArea(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxFormWidth,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: _LoginForm(
                                localizations: localizations,
                                emailController: emailController,
                                passwordController: passwordController,
                                showEmailError: showEmailError,
                                isButtonEnabled: isButtonEnabled,
                                opacityAnimation: _opacityAnimation,
                                loginWithEmailAndPassword: _loginWithEmailAndPassword,
                                loginWithGoogle: _loginWithGoogle,
                                loginWithFacebook: _loginWithFacebook,
                                isWideScreen: isWideScreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (_isLoading) const LoadingIndicator(), // Show loading indicator
      ],
    );
  }
}

// Estrae il form in un widget separato per riutilizzo
class _LoginForm extends StatelessWidget {
  final AppLocalizations localizations;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showEmailError;
  final bool isButtonEnabled;
  final Animation<double> opacityAnimation;
  final VoidCallback loginWithEmailAndPassword;
  final Future<void> Function() loginWithGoogle;
  final Future<void> Function() loginWithFacebook;
  final bool isWideScreen;

  const _LoginForm({
    required this.localizations,
    required this.emailController,
    required this.passwordController,
    required this.showEmailError,
    required this.isButtonEnabled,
    required this.opacityAnimation,
    required this.loginWithEmailAndPassword,
    required this.loginWithGoogle,
    required this.loginWithFacebook,
    required this.isWideScreen,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = this.isWideScreen;
    final Color? cardTextColor = isWideScreen
        ? Theme.of(context).colorScheme.onPrimary
        : null;

    final double maxFormWidth = isWideScreen ? 400.0 : double.infinity;

    final Color inputTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxFormWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/logo.png',
              height: 100,
            ),
            const SizedBox(height: 40),

            // Username Field
            SizedBox(
              width: isWideScreen ? 320 : double.infinity,
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    // ignore: invalid_use_of_protected_member
                    (context as Element).markNeedsBuild();
                  }
                },
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('email'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    errorText: showEmailError
                        ? localizations.translate('invalid_email')
                        : null,
                    isDense: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  style: TextStyle(color: inputTextColor),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Password Field
            SizedBox(
              width: isWideScreen ? 320 : double.infinity,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                ),
                onSubmitted: (_) {
                  if (isButtonEnabled) {
                    loginWithEmailAndPassword();
                  }
                },
                style: TextStyle(color: inputTextColor),
              ),
            ),
            const SizedBox(height: 20),

            // Login Button
            AnimatedBuilder(
              animation: opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: opacityAnimation.value,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled
                        ? loginWithEmailAndPassword
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 50), // Full width
                      backgroundColor:
                          isWideScreen
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary,
                      foregroundColor: isWideScreen
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimary,
                      elevation: isButtonEnabled ? 4 : 0,
                    ),
                    child: Text(
                      localizations.translate('login'),
                      style: cardTextColor != null
                            ? TextStyle(color: Colors.white)
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40), // ridotto da 60

            // Other login options (Google, Facebook) available only for mobile
            if (!isWideScreen) ...[
              ElevatedButton.icon(
                onPressed: loginWithGoogle,
                icon: const Icon(Icons.login),
                label: Text(localizations.translate('login_google')),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: loginWithFacebook,
                icon: const Icon(Icons.facebook),
                label: Text(localizations.translate('login_facebook')),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
            ],

            // Signup Redirection
            GestureDetector(
              onTap: () {
                GoRouter.of(context)
                    .go('/signup'); // Navigate to Signup Page
              },
              child: Text(
                localizations.translate('dont_have_account'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
