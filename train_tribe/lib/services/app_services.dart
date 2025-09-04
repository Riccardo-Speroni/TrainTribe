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
