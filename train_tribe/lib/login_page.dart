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
import 'widgets/logo_pattern_background.dart';
import 'utils/auth_adapter.dart';

class LoginPage extends StatefulWidget {
  final AuthAdapter? authAdapter; // for testing injection
  const LoginPage({super.key, this.authAdapter});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isButtonEnabled = false;
  bool showEmailError = false;
  bool _isLoading = false; // State to control loading indicator

  // Background pattern moved to reusable widget

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  // Test-only: force layout branch
  @visibleForTesting
  bool? debugForceWideScreen;
  @visibleForTesting
  void setForceWideScreenForTest(bool? v) => setState(() => debugForceWideScreen = v);

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

    // Particles generated inside LayoutBuilder for actual size (to avoid overlaps)
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  void _updateButtonState() {
    final shouldEnable =
        emailController.text.trim().isNotEmpty && passwordController.text.trim().isNotEmpty && _isValidEmail(emailController.text.trim());

    if (shouldEnable != isButtonEnabled) {
      setState(() {
        isButtonEnabled = shouldEnable;
        if (isButtonEnabled) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
        // Ensure any delayed test-driven changes trigger another frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
  });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false); // Hide loading indicator
        return; // User canceled the login
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!mounted) return; // ensure context still valid
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
      if (mounted) {
        _showErrorDialog(AppLocalizations.of(context).translate('login_error_generic'));
      }
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  Future<void> _loginWithFacebook() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success || result.accessToken == null) {
        if (mounted) setState(() => _isLoading = false); // Hide loading indicator
        return; // Login failed or accessToken is null
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!mounted) return;
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
      if (mounted) {
        _showErrorDialog(AppLocalizations.of(context).translate('login_error_generic'));
      }
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  Future<void> _loginWithEmailAndPassword() async {
    if (mounted) setState(() => _isLoading = true); // Show loading indicator
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final adapter = widget.authAdapter ?? FirebaseAuthAdapter();
      await adapter.signInWithEmailAndPassword(email: email, password: password);
  // Obtain router only after successful sign-in so tests without a GoRouter ancestor don't fail early.
  final router = GoRouter.of(context);
      if (mounted) router.go('/root');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errorMessage = FirebaseExceptionHandler.logInErrorMessage(context, e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      if (mounted) {
        _showErrorDialog(AppLocalizations.of(context).translate('login_error_generic'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // Hide loading indicator
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
    // Recompute enable state defensively (in addition to listener) to avoid race conditions in tests.
    final computedEnable =
        _isValidEmail(emailController.text.trim()) && emailController.text.trim().isNotEmpty && passwordController.text.trim().isNotEmpty;
    if (computedEnable != isButtonEnabled) {
      // Keep internal state in sync so animation reflects correct opacity.
      isButtonEnabled = computedEnable;
    }

    // Imposta la larghezza massima su desktop/web
    bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    if (debugForceWideScreen != null) {
      isWideScreen = debugForceWideScreen!;
    }
    final double maxFormWidth = isWideScreen ? 400.0 : double.infinity;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final contentStack = Stack(
      children: [
        Scaffold(
          key: const Key('login_page'),
          backgroundColor: isWideScreen
              ? Colors.transparent // pattern shows on desktop/web
              : (isDark ? Colors.black : Colors.white),
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
                      child: SizedBox(
                        width: 500,
                        height: 560,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 32.0),
                          child: SingleChildScrollView(
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
        if (_isLoading) const LoadingIndicator(),
      ],
    );

    // Apply pattern background only on desktop/web (non mobile)
    if (isWideScreen) {
      return LogoPatternBackground(child: contentStack);
    }
    return contentStack;
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
    final Color? cardTextColor = isWideScreen ? Theme.of(context).colorScheme.onPrimary : null;

    final double maxFormWidth = isWideScreen ? 400.0 : double.infinity;

    final Color inputTextColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    // Desktop/web layout unchanged (scrollable single column)
    if (isWideScreen) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxFormWidth),
          child: _buildFormContent(context, localizations, inputTextColor, cardTextColor, includeSocial: false, includeSignupLink: true),
        ),
      );
    }

    // Mobile: pin signup link at bottom.
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxFormWidth),
              child:
                  _buildFormContent(context, localizations, inputTextColor, cardTextColor, includeSocial: true, includeSignupLink: false),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: GestureDetector(
            onTap: () => GoRouter.of(context).go('/signup'),
            child: Text(
              localizations.translate('dont_have_account'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(
    BuildContext ctx,
    AppLocalizations localizations,
    Color inputTextColor,
    Color? cardTextColor, {
    required bool includeSocial,
    required bool includeSignupLink,
  }) {
    final bool isWideScreen = this.isWideScreen;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('images/logo.png', height: 100),
        const SizedBox(height: 40),
        SizedBox(
          width: isWideScreen ? 320 : double.infinity,
          child: Focus(
            child: TextField(
              controller: emailController,
              key: const Key('emailField'),
              decoration: InputDecoration(
                labelText: localizations.translate('email'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                errorText: showEmailError ? localizations.translate('invalid_email') : null,
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              style: TextStyle(color: inputTextColor),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: isWideScreen ? 320 : double.infinity,
          child: TextField(
            controller: passwordController,
            obscureText: true,
            key: const Key('passwordField'),
            decoration: InputDecoration(
              labelText: localizations.translate('password'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              isDense: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
            onSubmitted: (_) {
              if (isButtonEnabled) loginWithEmailAndPassword();
            },
            style: TextStyle(color: inputTextColor),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: opacityAnimation,
          builder: (context, child) => Opacity(
            opacity: opacityAnimation.value,
            child: SizedBox(
              width: isWideScreen ? 320 : double.infinity,
              child: ElevatedButton(
                key: const Key('loginButton'),
                onPressed: isButtonEnabled ? loginWithEmailAndPassword : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(ctx).colorScheme.primary,
                  elevation: isButtonEnabled ? 4 : 0,
                ),
                child: Text(
                  localizations.translate('login'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (includeSocial) ...[
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
          const SizedBox(height: 20),
        ],
        if (includeSignupLink)
          GestureDetector(
            onTap: () => GoRouter.of(ctx).go('/signup'),
            child: Text(
              localizations.translate('dont_have_account'),
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
