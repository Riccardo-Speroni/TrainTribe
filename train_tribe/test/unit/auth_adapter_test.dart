import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:train_tribe/utils/auth_adapter.dart';

void main() {
  group('FirebaseAuthAdapter', () {
    test('signInWithEmailAndPassword delegates to FirebaseAuth', () async {
      final mockUser = MockUser(email: 'user@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser);
      final adapter = FirebaseAuthAdapter(auth: mockAuth);
      expect(adapter.currentUser, isNull); // not signed in yet
      await adapter.signInWithEmailAndPassword(email: 'user@test.com', password: 'pw');
      expect(adapter.currentUser?.email, 'user@test.com');
    });
  });
}
