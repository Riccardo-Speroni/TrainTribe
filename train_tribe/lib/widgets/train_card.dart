import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../utils/profile_picture_widget.dart';
// Removed avatar tooltips dependence on localizations

class TrainCard extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final String departureTime;
  final String arrivalTime;
  final bool isDirect;
  final List<Map<String, String>> userAvatars;
  final List<Map<String, dynamic>> legs;
  final Widget? trailing; // For confirm button
  final bool highlightConfirmed; // Visual highlight if confirmed
  final String? currentUserId; // to style own confirmation vs friends

  const TrainCard({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.departureTime,
    required this.arrivalTime,
    required this.isDirect,
    required this.userAvatars,
    required this.legs,
    this.trailing,
    this.highlightConfirmed = false,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool userConfirmed = highlightConfirmed; // highlightConfirmed represents current user's confirmation
    final baseBorderColor =
        theme.brightness == Brightness.dark ? theme.colorScheme.outlineVariant.withOpacity(0.4) : Colors.grey.withOpacity(0.15);
    final borderColor =
        userConfirmed ? (theme.colorScheme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.green) : baseBorderColor;
    final gradient = userConfirmed
        ? LinearGradient(
            colors: theme.colorScheme.brightness == Brightness.dark
                ? [theme.colorScheme.primary.withOpacity(0.15), theme.colorScheme.primary.withOpacity(0.05)]
                : [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    return _Hoverable(
      builder: (hovering) {
        final hoverElevation = hovering ? 0.09 : 0.0;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: hovering ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: borderColor, width: 1.6),
              boxShadow: [
                if (theme.brightness == Brightness.light)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06 + hoverElevation),
                    blurRadius: 14 + (hovering ? 4 : 0),
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(hovering ? 0.12 : 0.07),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isExpanded) _buildCollapsed(context) else _buildExpanded(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isTight = constraints.maxWidth < 560; // widen threshold to reduce single-row crowding
      final titleChip = _solutionChip(context);
      final timeText = Flexible(
        child: Text(
          '$departureTime – $arrivalTime',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      );

      final icon = Icon(
        isDirect ? Icons.trending_flat : Icons.alt_route,
        color: isDirect ? Colors.green : Colors.orange,
        size: 22.0,
      );

      final avatars = _buildAvatars();
      final confirmBtn = trailing != null
          ? ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96, maxWidth: 130),
              child: trailing!,
            )
          : const SizedBox();

      if (!isTight) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left flexible group
            Expanded(
              flex: 6,
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 10),
                  titleChip,
                  const SizedBox(width: 14),
                  timeText,
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Avatars shrink if needed
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: avatars,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: confirmBtn,
              ),
            ),
          ],
        );
      }

      // Compact / narrow: multi-line layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              titleChip,
              const SizedBox(width: 10),
              Expanded(child: timeText),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: avatars),
              const SizedBox(width: 12),
              confirmBtn,
            ],
          ),
        ],
      );
    });
  }

  Widget _solutionChip(BuildContext context) {
    final theme = Theme.of(context);
    final confirmed = highlightConfirmed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: confirmed
            ? (theme.brightness == Brightness.dark ? theme.colorScheme.primary.withOpacity(0.25) : Colors.green.withOpacity(0.15))
            : theme.colorScheme.secondaryContainer.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.5),
      ),
      child: Text(
        title, // full title preserved
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: confirmed
              ? (theme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.green.shade800)
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildAvatars() {
    return SizedBox(
      width: (userAvatars.isNotEmpty ? ((userAvatars.length - 1) * 14.0 + 34.0) : 34.0).clamp(34.0, 120.0),
      height: 32.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < userAvatars.length; i++)
            Positioned(
              left: i * 14.0,
              child: _confirmedAvatarWrapper(userAvatars[i],
                  child: ProfilePicture(
                    picture: userAvatars[i]['image'],
                    size: 16.0,
                  )),
            ),
        ],
      ),
    );
  }
  // Removed tooltip + cached context.

  Widget _confirmedAvatarWrapper(Map<String, String> friend, {required Widget child}) {
    final isConfirmed = (friend['confirmed'] == 'true');
    if (!isConfirmed) return child;
    final isUser = currentUserId != null && friend['user_id'] == currentUserId;
    final borderColor = isUser ? Colors.green : Colors.amber;
    final glowColor = isUser ? Colors.greenAccent : Colors.amberAccent;

    // User: keep current ring + glow (green).
    if (isUser) {
      return Builder(builder: (context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              if (!dark) BoxShadow(color: glowColor.withOpacity(0.45), blurRadius: 5, spreadRadius: 0.6),
              if (dark) BoxShadow(color: borderColor.withOpacity(0.22), blurRadius: 3, spreadRadius: 0.3),
            ],
          ),
          child: child,
        );
      });
    }

    // Friend: add a distinct badge with a checkmark to avoid relying only on amber ring (which may blend with avatar colors).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Builder(builder: (context) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                if (!dark) BoxShadow(color: glowColor.withOpacity(0.42), blurRadius: 4, spreadRadius: 0.6),
                if (dark) BoxShadow(color: borderColor.withOpacity(0.18), blurRadius: 2.5, spreadRadius: 0.25),
              ],
            ),
            child: child,
          );
        }),
        Positioned(
          bottom: -3,
          right: -3,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: borderColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(color: borderColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 0.5),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check, size: 8, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$departureTime - $arrivalTime',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ],
              ),
            ),
            _buildAvatars(),
            if (trailing != null) Padding(padding: const EdgeInsets.only(left: 8.0), child: trailing!),
          ],
        ),
        const SizedBox(height: 12),
        _buildLegsTimeline(),
      ],
    );
  }

  Widget _buildLegsTimeline() {
    const stopWidth = 160.0;
    bool anyVertical = false;
    for (final leg in legs) {
      final stopsRaw = leg['stops'] as List?;
      final stops = stopsRaw?.map((s) => (s as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''))).toList() ?? [];
      final totalWidth = stops.length * stopWidth + (stops.length - 1) * 16.0 + 50.0;
      if (totalWidth > 600) {
        // rough heuristic
        anyVertical = true;
        break;
      }
    }

    List<List<Map<String, String>>> friendsPerLeg = [];
    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i];
      List<Map<String, String>> friendsForLeg = [];
      if (leg.containsKey('originalFriends')) {
        friendsForLeg = (leg['originalFriends'] as List)
            .map<Map<String, String>>((friend) => {
                  'image': (friend['picture'] ?? '').toString(),
                  'name': (friend['username'] ?? '').toString(),
                  'from': (friend['from'] ?? '').toString(),
                  'to': (friend['to'] ?? '').toString(),
                  'confirmed': ((friend['confirmed'] == true) || friend['confirmed'] == 'true').toString(),
                  'user_id': (friend['user_id'] ?? '').toString(),
                })
            .toList();
      }
      friendsPerLeg.add(friendsForLeg);
    }

    return Column(
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
              confirmedWrapper: _confirmedAvatarWrapper,
            ),
          );
        }),
      ],
    );
  }
}

