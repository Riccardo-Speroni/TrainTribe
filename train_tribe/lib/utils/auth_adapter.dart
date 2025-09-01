import 'package:firebase_auth/firebase_auth.dart';

/// Simple abstraction to allow mocking FirebaseAuth in widget tests.
abstract class AuthAdapter {
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password});
  User? get currentUser;
}

class FirebaseAuthAdapter implements AuthAdapter {
  final FirebaseAuth _auth;
  FirebaseAuthAdapter({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  User? get currentUser => _auth.currentUser;
}
