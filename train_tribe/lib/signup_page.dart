import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'l10n/app_localizations.dart';
import 'utils/firebase_exception_handler.dart';
import 'utils/loading_indicator.dart';
import 'widgets/user_details_page.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  File? _profileImage;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isEmailValid = false;
  bool arePasswordsValid = false;
  bool areMandatoryFieldsFilled = false;
  bool _isLoading = false; // State to control loading indicator
  bool isUsernameUnique = true; // State to track username uniqueness

  int _avatarPage = 1; // Tracks the current page of avatars
  List<String> _avatarUrls = []; // Stores the generated avatar URLs
  String? _selectedAvatarUrl; // Memorizza l'URL dell'avatar selezionato

  void _nextPage() {
    final bool isWideScreen =
        kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    if (_currentPage < 3) {
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
    final bool isWideScreen =
        kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    File? tempFile;
    try {
      // Read the image file as bytes
      final imageBytes = await imageFile.readAsBytes();

      // Decode the image and resize it
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw Exception("Failed to decode image");
      }
      final resizedImage =
          img.copyResize(decodedImage, width: 300, height: 300);

      // Encode the resized image back to bytes
      final resizedImageBytes = img.encodeJpg(resizedImage);

      // Create a temporary file for the resized image
      final tempDir = Directory.systemTemp;
      tempFile = File('${tempDir.path}/resized_profile_picture.jpg');
      await tempFile.writeAsBytes(resizedImageBytes);

      // Upload the resized image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
          'profile_pictures/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(tempFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    } finally {
      // Ensure the temporary file is deleted
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  void _validateEmail() {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    setState(() {
      isEmailValid = emailRegex.hasMatch(emailController.text.trim());
    });
  }

  void _validateMandatoryFields() {
    setState(() {
      areMandatoryFieldsFilled = usernameController.text.trim().isNotEmpty &&
          firstNameController.text.trim().isNotEmpty &&
          lastNameController.text.trim().isNotEmpty;
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
        _showErrorDialog(
            AppLocalizations.of(context).translate('invalid_phone'));
        setState(() => _isLoading = false);
        return;
      }

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? profilePictureUrl;
      if (_profileImage != null) {
        // Upload selected image
        profilePictureUrl = await _uploadImageToFirebase(_profileImage!);
      } else if (_selectedAvatarUrl != null) {
        // Use selected avatar URL
        profilePictureUrl = _selectedAvatarUrl;
      } else {
        // Generate initials-based avatar
        final initials = "${firstName[0]}${lastName[0]}".toUpperCase();
        profilePictureUrl = initials; // Save initials as a placeholder
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': firstName,
        'surname': lastName,
        'username': username,
        'email': email,
        // Store normalized E.164 into the single 'phone' field when available
        'phone': phone.isNotEmpty ? phone : null,
        'picture': profilePictureUrl,
      });

      GoRouter.of(context).go('/root');
    } on FirebaseAuthException catch (e) {
      final errorMessage =
          FirebaseExceptionHandler.signInErrorMessage(context, e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      print("Error creating user: $e");
      _showErrorDialog(
          AppLocalizations.of(context).translate('unexpected_error'));
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

  void _generateAvatars({bool nextPage = false}) {
    setState(() {
      if (nextPage) {
        _avatarPage++;
      } else {
        _avatarPage = 1;
      }
      final username = usernameController.text.trim();
      if (username.isEmpty) {
        _avatarUrls = [];
        return;
      }
      _avatarUrls = List.generate(10, (index) {
        final seed = '$username${(_avatarPage - 1) * 10 + index + 1}';
        return 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=$seed&backgroundType=gradientLinear,solid';
      });
    });
  }

  void _selectAvatar(String avatarUrl) {
    setState(() {
      _selectedAvatarUrl = avatarUrl; // Save the selected avatar URL
      _profileImage = null; // Remove any previously selected image
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bool isWideScreen =
        kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    final double maxFormWidth = isWideScreen ? 500.0 : double.infinity;

    return Stack(
      children: [
        Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: isWideScreen
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 32.0, horizontal: 32.0),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mostra solo la pagina corrente, niente PageView/Expanded
                                if (_currentPage == 0)
                                  _buildEmailPage(context, localizations)
                                else if (_currentPage == 1)
                                  _buildPasswordPage(localizations)
                                else if (_currentPage == 2)
                                  _buildUserDetailsPage(localizations)
                                else if (_currentPage == 3)
                                  _buildProfilePicturePage(localizations),
                                if (_currentPage == 0)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        GoRouter.of(context).go('/login');
                                      },
                                      child: Text(
                                        localizations
                                            .translate('already_have_account'),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
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
                              _buildProfilePicturePage(localizations),
                            ],
                          ),
                        ),
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
        if (_isLoading) const LoadingIndicator(), // Show loading indicator
      ],
    );
  }

  Widget _buildEmailPage(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 180,
                child: Image.asset('images/logo.png', height: 200),
              ),
              const SizedBox(height: 20),
              Text(localizations.translate('enter_email'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                width: 350,
                child: TextField(
                  controller: emailController,
                  onChanged: (_) => _validateEmail(),
                  decoration: InputDecoration(
                    labelText: localizations.translate('email'),
                    border: const OutlineInputBorder(),
                    errorText: isEmailValid
                        ? null
                        : localizations.translate('invalid_email'),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 350,
                height: 40,
                child: ElevatedButton(
                  onPressed: isEmailValid ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmailValid
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  child: Text(localizations.translate('next'),
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordPage(AppLocalizations localizations) {
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
      arePasswordsValid = isMinLength &&
          hasUppercase &&
          hasLowercase &&
          hasNumber &&
          passwordsMatch;
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Column(
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
              const SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: localizations.translate('confirm_password'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: arePasswordsValid ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: arePasswordsValid
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                child: Text(
                  localizations.translate('next'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCondition(String text, bool condition) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: condition ? Colors.green : Colors.red,
            fontSize: 14,
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
            // Save the current values to the controllers
            setState(() {
              firstNameController.text = firstNameController.text.trim();
              lastNameController.text = lastNameController.text.trim();
              usernameController.text = usernameController.text.trim();
              phoneController.text = phoneController.text.trim();
            });
            _nextPage();
          },
          actionButtonText: localizations.translate('next'),
          nameController: firstNameController,
          surnameController: lastNameController,
          usernameController: usernameController,
          phoneController: phoneController,
        ),
      ),
    );
  }

  Widget _buildProfilePicturePage(AppLocalizations localizations) {
    final horizontalPadding =
        MediaQuery.of(context).size.width > 600 ? 40.0 : 20.0;
    final bool isWideScreen = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  const SizedBox(height: 30),
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
                    localizations.translate('choose_profile_picture'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60, // Reduced size of the profile picture
                    backgroundColor: Colors.teal,
                    foregroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_selectedAvatarUrl != null
                            ? NetworkImage(_selectedAvatarUrl!)
                            : null),
                    child: _profileImage == null && _selectedAvatarUrl == null
                        ? Initicon(
                            text:
                                "${firstNameController.text} ${lastNameController.text}",
                            backgroundColor: Colors.transparent,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                            ),
                            size:
                                120, // Match the size to the CircleAvatar's diameter
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(localizations.translate('pick_image')),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _generateAvatars(),
                    child: Text(localizations.translate('generate_avatars')),
                  ),
                  // Bottone per vedere altri avatar se già generati
                  if (_avatarUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: () => _generateAvatars(nextPage: true),
                        child: Text('Altri avatar'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_avatarUrls.isNotEmpty)
                    SizedBox(
                        height: isWideScreen ? 180 : 220,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 600), // Limit the grid width
                          child: ScrollConfiguration(
                            behavior: const ScrollBehavior().copyWith(overscroll: false),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 80,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 1,
                                        ),
                                        itemCount: _avatarUrls.length,
                                        itemBuilder: (context, index) {
                                          final avatarUrl = _avatarUrls[index];
                                          return GestureDetector(
                                            onTap: () => _selectAvatar(avatarUrl),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(100),
                                              child: Image.network(
                                                avatarUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createUserInFirebase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      localizations.translate('create_account'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20), // Add padding below the button
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}