import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _MemoryStore implements ConfirmationStore {
  final Map<String, Map<String, Map<String, bool>>> _data = {}; // date -> trainId -> userId -> confirmed

  @override
  Future<void> setConfirmation({required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    _data.putIfAbsent(dateStr, () => {});
    _data[dateStr]!.putIfAbsent(trainId, () => {});
    _data[dateStr]![trainId]![userId] = confirmed;
  }

  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    return _data[dateStr]?[trainId]?[userId] == true;
  }
}

void main() {
  test('confirmTrain (deprecated alias) confirms only selected train', () async {
    final store = _MemoryStore();
    final svc = TrainConfirmationService(store: store);
    final (err, status) = await svc.confirmTrain(
      dateStr: '2025-03-10',
      trainId: 'T1',
      userId: 'userX',
      eventTrainIds: ['T1', 'T2', 'T3'],
    );
    expect(err, isNull);
    expect(status, 'route_confirmed');
    expect(await store.getConfirmation(dateStr: '2025-03-10', trainId: 'T1', userId: 'userX'), true);
    expect(await store.getConfirmation(dateStr: '2025-03-10', trainId: 'T2', userId: 'userX'), false);
    expect(await store.getConfirmation(dateStr: '2025-03-10', trainId: 'T3', userId: 'userX'), false);
  });
}
