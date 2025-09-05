import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/train_preload_utils.dart';

void main() {
  test('computePreloadedConfirmations picks first fully confirmed route per event', () async {
    final events = {
      'e1': [
        {
          // route 0 2 legs
          'leg1': {'trip_id': 'A'},
          'leg2': {'trip_id': 'B'},
        },
        {
          // route 1 single
          'leg1': {'trip_id': 'C'},
        }
      ],
      'e2': [
        {
          'leg1': {'trip_id': 'X'}
        },
        {
          'leg1': {'trip_id': 'Y'}
        },
      ]
    };
    final confirmedSets = <String, Set<String>>{
      'e1': {'A', 'B'}, // route 0 fully confirmed
      'e2': {'Y'}, // only second route confirmed
    };

    final result = await computePreloadedConfirmations(events, (eventId, allTrainIds) async => confirmedSets[eventId] ?? {});
    expect(result['e1'], 'A+B');
    expect(result['e2'], 'Y');
  });

  test('computePreloadedConfirmations returns empty map when no confirmations', () async {
    final events = {
      'e1': [
        {
          'leg1': {'trip_id': 'A'}
        },
      ],
    };
    final result = await computePreloadedConfirmations(events, (e, ids) async => {});
    expect(result.containsKey('e1'), isFalse);
  });
}
