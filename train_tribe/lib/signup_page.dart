import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'main.dart';

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
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent swiping
        children: [
          _buildUsernamePage(context),
          _buildPasswordPage(),
          _buildPhoneAndEmailPage(),
          _buildProfilePicturePage(),
        ],
      ),
    );
  }

  // Step 1: Username
  Widget _buildUsernamePage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('images/djungelskog.jpg', height: 100),
            
            const SizedBox(height: 20),
            
            const Text("Choose a username", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            const TextField(
              decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(onPressed: _nextPage, child: const Text("Next")),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: () {}, // TODO: Google Auth
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: () {}, // TODO: Facebook Auth
              icon: const Icon(Icons.facebook),
              label: const Text("Sign in with Facebook"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
            
            const SizedBox(height: 20),
            
            // Login Redirection
              GestureDetector(
                onTap: () {
                  GoRouter.of(context).go('/login'); // Navigate to Login Page
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Step 2: Password
  Widget _buildPasswordPage() {
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
          
          const Text("Choose a password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder())),
          
          const SizedBox(height: 20),
          
          const Text("Repeat the password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder())),
          
          const SizedBox(height: 20),
          
          ElevatedButton(onPressed: _nextPage, child: const Text("Next")),
        ],
      ),
    );
  }

  // Step 3: Phone & Email
  Widget _buildPhoneAndEmailPage() {
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
          
          const Text("Add your Phone Number", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder())),
          
          const SizedBox(height: 20),
          
          const Text("Your email", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
          
          const SizedBox(height: 20),
         
          const Text("Name and Surname", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(labelText: "First Name", border: OutlineInputBorder()))),
              SizedBox(width: 10),
              Expanded(child: TextField(decoration: InputDecoration(labelText: "Last Name", border: OutlineInputBorder()))),
            ],
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton(onPressed: _nextPage, child: const Text("Next")),
        ],
      ),
    );
  }

  // Step 4: Profile Picture
  Widget _buildProfilePicturePage() {
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
          
          const Text("Choose a profile picture", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 75,
            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null, //TODO: Add default image
            child: _profileImage == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(onPressed: _pickImage, child: const Text("Pick an Image")),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () {
              // TODO: Handle account creation

              // Simulate successful login
              isLoggedIn.value = true;
              print("User logged in"); // Debug log
              GoRouter.of(context).go('/root');
            },
            child: const Text("Create Account"),
          ),
        ],
      ),
    );
  }
}
