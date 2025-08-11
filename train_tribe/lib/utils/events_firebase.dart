import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

Future<List<CalendarEvent>> fetchEventsFromFirebase(String userId) async {
  final userEventsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('events');
  final userEventsSnapshot = await userEventsRef.get();
  List<CalendarEvent> result = [];

  for (var doc in userEventsSnapshot.docs) {
    final eventId = doc.id;
    final eventDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .get();
    if (eventDoc.exists) {
      result.add(CalendarEvent.fromFirestore(eventDoc.id, eventDoc.data()!));
    }
  }
  return result;
}
