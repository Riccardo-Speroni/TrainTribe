import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'main.dart';
import 'l10n/app_localizations.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  File? _profileImage;

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
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context); 
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent swiping
        children: [
          _buildUsernamePage(context, localizations),
          _buildPasswordPage(localizations),
          _buildPhoneAndEmailPage(localizations),
          _buildProfilePicturePage(localizations),
        ],
      ),
    );
  }

  // Step 1: Username
  Widget _buildUsernamePage(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('images/djungelskog.jpg', height: 100),
            
            const SizedBox(height: 20),
            
            Text(localizations.translate('choose_username'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            TextField(
              decoration: InputDecoration(labelText: localizations.translate('username'), border: const OutlineInputBorder()),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(onPressed: _nextPage, child: Text(localizations.translate('next'))),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: () {}, // TODO: Google Auth
              icon: const Icon(Icons.login),
              label: Text(localizations.translate('sign_in_google')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: () {}, // TODO: Facebook Auth
              icon: const Icon(Icons.facebook),
              label: Text(localizations.translate('sign_in_facebook')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
            
            const SizedBox(height: 20),
            
            // Login Redirection
              GestureDetector(
                onTap: () {
                  GoRouter.of(context).go('/login'); // Navigate to Login Page
                },
                child: Text(
                  localizations.translate('already_have_account'),
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Step 2: Password
  Widget _buildPasswordPage(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
          ),

          const SizedBox(height: 20),

          Image.asset('images/djungelskog.jpg', height: 100),
            
          const SizedBox(height: 20),
          
          Text(localizations.translate('choose_password'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(obscureText: true, decoration: InputDecoration(labelText: localizations.translate('password'), border: const OutlineInputBorder())),
          
          const SizedBox(height: 20),
          
          Text(localizations.translate('repeat_password'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(obscureText: true, decoration: InputDecoration(labelText: localizations.translate('confirm_password'), border: const OutlineInputBorder())),
          
          const SizedBox(height: 20),
          
          ElevatedButton(onPressed: _nextPage, child: Text(localizations.translate('next'))),
        ],
      ),
    );
  }

  // Step 3: Phone & Email
  Widget _buildPhoneAndEmailPage(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
          ),
          
          Image.asset('images/djungelskog.jpg', height: 100),
          
          const SizedBox(height: 20),
          
          Text(localizations.translate('add_phone_number'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: localizations.translate('phone_number'), border: const OutlineInputBorder())),
          
          const SizedBox(height: 20),
          
          Text(localizations.translate('your_email'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: localizations.translate('email'), border: const OutlineInputBorder())),
          
          const SizedBox(height: 20),
         
          Text(localizations.translate('name_surname'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(labelText: localizations.translate('first_name'), border: const OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(decoration: InputDecoration(labelText: localizations.translate('last_name'), border: const OutlineInputBorder()))),
            ],
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton(onPressed: _nextPage, child: Text(localizations.translate('next'))),
        ],
      ),
    );
  }

  // Step 4: Profile Picture
  Widget _buildProfilePicturePage(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
          ),
          
          Image.asset('images/djungelskog.jpg', height: 100),
          
          const SizedBox(height: 20),
          
          Text(localizations.translate('choose_profile_picture'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 75,
            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null, //TODO: Add default image
            child: _profileImage == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(onPressed: _pickImage, child: Text(localizations.translate('pick_image'))),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () {
              // TODO: Handle account creation

              // Simulate successful login
              isLoggedIn.value = true;
              print("User logged in"); // Debug log
              GoRouter.of(context).go('/root');
            },
            child: Text(localizations.translate('create_account')),
          ),
        ],
      ),
    );
  }
}
