import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../utils/profile_picture_widget.dart';

class TrainCard extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final String departureTime;
  final String arrivalTime;
  final bool isDirect;
  final List<Map<String, String>> userAvatars;
  final List<Map<String, dynamic>> legs;

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
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Icon(
                        isDirect ? Icons.trending_flat : Icons.alt_route,
                        color: isDirect ? Colors.green : Colors.orange,
                        size: 32.0,
                      ),
                    ),
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
                      width: (userAvatars.isNotEmpty ? ((userAvatars.length - 1) * 12.0 + 32.0) : 32.0).clamp(32.0, 80.0),
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
                                  child: ProfilePicture(
                                    picture: userAvatars[i]['image'],
                                    size: 16.0,
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
                      final stops = stopsRaw?.map((s) => (s as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''))).toList() ?? [];
                      final totalWidth = stops.length * stopWidth + (stops.length - 1) * 16.0 + 50.0;
                      if (isMobile || totalWidth > constraints.maxWidth) {
                        anyVertical = true;
                        break;
                      }
                    }
                    List<List<Map<String, String>>> friendsPerLeg = [];
                    for (int i = 0; i < legs.length; i++) {
                      final leg = legs[i];
                      // Try to get the original friends for this leg from the original JSON structure
                      // If not present, fallback to userAvatars filtered by from/to in this leg's stops
                      List<Map<String, String>> friendsForLeg = [];
                      if (leg.containsKey('originalFriends')) {
                        friendsForLeg = (leg['originalFriends'] as List)
                            .map<Map<String, String>>((friend) => {
                                  'image': (friend['picture'] ?? '').toString(),
                                  'name': (friend['username'] ?? '').toString(),
                                  'from': (friend['from'] ?? '').toString(),
                                  'to': (friend['to'] ?? '').toString(),
                                })
                            .toList();
                      } else {
                        final stopsRaw = leg['stops'] as List?;
                        final stops = stopsRaw?.map((s) => (s as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''))).toList() ?? [];
                        final stopIds = stops.map((s) => s['id'] ?? '').toList();
                        friendsForLeg = userAvatars.where((user) {
                          final from = user['from'];
                          final to = user['to'];
                          if (from == null || to == null) return false;
                          final fromIdx = stopIds.indexOf(from);
                          final toIdx = stopIds.indexOf(to);
                          return fromIdx != -1 && toIdx != -1;
                        }).toList();
                      }
                      friendsPerLeg.add(friendsForLeg);
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...legs.asMap().entries.map((entry) {
                            final i = entry.key;
                            final leg = entry.value;
                            final stopsRaw = leg['stops'] as List?;
                            final stops = stopsRaw?.map((s) => (s as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''))).toList() ?? [];
                            final stopIds = stops.map((s) => s['id'] ?? '').toList();
                            final userFrom = leg['userFrom'] as String? ?? '';
                            final userTo = leg['userTo'] as String? ?? '';
                            final friendsForLeg = friendsPerLeg[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: _LegTimeline(
                                stops: stops,
                                userAvatars: friendsForLeg,
                                stopIds: stopIds,
                                isVertical: anyVertical,
                                userFrom: userFrom,
                                userTo: userTo,
                              ),
                            );
                          }),
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
  final List<String> stopIds;
  final bool isVertical;
  final String userFrom;
  final String userTo;
  const _LegTimeline({
    required this.stops,
    required this.userAvatars,
    required this.stopIds,
    required this.isVertical,
    required this.userFrom,
    required this.userTo,
  });

  List<Map<String, String>> usersAtStop(String stopId) {
    final idx = stopIds.indexOf(stopId);
    if (idx == -1) return [];
    return userAvatars.where((user) {
      final from = user['from'];
      final to = user['to'];
      if (from == null || to == null) return false;
      final fromIdx = stopIds.indexOf(from);
      final toIdx = stopIds.indexOf(to);
      if (fromIdx == -1 || toIdx == -1) return false;
      return fromIdx <= idx && idx <= toIdx;
    }).toList();
  }

  bool isStopInUserSegment(String stopId) {
    if (userFrom.isEmpty || userTo.isEmpty) return false;
    final idx = stopIds.indexOf(stopId);
    final fromIdx = stopIds.indexOf(userFrom);
    final toIdx = stopIds.indexOf(userTo);
    if (idx == -1 || fromIdx == -1 || toIdx == -1) return false;
    return fromIdx <= idx && idx <= toIdx;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const stopWidth = 160.0;
        final totalWidth = stops.length * stopWidth + (stops.length - 1) * 16.0 + 50.0;
        final shouldBeVertical = isVertical || totalWidth > constraints.maxWidth;

        IconData? stopIconData(String stopId) {
          if (userFrom.isNotEmpty && stopId == userFrom) {
            return MdiIcons.stairsUp;
          }
          if (userTo.isNotEmpty && stopId == userTo) {
            return MdiIcons.stairsDown;
          }
          return null;
        }

        // Get the indices for the user's segment
        final fromIdx = userFrom.isNotEmpty ? stopIds.indexOf(userFrom) : -1;
        final toIdx = userTo.isNotEmpty ? stopIds.indexOf(userTo) : -1;

        // Build dot with color depending on user segment
        Widget buildDot(int idx, String stopId) {
          final iconData = stopIconData(stopId);
          final isInUser = (fromIdx != -1 && toIdx != -1 && idx >= fromIdx && idx <= toIdx);
          final dotColor = isInUser
              ? Colors.blue
              : Colors.grey.withValues(alpha: 0.6);
          if (iconData != null) {
            final isUnboarding = userTo.isNotEmpty && stopId == userTo;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: isUnboarding
                          ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0))
                          : Matrix4.identity(),
                      child: Icon(
                        iconData,
                        color: const Color.fromARGB(230, 255, 255, 255),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            );
          }
        }

        // Build connector with color depending on user segment
        Color connectorColor(int idx) {
          // Connector is between stop[idx] and stop[idx+1]
          if (fromIdx == -1 || toIdx == -1) return Colors.grey.withValues(alpha: 0.6);
          // Blue if the segment [idx, idx+1] is fully inside (fromIdx, toIdx]
          if (idx > fromIdx && idx <= toIdx) return Colors.blue;
          return Colors.grey.withValues(alpha: 0.6);
        }

        if (shouldBeVertical) {
          return FixedTimeline.tileBuilder(
            theme: TimelineThemeData(
              nodePosition: 0,
              color: Colors.blue,
              indicatorTheme: const IndicatorThemeData(
                position: 0.5,
                size: 24.0,
              ),
              connectorTheme: const ConnectorThemeData(
                thickness: 4.0,
                color: Colors.blue,
              ),
            ),
            builder: TimelineTileBuilder.connected(
              connectionDirection: ConnectionDirection.before,
              itemCount: stops.length,
              indicatorBuilder: (context, index) {
                final stop = stops[index];
                return buildDot(index, stop['id'] ?? '');
              },
              connectorBuilder: (context, index, type) =>
                  SolidLineConnector(color: connectorColor(index)),
              contentsBuilder: (context, index) {
                final stop = stops[index];
                final users = usersAtStop(stop['id'] ?? '');
                final isInUser = (fromIdx != -1 && toIdx != -1 && index >= fromIdx && index <= toIdx);
                final textStyle = isInUser
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14, overflow: TextOverflow.ellipsis);
                final arrivalStyle = isInUser
                    ? const TextStyle(color: Colors.grey)
                    : TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 12);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop['name'] ?? '', style: textStyle),
                      if (stop['arrivalTime'] != null)
                        Text('Arrivo: ${stop['arrivalTime']!}', style: arrivalStyle),
                      if (users.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 8,
                            children: users.map((user) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ProfilePicture(
                                  picture: user['image'],
                                  size: 10.0,
                                ),
                                const SizedBox(width: 4),
                                Text(user['name'] ?? '', style: const TextStyle(fontSize: 12)),
                              ],
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        } else {
          return SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedTimeline.tileBuilder(
                  direction: Axis.horizontal,
                  builder: TimelineTileBuilder.connected(
                    connectionDirection: ConnectionDirection.before,
                    itemCount: stops.length,
                    indicatorBuilder: (context, index) {
                      final stop = stops[index];
                      return buildDot(index, stop['id'] ?? '');
                    },
                    connectorBuilder: (context, index, type) =>
                        SolidLineConnector(color: connectorColor(index)),
                    contentsBuilder: (context, index) {
                      final stop = stops[index];
                      final users = usersAtStop(stop['id'] ?? '');
                      final isInUser = (fromIdx != -1 && toIdx != -1 && index >= fromIdx && index <= toIdx);
                      final textStyle = isInUser
                          ? const TextStyle(fontWeight: FontWeight.bold)
                          : const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14, overflow: TextOverflow.ellipsis);
                      final arrivalStyle = isInUser
                          ? const TextStyle(color: Colors.grey, fontSize: 12)
                          : TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 12);
                      return Container(
                        width: stopWidth,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(stop['name'] ?? '', style: textStyle, textAlign: TextAlign.center),
                            if (stop['arrivalTime'] != null)
                              Text('Arrivo: ${stop['arrivalTime']!}', style: arrivalStyle, textAlign: TextAlign.center),
                            if (users.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  children: users.map((user) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ProfilePicture(
                                        picture: user['image'],
                                        size: 10.0,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(user['name'] ?? '', style: const TextStyle(fontSize: 12)),
                                    ],
                                  )).toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}