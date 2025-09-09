import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IUserRepository {
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data);
  Future<bool> isUsernameUnique(String username);
}

class FirestoreUserRepository implements IUserRepository {
  final FirebaseFirestore firestore;
  FirestoreUserRepository(this.firestore);

  @override
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(uid).set(data);
  }

  @override
  Future<bool> isUsernameUnique(String username) async {
    final query = await firestore.collection('users').where('username', isEqualTo: username).limit(1).get();
    return query.docs.isEmpty;
  }
}
