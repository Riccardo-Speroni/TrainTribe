import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';
import 'widgets/train_card.dart';
import 'widgets/train_card_widgets/responsive_card_list.dart';
import 'utils/train_confirmation.dart';
import 'widgets/legend_dialog.dart';
import 'utils/train_utils.dart';
import 'utils/train_route_utils.dart';

class TrainsPage extends StatefulWidget {
  final bool testMode; // Skip network & Firestore when true
  final TrainConfirmationService? confirmationServiceOverride; // for tests
  final String? testUserId; // for tests when FirebaseAuth not available
  final Map<String, List<dynamic>>? testEventsData; // optional injected events/routes for tests
  const TrainsPage({super.key, this.testMode = false, this.confirmationServiceOverride, this.testUserId, this.testEventsData});

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
  late TrainConfirmationService _confirmationService;
  @visibleForTesting
  set testConfirmationService(TrainConfirmationService svc) => _confirmationService = svc;

  @override
  void initState() {
    super.initState();
    daysOfWeekFull = [];
    daysOfWeekShort = [];
    _confirmationService = widget.confirmationServiceOverride ?? TrainConfirmationService();
    if (!widget.testMode) {
      _loadData();
    } else {
      isLoading = false;
      eventsData = widget.testEventsData ?? {
        'event1': [
          {
            'leg1': {
              'trip_id': 'T1',
              'from': 'S1',
              'to': 'S2',
              'stops': [
                {'stop_id': 'S1', 'departure_time': '08:00:00'},
                {'stop_id': 'S2', 'arrival_time': '09:00:00'}
              ],
              'friends': []
            }
          }
        ]
      };
    }
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
    if (widget.testMode) return; // testMode provides stub data in initState
    if (!mounted) return;
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final now = DateTime.now().add(Duration(days: selectedDayIndex));
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    Map<String, Map<String, dynamic>> details = {};

    try {
      // 1. Fetch routes (eventsData)
      final url = Uri.parse('https://get-event-full-trip-data-v75np53hva-uc.a.run.app?date=$dateStr&userId=$userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        eventsData = (json.decode(response.body) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as List<dynamic>));
      } else if (response.statusCode == 404) {
        eventsData = null; // none
      } else {
        throw Exception('Failed to load trips data (${response.statusCode})');
      }

      // 2. Fetch event details (origin/destination/times)
      if (eventsData != null && eventsData!.isNotEmpty && userId.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        final eventIds = eventsData!.keys.toList();
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
          } catch (_) {/* ignore per-event errors */}
        }));
      }

      // 3. Preload confirmed route signatures
      if (eventsData != null && userId.isNotEmpty) {
        final Map<String, String?> preloadMap = {};
        for (final entry in eventsData!.entries) {
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
          final confirmedIds = await _confirmationService.fetchConfirmedTrainIds(
            dateStr: dateStr,
            userId: userId,
            trainIds: allEventTrainIds.toList(),
          );
          for (final routeIds in routeTrainIdLists) {
            if (routeIds.every(confirmedIds.contains)) {
              preloadMap[eventId] = _routeSignature(routeIds);
              break; // one per event
            }
          }
        }
        if (preloadMap.isNotEmpty && mounted) {
          setState(() => confirmedTrainPerEvent.addAll(preloadMap));
        }
      }
    } catch (e, st) {
      debugPrint('Load data error: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) {
        setState(() {
          eventDetails = details;
          isLoading = false;
        });
      }
    }
  }

  // Deprecated internal version kept for backward compatibility; use routeSignature().
  String _routeSignature(List<String> ids) => routeSignature(ids);

  bool _shouldUseShortDayLabels(BuildContext context, double totalWidth) => shouldUseShortDayLabels(totalWidth);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // Dynamic abbreviation handled later via LayoutBuilder (no need for screen width heuristic here).
    return SelectionContainer.disabled(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent, // remove Material3 scroll tint
          title: SelectionContainer.disabled(child: Text(localizations.translate('trains'))),
          actions: [
            IconButton(
              tooltip: localizations.translate('train_confirm_legend_title'),
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showLegendDialog(
                  context: context,
                  title: localizations.translate('train_confirm_legend_title'),
                  okLabel: localizations.translate('ok'),
                  infoText: localizations.translate('train_confirm_info'),
                  items: [
                    LegendItem(
                      ringColor: Colors.green,
                      glowColor: Colors.greenAccent,
                      label: localizations.translate('train_confirm_legend_you'),
                      isUser: true,
                    ),
                    LegendItem(
                      ringColor: Colors.amber,
                      glowColor: Colors.amberAccent,
                      label: localizations.translate('train_confirm_legend_friend'),
                      showCheck: true,
                    ),
                    LegendItem(
                      ringColor: Colors.grey,
                      glowColor: Colors.transparent,
                      label: localizations.translate('train_confirm_legend_unconfirmed'),
                      backgroundColor: Colors.grey,
                      iconColor: Colors.white,
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Builder(builder: (context) {
              final theme = Theme.of(context);
              final selColor = theme.colorScheme.primary;
              final unselectedText =
                  theme.brightness == Brightness.dark ? theme.colorScheme.onSurface.withValues(alpha: 0.60) : Colors.black87;
              return LayoutBuilder(builder: (ctx, constraints) {
                final useShort = _shouldUseShortDayLabels(ctx, constraints.maxWidth);
                final labels = useShort ? daysOfWeekShort : daysOfWeekFull;
                return SelectionContainer.disabled(
                  child: Row(
                    children: List.generate(labels.length, (index) {
                      final selected = selectedDayIndex == index;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selectedDayIndex = index);
                              _loadData();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              decoration: BoxDecoration(
                                color: selected
                                    ? selColor
                                    : (theme.brightness == Brightness.dark
                                        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: selected
                                      ? selColor
                                      : (theme.brightness == Brightness.dark
                                          ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
                                          : Colors.grey.withValues(alpha: 0.3)),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  labels[index],
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected ? theme.colorScheme.onPrimary : unselectedText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              });
            }),
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

                              // Collect ordered legs via utility
                              final legs = extractLegs(route);

                              // Gather route trainIds (all legs).
                              final List<String> routeTrainIds = [
                                for (final l in legs)
                                  if (l['trip_id'] != null) l['trip_id'].toString()
                              ];

                              // Merge friend avatars across legs:
                              final userAvatars = mergeFriendAvatars(legs);

                              // Departure/arrival time: time the user boards/alights (match stop_id with 'from'/'to')
                              final times = computeDepartureArrivalTimes(legs);
                              final departureTime = times['departure'] ?? '';
                              final arrivalTime = times['arrival'] ?? '';
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
                              // Multi-leg confirmation: route considered confirmed only if ALL its leg trainIds confirmed.
                              final routeSignature = _routeSignature(routeTrainIds);
                              final isConfirmed = confirmedTrainPerEvent[eventId] == routeSignature;
                              final currentUserId =
                                  widget.testMode ? (widget.testUserId ?? 'test-user') : FirebaseAuth.instance.currentUser?.uid;
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
                                trailing: _buildConfirmButton(
                                    eventId: eventId,
                                    routeSignature: routeSignature,
                                    routeTrainIds: routeTrainIds,
                                    dateStr: dateStr,
                                    routes: routes),
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
                                            final endStr =
                                                DateFormat.Hm(localizations.languageCode()).format(details['event_end'].toDate());

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
      ),
    );
  }

  Widget _buildConfirmButton({
    required String eventId,
    required String routeSignature,
    required List<String> routeTrainIds,
    required String dateStr,
    required dynamic routes,
  }) {
    final loc = AppLocalizations.of(context);
    final confirmed = confirmedTrainPerEvent[eventId] == routeSignature;
    final theme = Theme.of(context);
    final label = confirmed ? loc.translate('confirmed') : loc.translate('confirm');

    MaterialColor baseSwatch = Colors.green;
    final Color basePrimary = baseSwatch;
    final bool dark = theme.brightness == Brightness.dark;

    // Revert to earlier solid confirmed style (no glow later handled in widget).
    final Color bg = confirmed ? basePrimary : (dark ? basePrimary.withValues(alpha: 0.18) : basePrimary.withValues(alpha: 0.12));
    final Color border = confirmed ? baseSwatch[700]! : (dark ? basePrimary.withValues(alpha: 0.45) : basePrimary.withValues(alpha: 0.55));
    final Color fg = confirmed ? Colors.white : (dark ? basePrimary.withValues(alpha: 0.95) : baseSwatch[800]!);

    return _ConfirmButton(
      key: ValueKey('confirmBtn_${eventId}_$routeSignature'),
      label: label,
      confirmed: confirmed,
      bg: bg,
      border: border,
      fg: fg,
      onTap: () async {
        final String? userId = widget.testMode ? (widget.testUserId ?? 'test-user') : FirebaseAuth.instance.currentUser?.uid;
        if (userId == null || userId.isEmpty) return;
        final Set<String> allTrainIds = {};
        if (routes is List) {
          for (final r in routes) {
            if (r is Map<String, dynamic>) {
              final legKeys = r.keys.where((k) => k.startsWith('leg'));
              for (final lk in legKeys) {
                final leg = r[lk];
                if (leg is Map && leg['trip_id'] != null) {
                  allTrainIds.add(leg['trip_id'].toString());
                }
              }
            }
          }
        }
        try {
          await _confirmationService.confirmRoute(
            dateStr: dateStr,
            selectedRouteTrainIds: routeTrainIds,
            userId: userId,
            allEventTrainIds: allTrainIds.toList(),
          );
          if (mounted) setState(() => confirmedTrainPerEvent[eventId] = routeSignature);
        } catch (e, st) {
          debugPrint('Confirm button error event=$eventId route=$routeSignature: $e');
          debugPrint(st.toString());
        }
      },
    );
  }
}

// Reusable animated confirm button widget

// Reusable animated confirm button widget (top-level)
class _ConfirmButton extends StatefulWidget {
  final String label;
  final bool confirmed;
  final Color bg;
  final Color border;
  final Color fg;
  final VoidCallback onTap;
  const _ConfirmButton({
    super.key,
    required this.label,
    required this.confirmed,
    required this.bg,
    required this.border,
    required this.fg,
    required this.onTap,
  });

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Elevation only for unconfirmed hover (confirmed flat, no glow).
    final elevation = widget.confirmed ? 0.0 : (_pressed ? 0.0 : (_hover ? 2.0 : 0.0));
    final scale = _pressed ? 0.97 : (_hover ? 1.01 : 1.0);
    final Color bg = widget.confirmed ? widget.bg : Color.lerp(widget.bg, widget.border, _hover ? 0.12 : 0.0)!;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(scale),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.border, width: 1.1),
            boxShadow: [
              if (!widget.confirmed && elevation > 0)
                BoxShadow(
                  color: widget.border.withValues(alpha: dark ? 0.30 : 0.22),
                  blurRadius: 6 + elevation * 2,
                  spreadRadius: 0.3,
                  offset: Offset(0, elevation),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              style: TextStyle(
                color: widget.fg,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                letterSpacing: 0.3,
              ),
              child: Text(
                widget.label,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Legend dialog extracted to widgets/legend_dialog.dart
