import 'train_utils.dart';

/// Compute preloaded confirmed route signatures for each event.
/// [eventsData] structure: eventId -> List of route maps; each route map contains legN entries.
/// [fetchConfirmed] is an async function returning the set of confirmed trainIds for the event.
/// Returns map of eventId -> routeSignature (first fully confirmed route only) when found.
Future<Map<String, String?>> computePreloadedConfirmations(
  Map<String, List<dynamic>> eventsData,
  Future<Set<String>> Function(String eventId, Set<String> eventTrainIds) fetchConfirmed,
) async {
  final result = <String, String?>{};
  for (final entry in eventsData.entries) {
    final eventId = entry.key;
    final routes = entry.value;
    final Set<String> allEventTrainIds = {};
    final List<List<String>> routeTrainIdLists = [];

    for (final r in routes) {
      if (r is Map<String, dynamic>) {
        final List<String> routeTrainIds = [];
        final legKeys = r.keys.where((k) => k.startsWith('leg')).toList()
          ..sort((a, b) {
            int ai = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            int bi = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return ai.compareTo(bi);
          });
        for (final lk in legKeys) {
          final leg = r[lk];
          if (leg is Map && leg['trip_id'] != null) {
            final tid = leg['trip_id'].toString();
            routeTrainIds.add(tid);
            allEventTrainIds.add(tid);
          }
        }
        if (routeTrainIds.isNotEmpty) routeTrainIdLists.add(routeTrainIds);
      }
    }
    if (allEventTrainIds.isEmpty) continue;
    final confirmedIds = await fetchConfirmed(eventId, allEventTrainIds);
    for (final routeIds in routeTrainIdLists) {
      if (routeIds.every(confirmedIds.contains)) {
        result[eventId] = routeSignature(routeIds);
        break; // only one per event
      }
    }
  }
  return result;
}
