import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timelines_plus/timelines_plus.dart';

class TrainCard extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final String departureTime;
  final String arrivalTime;
  final bool isDirect;
  final List<Map<String, String>> userAvatars;
  final List<Map<String, Object>> legs;

  const TrainCard({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.departureTime,
    required this.arrivalTime,
    required this.isDirect,
    required this.userAvatars,
    required this.legs
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.5 * 255).toInt()),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              if (!isExpanded) ...[
                Row(
                  children: [
                    // Icona sinistra
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Icon(
                        isDirect ? Icons.trending_flat : Icons.alt_route,
                        color: isDirect ? Colors.green : Colors.orange,
                        size: 32.0,
                      ),
                    ),
                    // Titolo e orari
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '$departureTime - $arrivalTime',
                            style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    SizedBox(
                      width: (userAvatars.length > 0 ? ((userAvatars.length - 1) * 12.0 + 32.0) : 32.0).clamp(32.0, 80.0),
                      height: 32.0,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < userAvatars.length; i++)
                            Positioned(
                              left: i * 12.0,
                              child: Tooltip(
                                message: userAvatars[i]['name']!,
                                child: GestureDetector(
                                  onLongPress: () {
                                    if (!kIsWeb && (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS)) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          content: Text(userAvatars[i]['name']!),
                                        ),
                                      );
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 16.0,
                                    backgroundImage: AssetImage(userAvatars[i]['image']!),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
              ],
              if (isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10.0),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    const stopWidth = 160.0;
                    bool anyVertical = false;
                    for (final leg in legs) {
                      final stopsRaw = leg['stops'] as List?;
                      final stops = stopsRaw?.map((s) => (s as Map<String, dynamic>).map((k, v) => MapEntry(k as String, v?.toString() ?? ''))).toList() ?? [];
                      final totalWidth = stops.length * stopWidth + (stops.length - 1) * 16.0 + 50.0;
                      if (isMobile || totalWidth > constraints.maxWidth) {
                        anyVertical = true;
                        break;
                      }
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...legs.map((leg) {
                            final stopsRaw = leg['stops'] as List?;
                            final stops = stopsRaw?.map((s) => (s as Map<String, dynamic>).map((k, v) => MapEntry(k as String, v?.toString() ?? ''))).toList() ?? [];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: _LegTimeline(
                                stops: stops,
                                userAvatars: userAvatars,
                                isVertical: anyVertical,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegTimeline extends StatelessWidget {
  final List<Map<String, String>> stops;
  final List<Map<String, String>> userAvatars;
  final bool isVertical;
  const _LegTimeline({required this.stops, required this.userAvatars, required this.isVertical});

  List<Map<String, String>> usersAtStop(String stopId) {
    return userAvatars.where((user) {
      final from = user['from'];
      final to = user['to'];
      if (from == null || to == null || stopId == null) return false;
      return int.tryParse(from) != null && int.tryParse(to) != null &&
        int.parse(from) <= int.parse(stopId) && int.parse(stopId) <= int.parse(to);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcolo la larghezza richiesta dalla timeline orizzontale
        const stopWidth = 160.0;
        final totalWidth = stops.length * stopWidth + (stops.length - 1) * 16.0 + 50.0;
        final shouldBeVertical = isVertical || totalWidth > constraints.maxWidth;
        if (shouldBeVertical) {
          return FixedTimeline.tileBuilder(
            theme: TimelineThemeData(
              nodePosition: 0,
              color: Colors.blue,
              indicatorTheme: const IndicatorThemeData(
                position: 0.5,
                size: 20.0,
              ),
              connectorTheme: const ConnectorThemeData(
                thickness: 4.0,
                color: Colors.blue,
              ),
            ),
            builder: TimelineTileBuilder.connected(
              connectionDirection: ConnectionDirection.before,
              itemCount: stops.length,
              indicatorBuilder: (context, index) => const DotIndicator(color: Colors.blue),
              connectorBuilder: (context, index, type) => SolidLineConnector(color: Colors.blue),
              contentsBuilder: (context, index) {
                final stop = stops[index];
                final users = usersAtStop(stop['id'] ?? '');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (stop['arrivalTime'] != null)
                        Text('Arrivo: ${stop['arrivalTime']!}', style: const TextStyle(color: Colors.grey)),
                      if (users.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: users.map((user) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: AssetImage(user['image'] ?? ''),
                              ),
                              const SizedBox(width: 4),
                              Text(user['name'] ?? '', style: const TextStyle(fontSize: 12)),
                            ],
                          )).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        } else {
          return Container(
            height: 180,
            child: FixedTimeline.tileBuilder(
              direction: Axis.horizontal,
              builder: TimelineTileBuilder.connected(
                connectionDirection: ConnectionDirection.before,
                itemCount: stops.length,
                indicatorBuilder: (context, index) => const DotIndicator(color: Colors.blue),
                connectorBuilder: (context, index, type) => SolidLineConnector(color: Colors.blue),
                contentsBuilder: (context, index) {
                  final stop = stops[index];
                  final users = usersAtStop(stop['id'] ?? '');
                  return Container(
                    width: stopWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(stop['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        if (stop['arrivalTime'] != null)
                          Text('Arrivo: ${stop['arrivalTime']!}', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                        if (users.isNotEmpty)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: users.map((user) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundImage: AssetImage(user['image'] ?? ''),
                                ),
                                const SizedBox(width: 4),
                                Text(user['name'] ?? '', style: const TextStyle(fontSize: 12)),
                              ],
                            )).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}