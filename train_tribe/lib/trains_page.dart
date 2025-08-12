import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'l10n/app_localizations.dart';
import 'widgets/train_card.dart';
import 'widgets/responsive_card_list.dart';

class TrainsPage extends StatefulWidget {
  const TrainsPage({super.key});

  @override
  State<TrainsPage> createState() => _TrainsPageState();
}

class _TrainsPageState extends State<TrainsPage> {
  late List<String> daysOfWeekFull;
  late List<String> daysOfWeekShort;
  int selectedDayIndex = 0;
  int? expandedCardIndex;
  Map<String, List<dynamic>>? eventsData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    daysOfWeekFull = [];
    daysOfWeekShort = [];
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    setState(() {
      daysOfWeekFull = List.generate(7, (index) {
        final now = DateTime.now();
        final day = now.add(Duration(days: index));
        return toBeginningOfSentenceCase(
            DateFormat.EEEE(localizations.languageCode()).format(day))!;
      });

      daysOfWeekShort = List.generate(7, (index) {
        final now = DateTime.now();
        final day = now.add(Duration(days: index));
        return toBeginningOfSentenceCase(
            DateFormat.E(localizations.languageCode()).format(day))!;
      });
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Get current user ID
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    // Get selected date
    final now = DateTime.now().add(Duration(days: selectedDayIndex));
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    // --- Actual HTTP call ---
    final url = Uri.parse('https://get-event-full-trip-data-v75np53hva-uc.a.run.app?date=$dateStr&userId=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      eventsData = (json.decode(response.body) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as List<dynamic>),
      );
    }
    
    // --- Fake hardcoded json file ---
    /* final jsonString = await rootBundle.loadString('images/json_example.json');
    eventsData = (json.decode(jsonString) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as List<dynamic>),
    );*/

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showFullDays = screenWidth > 600;
    final daysOfWeek = showFullDays ? daysOfWeekFull : daysOfWeekShort;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('trains')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Row(
            children: List.generate(daysOfWeek.length, (index) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDayIndex = index;
                    });
                    _loadData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    decoration: BoxDecoration(
                      color: selectedDayIndex == index ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Center(
                      child: Text(
                        daysOfWeek[index],
                        style: TextStyle(
                          color: selectedDayIndex == index ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: eventsData == null
                  ? Center(child: Text(localizations.translate('no_trains_found')))
                  : ListView(
                      children: [
                        ...eventsData!.entries.map((eventEntry) {
                          final eventId = eventEntry.key;
                          final routes = eventEntry.value;
                          // Build the list of TrainCards for this event
                          final trainCards = routes.asMap().entries.map((routeEntry) {
                            final routeIndex = routeEntry.key;
                            final route = routeEntry.value as Map<String, dynamic>;
                            // Collect all legs (leg0, leg1, ...)
                            final legs = <Map<String, dynamic>>[];
                            for (var k in route.keys) {
                              if (k.startsWith('leg')) {
                                legs.add(route[k]);
                              }
                            }
                            // For userAvatars: collect all friends from all legs, and merge by user_id (or image+name)
                            final Map<String, Map<String, String>> userAvatarsMap = {};
                            for (final leg in legs) {
                              if (leg['friends'] != null) {
                                for (final friend in (leg['friends'] as List)) {
                                  final userId = (friend['user_id'] ?? '') as String;
                                  final image = (friend['picture'] ?? '').toString();
                                  final name = (friend['username'] ?? '').toString();
                                  final from = (friend['from'] ?? '').toString();
                                  final to = (friend['to'] ?? '').toString();
                                  // Use userId if present, otherwise fallback to image+name
                                  final key = userId.isNotEmpty ? userId : '$image|$name';
                                  if (!userAvatarsMap.containsKey(key)) {
                                    userAvatarsMap[key] = {
                                      'image': image,
                                      'name': name,
                                      'from': from,
                                      'to': to,
                                    };
                                  } else {
                                    // Merge: set from=min(from), to=max(to)
                                    final prevFrom = userAvatarsMap[key]!['from'] ?? from;
                                    final prevTo = userAvatarsMap[key]!['to'] ?? to;
                                    // Use string comparison for stop_id, or if numeric, use int
                                    userAvatarsMap[key]!['from'] =
                                        (from.compareTo(prevFrom) < 0) ? from : prevFrom;
                                    userAvatarsMap[key]!['to'] =
                                        (to.compareTo(prevTo) > 0) ? to : prevTo;
                                  }
                                }
                              }
                            }
                            final userAvatars = userAvatarsMap.values.toList();
                            // Departure/arrival time: from first/last stop of first/last leg
                            String departureTime = '';
                            String arrivalTime = '';
                            if (legs.isNotEmpty) {
                              final firstLeg = legs.first;
                              final lastLeg = legs.last;
                              final firstStops = firstLeg['stops'] as List<dynamic>;
                              final lastStops = lastLeg['stops'] as List<dynamic>;
                              if (firstStops.isNotEmpty) {
                                departureTime = (firstStops.first['departure_time'] ?? firstStops.first['arrival_time'] ?? '').toString().substring(0,5);
                              }
                              if (lastStops.isNotEmpty) {
                                arrivalTime = (lastStops.last['arrival_time'] ?? lastStops.last['departure_time'] ?? '').toString().substring(0,5);
                              }
                            }
                            // isDirect: only one leg
                            final isDirect = legs.length == 1;
                            // legs for TrainCard: stops, trainNumber, operator, isDirect
                            final legsForCard = legs.map((leg) {
                              final stops = (leg['stops'] as List<dynamic>).map((stop) {
                                return {
                                  'name': stop['stop_name'] ?? '',
                                  'arrivalTime': stop['arrival_time']?.toString().substring(0,5) ?? '',
                                  'departureTime': stop['departure_time']?.toString().substring(0,5) ?? '',
                                  'platform': stop['platform'] ?? '',
                                  'track': stop['track'] ?? '',
                                  'id': stop['stop_id'] ?? '',
                                };
                              }).toList();
                              return {
                                'stops': stops,
                                'trainNumber': leg['trip_id'] ?? '',
                                'operator': '', // Not present in json
                                'isDirect': isDirect,
                                'userFrom': leg['from'] ?? '',
                                'userTo': leg['to'] ?? '',
                                'originalFriends': leg['friends'] ?? [],
                              };
                            }).toList();
                            // Title: Solution N
                            final title = '${localizations.translate('solution')} $routeIndex';
                            // Use a unique index for expandedCardIndex per event
                            final cardIndex = routeIndex;
                            return TrainCard(
                              title: title,
                              isExpanded: expandedCardIndex == (eventId.hashCode ^ cardIndex),
                              onTap: () {
                                setState(() {
                                  expandedCardIndex = expandedCardIndex == (eventId.hashCode ^ cardIndex)
                                      ? null
                                      : (eventId.hashCode ^ cardIndex);
                                });
                              },
                              departureTime: departureTime,
                              arrivalTime: arrivalTime,
                              isDirect: isDirect,
                              userAvatars: userAvatars,
                              legs: legsForCard,
                            );
                          }).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(thickness: 2, color: Colors.blueGrey),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Text(
                                        'Event: $eventId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(thickness: 2, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                              ResponsiveCardList(
                                cards: trainCards,
                                expandedCardIndex: trainCards.indexWhere((card) =>
                                  (expandedCardIndex == (eventId.hashCode ^ trainCards.indexOf(card)))
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
