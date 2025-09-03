import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstraction for mood load/save so the widget can be tested without Firebase.
abstract class MoodRepository {
  Future<bool> load(String userId);
  Future<void> save(String userId, bool mood);
}

class FirebaseMoodRepository implements MoodRepository {
  final FirebaseFirestore _firestore;
  FirebaseMoodRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<bool> load(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['mood'] is bool) {
        return data['mood'] as bool;
      }
    }
    // ensure default persisted
    await _firestore.collection('users').doc(userId).set({'mood': true}, SetOptions(merge: true));
    return true;
  }

  @override
  Future<void> save(String userId, bool mood) async {
    await _firestore.collection('users').doc(userId).set({'mood': mood}, SetOptions(merge: true));
  }
}
