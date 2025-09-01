import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Handles confirming a train for an event. Only one confirmed train per event per user.
/// We represent a confirmed train by setting:
/// trains_match / {yyyy-MM-dd} / trains / {trainId} / users / {userId}  { confirmed: true, updatedAt: Timestamp }
/// All other trains for the same date (and therefore same event day) for that user will be set to confirmed:false.
class TrainConfirmationService {
  final FirebaseFirestore _firestore;
  TrainConfirmationService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// (Deprecated single-train helper) Retained for backward compatibility.
  /// Uses new multi-train route logic with a single selected + event set.
  Future<(String?, String)> confirmTrain({
    required String dateStr,
    required String trainId,
    required String userId,
    required List<String> eventTrainIds,
  }) async {
    return confirmRoute(
      dateStr: dateStr,
      selectedRouteTrainIds: [trainId],
      userId: userId,
      allEventTrainIds: eventTrainIds.toSet().toList(),
    );
  }

  /// Confirm an entire route (all its leg trainIds).
  /// Sets confirmed=true for every train in selectedRouteTrainIds.
  /// Sets confirmed=false for every other train in allEventTrainIds (scoping to same event/day).
  /// Returns (errorMessage, statusMessage).
  Future<(String?, String)> confirmRoute({
    required String dateStr,
    required List<String> selectedRouteTrainIds,
    required String userId,
    required List<String> allEventTrainIds,
  }) async {
    final uniqueAll = allEventTrainIds.toSet();
    final selectedSet = selectedRouteTrainIds.toSet();
    final batch = _firestore.batch();
    final now = Timestamp.now();

    try {
      for (final trainId in uniqueAll) {
        final docRef = _firestore.collection('trains_match').doc(dateStr).collection('trains').doc(trainId).collection('users').doc(userId);

        final isSelected = selectedSet.contains(trainId);
        batch.set(
            docRef,
            {
              'confirmed': isSelected,
              'updatedAt': now,
            },
            SetOptions(merge: true));
      }
      await batch.commit();
      return (null, 'route_confirmed');
    } catch (e, st) {
      debugPrint('confirmRoute error: $e\n$st');
      return ('confirm_route_error', e.toString());
    }
  }

  /// Fetch all trainIds (subset of provided trainIds) that are confirmed for the user on the day.
  Future<Set<String>> fetchConfirmedTrainIds({
    required String dateStr,
    required String userId,
    required List<String> trainIds,
  }) async {
    final confirmed = <String>{};
    try {
      for (final trainId in trainIds.toSet()) {
        final doc = await _firestore
            .collection('trains_match')
            .doc(dateStr)
            .collection('trains')
            .doc(trainId)
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists && (doc.data()?['confirmed'] == true)) {
          confirmed.add(trainId);
        }
      }
    } catch (e, st) {
      debugPrint('fetchConfirmedTrainIds error: $e\n$st');
    }
    return confirmed;
  }

  /// Determine if a given route (list of trainIds) is fully confirmed.
  Future<bool> isRouteConfirmed({
    required String dateStr,
    required String userId,
    required List<String> routeTrainIds,
  }) async {
    final set = await fetchConfirmedTrainIds(
      dateStr: dateStr,
      userId: userId,
      trainIds: routeTrainIds,
    );
    return routeTrainIds.every(set.contains);
  }

  /// (Legacy) Return ONE confirmed train among eventTrainIds (kept for older calls).
  Future<String?> fetchConfirmedTrain({
    required String dateStr,
    required String userId,
    required List<String> eventTrainIds,
  }) async {
    final set = await fetchConfirmedTrainIds(
      dateStr: dateStr,
      userId: userId,
      trainIds: eventTrainIds,
    );
    return set.isEmpty ? null : set.first;
  }
}