// Simple hover detector wrapper for desktop/web to provide hover state.
class _Hoverable extends StatefulWidget {
  final Widget Function(bool hovering) builder;
  const _Hoverable({required this.builder});

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hovering = false;

  void _setHover(bool value) {
    if (_hovering != value) {
      setState(() => _hovering = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: widget.builder(_hovering),
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
  final Widget Function(Map<String, String> friend, {required Widget child})? confirmedWrapper;
  const _LegTimeline({
    required this.stops,
    required this.userAvatars,
    required this.stopIds,
    required this.isVertical,
    required this.userFrom,
    required this.userTo,
    this.confirmedWrapper,
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
          final dotColor = isInUser ? Colors.blue : Colors.grey.withValues(alpha: 0.6);
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
                      transform: isUnboarding ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0)) : Matrix4.identity(),
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
              connectorBuilder: (context, index, type) => SolidLineConnector(color: connectorColor(index)),
              contentsBuilder: (context, index) {
                final stop = stops[index];
                final users = usersAtStop(stop['id'] ?? '');
                final isInUser = (fromIdx != -1 && toIdx != -1 && index >= fromIdx && index <= toIdx);
                final textStyle = isInUser
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14, overflow: TextOverflow.ellipsis);
                final arrivalStyle =
                    isInUser ? const TextStyle(color: Colors.grey) : TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 12);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop['name'] ?? '', style: textStyle),
                      if (stop['arrivalTime'] != null) Text('Arrivo: ${stop['arrivalTime']!}', style: arrivalStyle),
                      if (users.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 8,
                            children: users.map((user) {
                              final avatar = ProfilePicture(picture: user['image'], size: 10.0);
                              final wrapped = confirmedWrapper != null ? confirmedWrapper!(user, child: avatar) : avatar;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  wrapped,
                                  const SizedBox(width: 4),
                                  Text(user['name'] ?? '', style: const TextStyle(fontSize: 12)),
                                ],
                              );
                            }).toList(),
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
                    connectorBuilder: (context, index, type) => SolidLineConnector(color: connectorColor(index)),
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
                                  children: users.map((user) {
                                    final avatar = ProfilePicture(picture: user['image'], size: 10.0);
                                    final wrapped = confirmedWrapper != null ? confirmedWrapper!(user, child: avatar) : avatar;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        wrapped,
                                        const SizedBox(width: 4),
                                        Text(user['name'] ?? '', style: const TextStyle(fontSize: 12)),
                                      ],
                                    );
                                  }).toList(),
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
