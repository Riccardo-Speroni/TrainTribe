import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _MemoryStore implements ConfirmationStore {
  final Map<String, Map<String, Map<String, bool>>> _data = {}; // date -> trainId -> userId -> confirmed

  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    _data.putIfAbsent(dateStr, () => {});
    _data[dateStr]!.putIfAbsent(trainId, () => {});
    _data[dateStr]![trainId]![userId] = confirmed;
  }

  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    return _data[dateStr]?[trainId]?[userId] == true;
  }
}

class _ThrowingStore implements ConfirmationStore {
  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    throw Exception('boom');
  }

  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    throw Exception('boom');
  }
}

void main() {
  group('TrainConfirmationService', () {
    test('confirmRoute sets only selected trains confirmed', () async {
      final store = _MemoryStore();
      final svc = TrainConfirmationService(store: store);
      final all = ['A', 'B', 'C'];
      final selected = ['A', 'C'];
      final (err, status) = await svc.confirmRoute(
        dateStr: '2025-01-01',
        selectedRouteTrainIds: selected,
        userId: 'u1',
        allEventTrainIds: all,
      );
      expect(err, isNull);
      expect(status, 'route_confirmed');
      expect(await store.getConfirmation(dateStr: '2025-01-01', trainId: 'A', userId: 'u1'), true);
      expect(await store.getConfirmation(dateStr: '2025-01-01', trainId: 'C', userId: 'u1'), true);
      expect(await store.getConfirmation(dateStr: '2025-01-01', trainId: 'B', userId: 'u1'), false);
    });

    test('fetchConfirmedTrainIds returns only confirmed subset', () async {
      final store = _MemoryStore();
      final svc = TrainConfirmationService(store: store);
      await svc.confirmRoute(dateStr: '2025-01-02', selectedRouteTrainIds: ['X'], userId: 'u2', allEventTrainIds: ['X', 'Y']);
      final set = await svc.fetchConfirmedTrainIds(dateStr: '2025-01-02', userId: 'u2', trainIds: ['X', 'Y', 'Z']);
      expect(set, {'X'});
    });

    test('isRouteConfirmed true only when all trains confirmed', () async {
      final store = _MemoryStore();
      final svc = TrainConfirmationService(store: store);
      await svc.confirmRoute(
          dateStr: '2025-01-03', selectedRouteTrainIds: ['R1', 'R2'], userId: 'u3', allEventTrainIds: ['R1', 'R2', 'R3']);
      expect(await svc.isRouteConfirmed(dateStr: '2025-01-03', userId: 'u3', routeTrainIds: ['R1', 'R2']), true);
      expect(await svc.isRouteConfirmed(dateStr: '2025-01-03', userId: 'u3', routeTrainIds: ['R1', 'R3']), false);
    });

    test('legacy fetchConfirmedTrain returns first confirmed or null', () async {
      final store = _MemoryStore();
      final svc = TrainConfirmationService(store: store);
      await svc.confirmRoute(dateStr: '2025-01-04', selectedRouteTrainIds: ['T9'], userId: 'u4', allEventTrainIds: ['T8', 'T9']);
      final confirmed = await svc.fetchConfirmedTrain(dateStr: '2025-01-04', userId: 'u4', eventTrainIds: ['T8', 'T9']);
      expect(confirmed, 'T9');
      final none = await svc.fetchConfirmedTrain(dateStr: '2025-01-04', userId: 'u4', eventTrainIds: ['Z1']);
      expect(none, isNull);
    });

    test('confirmRoute surfaces error tuple on store failure', () async {
      final svc = TrainConfirmationService(store: _ThrowingStore());
      final (err, status) = await svc.confirmRoute(
        dateStr: '2025-02-01',
        selectedRouteTrainIds: ['A'],
        userId: 'uErr',
        allEventTrainIds: ['A', 'B'],
      );
      expect(err, isNotNull);
      expect(status, isNotEmpty);
    });

    test('fetchConfirmedTrainIds returns empty set on store failure', () async {
      final svc = TrainConfirmationService(store: _ThrowingStore());
      final set = await svc.fetchConfirmedTrainIds(dateStr: '2025-02-02', userId: 'uErr2', trainIds: ['X', 'Y']);
      expect(set, isEmpty);
    });
  });
}
