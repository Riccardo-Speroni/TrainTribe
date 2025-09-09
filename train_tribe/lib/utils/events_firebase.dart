import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

/// Fetch all calendar events for a user from Firestore.
/// The optional [firestore] parameter allows injection of a fake instance in tests
/// to avoid requiring Firebase.initializeApp().
Future<List<CalendarEvent>> fetchEventsFromFirebase(String userId, {FirebaseFirestore? firestore}) async {
  final fs = firestore ?? FirebaseFirestore.instance;
  final userEventsRef = fs.collection('users').doc(userId).collection('events');
  final userEventsSnapshot = await userEventsRef.get();
  final List<CalendarEvent> result = [];
  for (final doc in userEventsSnapshot.docs) {
    final eventDoc = await userEventsRef.doc(doc.id).get();
    if (eventDoc.exists) {
      final data = eventDoc.data();
      if (data != null) {
        result.add(CalendarEvent.fromFirestore(eventDoc.id, data));
      }
    }
  }
  return result;
}
