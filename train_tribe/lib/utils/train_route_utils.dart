// Utility functions extracted from TrainsPage to enable unit testing.

// Extract legs from a route map (keys starting with 'leg' ordered numerically).
List<Map<String, dynamic>> extractLegs(Map<String, dynamic> route) {
  final legs = <Map<String, dynamic>>[];
  final legKeys = route.keys.where((k) => k.startsWith('leg')).toList()
    ..sort((a, b) {
      int ai = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int bi = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return ai.compareTo(bi);
    });
  for (final k in legKeys) {
    final leg = route[k];
    if (leg is Map) legs.add(Map<String, dynamic>.from(leg));
  }
  return legs;
}

// Merge friend avatars across legs preserving earliest from and latest to, and AND-confirmation across legs they appear in.
List<Map<String, String>> mergeFriendAvatars(List<Map<String, dynamic>> legs) {
  final Map<String, Map<String, String>> userAvatarsMap = {};
  for (final leg in legs) {
    final friends = leg['friends'];
    if (friends is List) {
      for (final friend in friends) {
        if (friend is Map) {
          final friendUserId = (friend['user_id'] ?? '') as String;
          final image = (friend['picture'] ?? '').toString();
          final name = (friend['username'] ?? '').toString();
          final from = (friend['from'] ?? '').toString();
          final to = (friend['to'] ?? '').toString();
          final legConfirmed = friend['confirmed'] == true;
          final key = friendUserId.isNotEmpty ? friendUserId : '$image|$name';
          if (!userAvatarsMap.containsKey(key)) {
            userAvatarsMap[key] = {
              'image': image,
              'name': name,
              'from': from,
              'to': to,
              'confirmed': legConfirmed ? 'true' : 'false',
              'user_id': friendUserId,
            };
          } else {
            final prev = userAvatarsMap[key]!;
            final prevFrom = prev['from'] ?? from;
            final prevTo = prev['to'] ?? to;
            prev['from'] = (from.compareTo(prevFrom) < 0) ? from : prevFrom;
            prev['to'] = (to.compareTo(prevTo) > 0) ? to : prevTo;
            final prevConfirmed = prev['confirmed'] == 'true';
            prev['confirmed'] = (prevConfirmed && legConfirmed).toString();
          }
        }
      }
    }
  }
  return userAvatarsMap.values.toList();
}

// Compute departure and arrival time (HH:mm) picking board time at first leg 'from' and alight time at last leg 'to'.
Map<String, String> computeDepartureArrivalTimes(List<Map<String, dynamic>> legs) {
  String departureTime = '';
  String arrivalTime = '';
  String toHHmm(dynamic t) {
    final s = (t ?? '').toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  if (legs.isNotEmpty) {
    final firstLeg = legs.first;
    final lastLeg = legs.last;
    final firstFromId = (firstLeg['from'] ?? '').toString();
    final lastToId = (lastLeg['to'] ?? '').toString();
    final firstStops = (firstLeg['stops'] as List<dynamic>? ?? []);
    final lastStops = (lastLeg['stops'] as List<dynamic>? ?? []);
    if (firstStops.isNotEmpty) {
      Map<String, dynamic>? boardStop;
      for (final s in firstStops) {
        if (s is Map && ((s['stop_id'] ?? '').toString() == firstFromId)) {
          boardStop = Map<String, dynamic>.from(s);
          break;
        }
      }
      boardStop ??= Map<String, dynamic>.from(firstStops.first as Map);
      departureTime = toHHmm(boardStop['departure_time'] ?? boardStop['arrival_time']);
    }
    if (lastStops.isNotEmpty) {
      Map<String, dynamic>? alightStop;
      for (final s in lastStops) {
        if (s is Map && ((s['stop_id'] ?? '').toString() == lastToId)) {
          alightStop = Map<String, dynamic>.from(s);
          break;
        }
      }
      alightStop ??= Map<String, dynamic>.from(lastStops.last as Map);
      arrivalTime = toHHmm(alightStop['arrival_time'] ?? alightStop['departure_time']);
    }
  }
  return {'departure': departureTime, 'arrival': arrivalTime};
}
