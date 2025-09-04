import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/train_route_utils.dart';

void main() {
  group('train_route_utils', () {
    test('extractLegs orders legs numerically', () {
      final route = {
        'leg10': {'trip_id': 'T10'},
        'leg2': {'trip_id': 'T2'},
        'other': 5,
        'leg1': {'trip_id': 'T1'},
      };
      final legs = extractLegs(route);
      expect(legs.map((l) => l['trip_id']).toList(), ['T1', 'T2', 'T10']);
    });

    test('mergeFriendAvatars merges ranges and ANDs confirmed', () {
      final legs = [
        {
          'friends': [
            {'user_id': 'u1', 'username': 'alice', 'picture': 'a.png', 'from': 'A', 'to': 'B', 'confirmed': true},
            {'user_id': 'u2', 'username': 'bob', 'picture': 'b.png', 'from': 'A', 'to': 'C', 'confirmed': true},
          ]
        },
        {
          'friends': [
            {'user_id': 'u1', 'username': 'alice', 'picture': 'a.png', 'from': 'B', 'to': 'D', 'confirmed': true},
            {'user_id': 'u2', 'username': 'bob', 'picture': 'b.png', 'from': 'C', 'to': 'D', 'confirmed': false},
          ]
        }
      ];
      final merged = mergeFriendAvatars(legs);
      final u1 = merged.firstWhere((m) => m['user_id'] == 'u1');
      final u2 = merged.firstWhere((m) => m['user_id'] == 'u2');
      expect(u1['from'], 'A');
      expect(u1['to'], 'D');
      expect(u1['confirmed'], 'true');
      expect(u2['from'], 'A');
      expect(u2['to'], 'D');
      expect(u2['confirmed'], 'false');
    });

    test('computeDepartureArrivalTimes resolves board/alight times', () {
      final legs = [
        {
          'from': 'S1',
          'to': 'S2',
          'stops': [
            {'stop_id': 'S1', 'departure_time': '08:05:00', 'arrival_time': '08:00:00'},
            {'stop_id': 'S2', 'arrival_time': '08:45:00'}
          ]
        },
        {
          'from': 'S2',
          'to': 'S3',
          'stops': [
            {'stop_id': 'S2', 'departure_time': '08:50:00'},
            {'stop_id': 'S3', 'arrival_time': '09:30:00'}
          ]
        }
      ];
      final times = computeDepartureArrivalTimes(legs);
      expect(times['departure'], '08:05');
      expect(times['arrival'], '09:30');
    });

    test('computeDepartureArrivalTimes empty legs returns blanks', () {
      final times = computeDepartureArrivalTimes([]);
      expect(times['departure'], '');
      expect(times['arrival'], '');
    });
  });
}
