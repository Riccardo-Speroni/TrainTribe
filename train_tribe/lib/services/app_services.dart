import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../repositories/user_repository.dart';

class AppServices {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final IUserRepository userRepository;
  const AppServices({required this.firestore, required this.auth, required this.userRepository});
}

/// Lightweight no-op Firestore used in tests when widget code path
/// bypasses actual network calls (e.g. via debugUserDataResolver).
// Note: For tests that bypass Firestore with debug resolvers, provide a fake
// FirebaseFirestore in the test file itself rather than attempting to mock
// sealed SDK classes here.

class AppServicesScope extends InheritedWidget {
  final AppServices services;
  const AppServicesScope({super.key, required this.services, required super.child});

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'AppServicesScope not found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(covariant AppServicesScope oldWidget) => false;
}
