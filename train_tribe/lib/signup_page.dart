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

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
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
      final resizedImage = img.copyResize(decodedImage, width: 300, height: 300);

      // Encode the resized image back to bytes
      final resizedImageBytes = img.encodeJpg(resizedImage);

      // Create a temporary file for the resized image
      final tempDir = Directory.systemTemp;
      tempFile = File('${tempDir.path}/resized_profile_picture.jpg');
      await tempFile.writeAsBytes(resizedImageBytes);

      // Upload the resized image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${DateTime.now().millisecondsSinceEpoch}.jpg');
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

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? profilePictureUrl;
      if (_profileImage != null) {
        // Upload selected image
        profilePictureUrl = await _uploadImageToFirebase(_profileImage!);
      } else {
        // Generate initials-based avatar
        final initials = "${firstName[0]}${lastName[0]}".toUpperCase();
        profilePictureUrl = initials; // Save initials as a placeholder
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': firstName,
        'surname': lastName,
        'username': username,
        'email': email,
        'phone': phone.isNotEmpty ? phone : null,
        'picture': profilePictureUrl,
      });

      GoRouter.of(context).go('/root');
    } on FirebaseAuthException catch (e) {
      final errorMessage = FirebaseExceptionHandler.signInErrorMessage(context, e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      print("Error creating user: $e");
      _showErrorDialog(AppLocalizations.of(context).translate('unexpected_error'));
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Stack(
      children: [
        Scaffold(
          body: Column(
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
              if (_currentPage == 0) // Show link only on the first page
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () {
                      GoRouter.of(context).go('/login');
                    },
                    child: Text(
                      localizations.translate('already_have_account'),
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isLoading) const LoadingIndicator(), // Show loading indicator
      ],
    );
  }

  Widget _buildEmailPage(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('images/djungelskog.jpg', height: 100),
            const SizedBox(height: 20),
            Text(localizations.translate('enter_email'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isEmailValid ? _nextPage : null,
              child: Text(localizations.translate('next')),
            ),
          ],
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
      arePasswordsValid = isMinLength && hasUppercase && hasLowercase && hasNumber && passwordsMatch;
    });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _prevPage,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            localizations.translate('choose_password'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            child: Text(localizations.translate('next')),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
                icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
          ),
          Image.asset('images/djungelskog.jpg', height: 100),
          const SizedBox(height: 20),
          Text(localizations.translate('choose_username'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: usernameController,
            onChanged: (_) => _validateMandatoryFields(),
            decoration: InputDecoration(
              labelText: localizations.translate('username'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(localizations.translate('name_surname'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: firstNameController,
                  onChanged: (_) => _validateMandatoryFields(),
                  decoration: InputDecoration(
                    labelText: localizations.translate('first_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: lastNameController,
                  onChanged: (_) => _validateMandatoryFields(),
                  decoration: InputDecoration(
                    labelText: localizations.translate('last_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(localizations.translate('add_phone_number'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: localizations.translate('phone_number'),
              border: const OutlineInputBorder(),
              helperText: localizations.translate('phone_number_note'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: areMandatoryFieldsFilled ? _nextPage : null,
            child: Text(localizations.translate('next')),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicturePage(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _prevPage,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            localizations.translate('choose_profile_picture'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
            CircleAvatar(
            radius: 75,
            backgroundColor: Colors.teal,
            foregroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null
              ? Initicon(
                text: "${firstNameController.text} ${lastNameController.text}",
                backgroundColor: Colors.transparent,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
                size: 150, // Match the size to the CircleAvatar's diameter
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
            onPressed: _createUserInFirebase,
            child: Text(localizations.translate('create_account')),
          ),
        ],
      ),
    );
  }
}
