import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Handles confirming a train for an event. Only one confirmed train per event per user.
/// We represent a confirmed train by setting:
/// trains_match / {yyyy-MM-dd} / trains / {trainId} / users / {userId}  { confirmed: true, updatedAt: Timestamp }
/// All other trains for the same date (and therefore same event day) for that user will be set to confirmed:false.
class TrainConfirmationService {
	final FirebaseFirestore _firestore;
	TrainConfirmationService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

	/// Confirm a train for a specific event (scoped via the list of eventTrainIds).
	/// Unconfirms any previously confirmed train among the provided eventTrainIds.
	Future<(String?, String)> confirmTrain({
		required String dateStr,
		required String trainId,
		required String userId,
		required List<String> eventTrainIds,
	}) async {
		final trainsCol = _firestore.collection('trains_match').doc(dateStr).collection('trains');
		String? previousConfirmed;
		final batch = _firestore.batch();
		try {
			for (final id in eventTrainIds) {
				final userDocRef = trainsCol.doc(id).collection('users').doc(userId);
				final userDoc = await userDocRef.get();
				final isThisConfirmed = (userDoc.data()?['confirmed'] == true);
				if (isThisConfirmed) {
					previousConfirmed = id;
				}
			}
			if (previousConfirmed != null && previousConfirmed != trainId) {
				final prevRef = trainsCol.doc(previousConfirmed).collection('users').doc(userId);
				batch.set(prevRef, {
					'confirmed': false,
				}, SetOptions(merge: true));
			}
			final newRef = trainsCol.doc(trainId).collection('users').doc(userId);
			batch.set(newRef, {
				'confirmed': true,
			}, SetOptions(merge: true));
			await batch.commit();
			return (previousConfirmed, trainId);
		} catch (e, st) {
			debugPrint('confirmTrain error for user=$userId date=$dateStr train=$trainId: $e');
			debugPrint(st.toString());
			rethrow;
		}
	}

	/// Return the confirmed train among eventTrainIds for the user, if any.
	Future<String?> fetchConfirmedTrain({
		required String dateStr,
		required String userId,
		required List<String> eventTrainIds,
	}) async {
		final trainsCol = _firestore.collection('trains_match').doc(dateStr).collection('trains');
		try {
			for (final id in eventTrainIds) {
				final userDoc = await trainsCol.doc(id).collection('users').doc(userId).get();
				if (userDoc.exists && userDoc.data()?['confirmed'] == true) {
					return id;
				}
			}
		} catch (e, st) {
			debugPrint('fetchConfirmedTrain error for user=$userId date=$dateStr: $e');
			debugPrint(st.toString());
			return null;
		}
		return null;
	}
}

