import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';
import 'widgets/train_card.dart';
import 'widgets/responsive_card_list.dart';
import 'utils/train_confirmation.dart';

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
  // Cached details for events: origin, destination, event_start, event_end
  Map<String, Map<String, dynamic>> eventDetails = {};
  // Now stores a route signature (all leg trainIds joined by '+') per event.
  final Map<String, String?> confirmedTrainPerEvent = {}; // eventId -> routeSignature
  final TrainConfirmationService _confirmationService = TrainConfirmationService();

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
    if (mounted) {
      setState(() {
        daysOfWeekFull = List.generate(7, (index) {
          final now = DateTime.now();
          final day = now.add(Duration(days: index));
          return toBeginningOfSentenceCase(DateFormat.EEEE(localizations.languageCode()).format(day))!;
        });

        daysOfWeekShort = List.generate(7, (index) {
          final now = DateTime.now();
          final day = now.add(Duration(days: index));
          return toBeginningOfSentenceCase(DateFormat.E(localizations.languageCode()).format(day))!;
        });
      });
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

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
    } else if (response.statusCode == 404) {
      eventsData = null; // No trips found
    } else {
      throw Exception('Failed to load trips data');
    }
    // Fetch event details from Firestore for each eventId if available
    final Map<String, Map<String, dynamic>> details = {};
    if (eventsData != null && eventsData!.isNotEmpty && userId.isNotEmpty) {
      final firestore = FirebaseFirestore.instance;
      final eventIds = eventsData!.keys.toList();
      try {
        await Future.wait(eventIds.map((eventId) async {
          try {
            final doc = await firestore.collection('users').doc(userId).collection('events').doc(eventId).get();
            if (doc.exists) {
              final data = doc.data();
              if (data != null) {
                details[eventId] = {
                  'origin': data['origin'],
                  'destination': data['destination'],
                  'event_start': data['event_start'],
                  'event_end': data['event_end'],
                };
              }
            }
          } catch (_) {
            // Ignore individual fetch errors, keep rendering others
          }
        }));
      } catch (_) {
        // Ignore batch errors
      }
    }

    if (mounted) {
      setState(() {
        eventDetails = details;
        isLoading = false;
      });
    }

    // Preload confirmed route per event.
    if (eventsData != null && userId.isNotEmpty) {
      final Map<String, String?> preloadMap = {};
      final dateStrForPreload = dateStr;
      try {
        for (final entry in eventsData!.entries) {
          final eventId = entry.key;
          final routes = entry.value;
          // Collect all trainIds across all routes (every leg).
          final Set<String> allEventTrainIds = {};
          // Build list of route trainId lists.
          final List<List<String>> routeTrainIdLists = [];

          for (final r in routes) {
            if (r is Map<String, dynamic>) {
              final List<String> routeTrainIds = [];
              // collect legX
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
              if (routeTrainIds.isNotEmpty) {
                routeTrainIdLists.add(routeTrainIds);
              }
            }
          }

          // Fetch all confirmed trainIds for this event's trains.
          final confirmedIds = await _confirmationService.fetchConfirmedTrainIds(
            dateStr: dateStrForPreload,
            userId: userId,
            trainIds: allEventTrainIds.toList(),
          );

          // Determine if any route is fully confirmed (all its leg ids in confirmedIds).
          for (final routeIds in routeTrainIdLists) {
            final full = routeIds.every(confirmedIds.contains);
            if (full) {
              preloadMap[eventId] = _routeSignature(routeIds);
              break; // Only one route can be confirmed.
            }
          }
        }
        if (mounted) {
          setState(() {
            confirmedTrainPerEvent.addAll(preloadMap);
          });
        }
      } catch (e, st) {
        debugPrint('Preload confirmations (multi-leg) error: $e');
        debugPrint(st.toString());
      }
    }
  }

  String _routeSignature(List<String> ids) => ids.join('+');

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showFullDays = screenWidth > 600;
    final daysOfWeek = showFullDays ? daysOfWeekFull : daysOfWeekShort;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('trains')),
        actions: [
          IconButton(
            tooltip: localizations.translate('train_confirm_legend_title'),
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegendDialog(context, localizations),
          ),
        ],
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
          : RefreshIndicator(
              onRefresh: _loadData,
              displacement: 24,
              child: eventsData == null
                  // Even if no data, keep a scrollable list so pull-to-refresh works
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text(localizations.translate('no_trains_found'))),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        ...eventsData!.entries.map((eventEntry) {
                          final eventId = eventEntry.key;
                          final routes = eventEntry.value;
                          // Build the list of TrainCards for this event
                          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: selectedDayIndex)));
                          final trainCards = routes.asMap().entries.map((routeEntry) {
                            final routeIndex = routeEntry.key;
                            final route = routeEntry.value as Map<String, dynamic>;

                            // Collect legs
                            final legs = <Map<String, dynamic>>[];
                            final legKeys = route.keys.where((k) => k.startsWith('leg')).toList()
                              ..sort((a, b) {
                                int ai = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                int bi = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                return ai.compareTo(bi);
                              });
                            for (final k in legKeys) {
                              legs.add(Map<String, dynamic>.from(route[k] as Map));
                            }

                            // Gather route trainIds (all legs).
                            final List<String> routeTrainIds = [
                              for (final l in legs)
                                if (l['trip_id'] != null) l['trip_id'].toString()
                            ];
                            final routeSignature = _routeSignature(routeTrainIds);

                            // Merge friend avatars across legs:
                            final Map<String, Map<String, String>> userAvatarsMap = {};
                            for (final leg in legs) {
                              if (leg['friends'] != null) {
                                for (final friend in (leg['friends'] as List)) {
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
                                      // Start with this leg's confirmed value; we will AND across legs they appear in.
                                      'confirmed': legConfirmed ? 'true' : 'false',
                                      'user_id': friendUserId,
                                    };
                                  } else {
                                    // Merge range
                                    final prev = userAvatarsMap[key]!;
                                    final prevFrom = prev['from'] ?? from;
                                    final prevTo = prev['to'] ?? to;
                                    prev['from'] = (from.compareTo(prevFrom) < 0) ? from : prevFrom;
                                    prev['to'] = (to.compareTo(prevTo) > 0) ? to : prevTo;
                                    // AND logic: friend considered route-confirmed only if confirmed in every leg they appear.
                                    final prevConfirmed = prev['confirmed'] == 'true';
                                    prev['confirmed'] = (prevConfirmed && legConfirmed).toString();
                                  }
                                }
                              }
                            }
                            final userAvatars = userAvatarsMap.values.toList();

                            // Departure/arrival time: time the user boards/alights (match stop_id with 'from'/'to')
                            String departureTime = '';
                            String arrivalTime = '';
                            String _toHHmm(dynamic t) {
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
                                final Map<String, dynamic> boardStop = (firstStops.firstWhere(
                                  (s) => ((s as Map)['stop_id'] ?? '').toString() == firstFromId,
                                  orElse: () => firstStops.first,
                                )) as Map<String, dynamic>;
                                departureTime = _toHHmm(boardStop['departure_time'] ?? boardStop['arrival_time']);
                              }
                              if (lastStops.isNotEmpty) {
                                final Map<String, dynamic> alightStop = (lastStops.firstWhere(
                                  (s) => ((s as Map)['stop_id'] ?? '').toString() == lastToId,
                                  orElse: () => lastStops.last,
                                )) as Map<String, dynamic>;
                                arrivalTime = _toHHmm(alightStop['arrival_time'] ?? alightStop['departure_time']);
                              }
                            }
                            // isDirect: only one leg
                            final isDirect = legs.length == 1;
                            // legs for TrainCard: stops, trainNumber, operator, isDirect
                            final legsForCard = legs.map((leg) {
                              final stops = (leg['stops'] as List<dynamic>).map((stop) {
                                return {
                                  'name': stop['stop_name'] ?? '',
                                  'arrivalTime': stop['arrival_time']?.toString().substring(0, 5) ?? '',
                                  'departureTime': stop['departure_time']?.toString().substring(0, 5) ?? '',
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
                                'originalFriends': (leg['friends'] as List?)?.map((f) {
                                      final m = Map<String, dynamic>.from(f as Map);
                                      m['confirmed'] = (m['confirmed'] == true);
                                      return m;
                                    }).toList() ??
                                    [],
                              };
                            }).toList();
                            // Title: Solution N
                            final title = '${localizations.translate('solution')} $routeIndex';
                            // Use a unique index for expandedCardIndex per event
                            final cardIndex = routeIndex;
                            final trainId =
                                legsForCard.isNotEmpty ? (legsForCard.first['trainNumber']?.toString() ?? 'unknown') : 'unknown';
                            final isConfirmed = confirmedTrainPerEvent[eventId] == trainId;
                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            return TrainCard(
                              title: title,
                              isExpanded: expandedCardIndex == (eventId.hashCode ^ cardIndex),
                              onTap: () {
                                setState(() {
                                  expandedCardIndex =
                                      expandedCardIndex == (eventId.hashCode ^ cardIndex) ? null : (eventId.hashCode ^ cardIndex);
                                });
                              },
                              departureTime: departureTime,
                              arrivalTime: arrivalTime,
                              isDirect: isDirect,
                              userAvatars: userAvatars,
                              legs: legsForCard,
                              trailing: _buildConfirmButton(eventId, trainId, dateStr, routes),
                              highlightConfirmed: isConfirmed,
                              currentUserId: currentUserId,
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
                                      child: Builder(builder: (_) {
                                        final details = eventDetails[eventId];
                                        String stationsText = 'Event';
                                        String timesText = '';
                                        if (details != null) {
                                          final origin = (details['origin'] ?? '').toString();
                                          final destination = (details['destination'] ?? '').toString();
                                          final startStr =
                                              DateFormat.Hm(localizations.languageCode()).format(details['event_start'].toDate());
                                          final endStr = DateFormat.Hm(localizations.languageCode()).format(details['event_end'].toDate());

                                          if (origin.isNotEmpty || destination.isNotEmpty) {
                                            stationsText = [origin, destination].where((s) => s.isNotEmpty).join(' → ');
                                          }
                                          if (startStr.isNotEmpty || endStr.isNotEmpty) {
                                            timesText = [startStr, endStr].where((s) => s.isNotEmpty).join(' - ');
                                          }
                                        }

                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              stationsText,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (timesText.isNotEmpty)
                                              Text(
                                                timesText,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                          ],
                                        );
                                      }),
                                    ),
                                    Expanded(
                                      child: Divider(thickness: 2, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                              ResponsiveCardList(
                                cards: trainCards,
                                expandedCardIndex:
                                    trainCards.indexWhere((card) => (expandedCardIndex == (eventId.hashCode ^ trainCards.indexOf(card)))),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
    );
  }

  Widget _buildConfirmButton(String eventId, String trainId, String dateStr, dynamic routes) {
    final isConfirmed = confirmedTrainPerEvent[eventId] == trainId;
    final loc = AppLocalizations.of(context);
    final confirmLabel = isConfirmed ? loc.translate('confirmed') : loc.translate('confirm');
    return ElevatedButton(
      onPressed: () async {
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid;
        if (userId == null) return;
        // Build list of trainIds for this event's routes
        final List<String> trainIds = [];
        if (routes is List) {
          for (final r in routes) {
            if (r is Map<String, dynamic>) {
              final leg0 = r['leg0'];
              if (leg0 is Map && leg0['trip_id'] != null) {
                trainIds.add(leg0['trip_id'].toString());
              }
            }
          }
        }
        try {
          await _confirmationService.confirmTrain(
            dateStr: dateStr,
            trainId: trainId,
            userId: userId,
            eventTrainIds: trainIds,
          );
          if (mounted) {
            setState(() {
              confirmedTrainPerEvent[eventId] = trainId;
            });
          }
        } catch (e, st) {
          debugPrint('Confirm button error event=$eventId train=$trainId: $e');
          debugPrint(st.toString());
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isConfirmed ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(confirmLabel),
    );
  }

  void _showLegendDialog(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.translate('train_confirm_legend_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendRow(
                ringColor: Colors.green,
                glow: Colors.greenAccent,
                label: loc.translate('train_confirm_legend_you'),
                isUser: true,
              ),
              const SizedBox(height: 10),
              _legendRow(
                ringColor: Colors.amber,
                glow: Colors.amberAccent,
                label: loc.translate('train_confirm_legend_friend'),
                showCheck: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const CircleAvatar(radius: 12, backgroundColor: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(child: Text(loc.translate('train_confirm_legend_unconfirmed'))),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                loc.translate('train_confirm_info'),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.translate('ok')),
            )
          ],
        );
      },
    );
  }

  Widget _legendRow({required Color ringColor, required Color glow, required String label, bool showCheck = false, bool isUser = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: isUser ? 3 : 2),
                boxShadow: [
                  BoxShadow(color: glow.withOpacity(0.6), blurRadius: 6, spreadRadius: 1),
                ],
                color: Colors.white,
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
            if (showCheck)
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ringColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: ringColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 0.5),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 9, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }
}
