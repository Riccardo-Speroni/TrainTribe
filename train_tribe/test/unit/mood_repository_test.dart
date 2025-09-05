import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_tribe/utils/mood_repository.dart';

class _FakeFirebaseMoodRepository extends FirebaseMoodRepository {
  _FakeFirebaseMoodRepository(FirebaseFirestore firestore) : super(firestore: firestore);
}

void main() {
  group('FirebaseMoodRepository', () {
    test('load returns existing mood true/false without overriding', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('users').doc('u1').set({'mood': false});
      await fake.collection('users').doc('u2').set({'mood': true});
      final repo = _FakeFirebaseMoodRepository(fake);
      expect(await repo.load('u1'), false);
      expect(await repo.load('u2'), true);
      // Ensure values not flipped
      final d1 = await fake.collection('users').doc('u1').get();
      expect(d1.data()!['mood'], false);
    });

    test('load persists default true when document missing or mood missing', () async {
      final fake = FakeFirebaseFirestore();
      final repo = _FakeFirebaseMoodRepository(fake);
      final val = await repo.load('u3');
      expect(val, true);
      final doc = await fake.collection('users').doc('u3').get();
      expect(doc.exists, true);
      expect(doc.data()!['mood'], true);
      // Case: mood field absent
      await fake.collection('users').doc('u4').set({'other': 1});
      final val2 = await repo.load('u4');
      expect(val2, true);
      final doc2 = await fake.collection('users').doc('u4').get();
      expect(doc2.data()!['mood'], true);
    });

    test('save updates mood value', () async {
      final fake = FakeFirebaseFirestore();
      final repo = _FakeFirebaseMoodRepository(fake);
      await repo.save('u5', false);
      var doc = await fake.collection('users').doc('u5').get();
      expect(doc.data()!['mood'], false);
      await repo.save('u5', true);
      doc = await fake.collection('users').doc('u5').get();
      expect(doc.data()!['mood'], true);
    });
  });
}
