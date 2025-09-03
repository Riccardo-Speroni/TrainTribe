import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/image_uploader.dart';
import 'l10n/app_localizations.dart';
import 'utils/firebase_exception_handler.dart';
import 'utils/loading_indicator.dart';
import 'widgets/user_details_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/logo_pattern_background.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  File? _profileImage; // Local picked file (resized & uploaded later)
  String? _generatedAvatarUrl; // Chosen generated avatar

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isEmailValid = false;
  bool arePasswordsValid = false;
  bool areMandatoryFieldsFilled = false;
  bool _isLoading = false; // State to control loading indicator
  bool isUsernameUnique = true; // State to track username uniqueness

  // Avatar generation state removed; handled by reusable picker widget

  void _nextPage() {
    final bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    if (_currentPage < 2) {
      if (isWideScreen) {
        setState(() => _currentPage++);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage++);
      }
    }
  }

  void _prevPage() {
    final bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    if (_currentPage > 0) {
      if (isWideScreen) {
        setState(() => _currentPage--);
      } else {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage--);
      }
    }
  }

  // Removed local upload; using ImageUploader.uploadProfileImage

  void _validateEmail() {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    setState(() {
      isEmailValid = emailRegex.hasMatch(emailController.text.trim());
    });
  }

  Future<void> _createUserInFirebase() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final username = usernameController.text.trim();
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();
      final phone = phoneController.text.trim();

      // Final safety check: accept only valid E.164-like strings if provided
      final e164Regex = RegExp(r'^\+[1-9]\d{7,14}$');
      if (phone.isNotEmpty && !e164Regex.hasMatch(phone)) {
        _showErrorDialog(AppLocalizations.of(context).translate('invalid_phone'));
        setState(() => _isLoading = false);
        return;
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? profilePictureUrl;
      if (_profileImage != null) {
        profilePictureUrl = await ImageUploader.uploadProfileImage(file: _profileImage!);
      } else if (_generatedAvatarUrl != null) {
        profilePictureUrl = _generatedAvatarUrl;
      } else {
        final initials = "${firstName[0]}${lastName[0]}".toUpperCase();
        profilePictureUrl = initials;
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': firstName,
        'surname': lastName,
        'username': username,
        'email': email,
        // Store normalized E.164 into the single 'phone' field when available
        'phone': phone.isNotEmpty ? phone : null,
        'picture': profilePictureUrl,
      });

  if (!mounted) return;
  GoRouter.of(context).go('/root');
    } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    final errorMessage =
      FirebaseExceptionHandler.signInErrorMessage(context, e.code);
    _showErrorDialog(errorMessage);
    } catch (e) {
  debugPrint('Error creating user: $e');
  if (mounted) {
    _showErrorDialog(
    AppLocalizations.of(context).translate('unexpected_error'));
  }
    } finally {
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('error')),
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

  // Avatar generation & selection handled by ProfilePicturePicker

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Build main signup content stack (form + loading overlay)
    final Widget contentStack = Stack(
      children: [
        Scaffold(
          backgroundColor: isWideScreen ? Colors.transparent : (isDark ? Colors.black : Colors.white),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: isWideScreen
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Card(
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
                          height: _currentPage < 2 ? 560 : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 32.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_currentPage == 0)
                                    _buildEmailPage(context, localizations)
                                  else if (_currentPage == 1)
                                    _buildPasswordPage(localizations)
                                  else if (_currentPage == 2)
                                    _buildUserDetailsPage(localizations),
                                  if (_currentPage == 0)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          GoRouter.of(context).go('/login');
                                        },
                                        child: Text(
                                          localizations.translate('already_have_account'),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildEmailPage(context, localizations),
                              _buildPasswordPage(localizations),
                              _buildUserDetailsPage(localizations),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
                          child: GestureDetector(
                            onTap: () {
                              GoRouter.of(context).go('/login');
                            },
                            child: Text(
                              localizations.translate('already_have_account'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    // Apply pattern background only on desktop/web (non mobile)
    if (isWideScreen) {
      return LogoPatternBackground(child: contentStack);
    }
    return contentStack;
  }

  Widget _buildEmailPage(BuildContext context, AppLocalizations localizations) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    final bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('images/logo.png', height: 100),
            const SizedBox(height: 20),
            Text(localizations.translate('enter_email'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: TextField(
                controller: emailController,
                onChanged: (_) => _validateEmail(),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: localizations.translate('email'),
                  border: const OutlineInputBorder(),
                  errorText: isEmailValid ? null : localizations.translate('invalid_email'),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 320,
              height: 40,
              child: ElevatedButton(
                key: const Key('signupEmailNextButton'),
                onPressed: isEmailValid ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEmailValid ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                child: Text(localizations.translate('next'), style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
    if (isWideScreen) return Center(child: content);
    return Align(alignment: Alignment.topCenter, child: content);
  }

  Widget _buildPasswordPage(AppLocalizations localizations) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    final bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validate password conditions
    final isMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final passwordsMatch = password == confirmPassword;

    // Update the arePasswordsValid flag
    setState(() {
      arePasswordsValid = isMinLength && hasUppercase && hasLowercase && hasNumber && passwordsMatch;
    });

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _prevPage,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.translate('choose_password'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                key: const Key('signupPasswordField'),
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordCondition(
                    localizations.translate('password_min_length'),
                    isMinLength,
                  ),
                  _buildPasswordCondition(
                    localizations.translate('password_uppercase'),
                    hasUppercase,
                  ),
                  _buildPasswordCondition(
                    localizations.translate('password_lowercase'),
                    hasLowercase,
                  ),
                  _buildPasswordCondition(
                    localizations.translate('password_number'),
                    hasNumber,
                  ),
                  _buildPasswordCondition(
                    localizations.translate('passwords_match'),
                    passwordsMatch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: TextField(
                controller: confirmPasswordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                key: const Key('signupConfirmPasswordField'),
                decoration: InputDecoration(
                  labelText: localizations.translate('confirm_password'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 320,
              height: 40,
              child: ElevatedButton(
                key: const Key('signupPasswordNextButton'),
                onPressed: arePasswordsValid ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: arePasswordsValid ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                child: Text(
                  localizations.translate('next'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (isWideScreen) return Center(child: content);
    return Align(alignment: Alignment.topCenter, child: content);
  }

  Widget _buildPasswordCondition(String text, bool condition) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: condition ? Colors.green : Colors.red,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailsPage(AppLocalizations localizations) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: UserDetailsPage(
          prefilledName: firstNameController.text,
          prefilledSurname: lastNameController.text,
          prefilledUsername: usernameController.text,
          prefilledPhone: phoneController.text,
          onBack: _prevPage,
          onAction: () {
            setState(() {
              firstNameController.text = firstNameController.text.trim();
              lastNameController.text = lastNameController.text.trim();
              usernameController.text = usernameController.text.trim();
              phoneController.text = phoneController.text.trim();
            });
            _createUserInFirebase();
          },
          actionButtonText: localizations.translate('create_account'),
          nameController: firstNameController,
          surnameController: lastNameController,
          usernameController: usernameController,
          phoneController: phoneController,
          onProfileImageSelected: (sel) {
            if (sel.removed) {
              setState(() {
                _profileImage = null;
                _generatedAvatarUrl = null;
              });
            } else if (sel.generatedAvatarUrl != null) {
              setState(() {
                _generatedAvatarUrl = sel.generatedAvatarUrl;
                _profileImage = null;
              });
            } else if (sel.pickedFile != null) {
              setState(() {
                _profileImage = File(sel.pickedFile!.path);
                _generatedAvatarUrl = null;
              });
            }
          },
        ),
      ),
    );
  }
}
