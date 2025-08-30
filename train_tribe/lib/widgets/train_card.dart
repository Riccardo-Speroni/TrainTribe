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
      // Plain text widget (no Flexible/Expanded here to avoid nesting ParentDataWidgets incorrectly).
      final timeLabel = Text(
        '$departureTime – $arrivalTime',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
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
                  // Use Flexible once here.
                  Flexible(child: timeLabel),
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
              // Expanded wraps the plain text (was previously Flexible inside Expanded -> error).
              Expanded(child: timeLabel),
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
                    firstName: userAvatars[i]['name'],
                    lastName: userAvatars[i]['last_name'],
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
    // Reuse collapsed header style for visual consistency while expanded.
    final icon = Icon(
      isDirect ? Icons.trending_flat : Icons.alt_route,
      color: isDirect ? Colors.green : Colors.orange,
      size: 22.0,
    );
    final titleChip = _solutionChip(context);
    final timeLabel = Text(
      '$departureTime – $arrivalTime',
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
    final avatars = _buildAvatars();
    final confirmBtn = trailing != null
        ? ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96, maxWidth: 130),
            child: trailing!,
          )
        : const SizedBox();

    return LayoutBuilder(builder: (context, constraints) {
      final isTight = constraints.maxWidth < 640; // allow more space on wide desktop
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isTight)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      titleChip,
                      const SizedBox(width: 14),
                      Flexible(child: timeLabel),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Flexible(flex: 3, child: Align(alignment: Alignment.centerLeft, child: avatars)),
                const SizedBox(width: 16),
                Flexible(flex: 3, child: Align(alignment: Alignment.centerRight, child: confirmBtn)),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    titleChip,
                    const SizedBox(width: 10),
                    Expanded(child: timeLabel),
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
            ),
          const SizedBox(height: 14),
          _buildLegsTimeline(),
        ],
      );
    });
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
              forceShowThumb: isExpanded, // ensure thumb visible while expanded
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
  final bool forceShowThumb;
  const _LegTimeline({
    required this.stops,
    required this.userAvatars,
    required this.stopIds,
    required this.isVertical,
    required this.userFrom,
    required this.userTo,
    this.confirmedWrapper,
    this.forceShowThumb = false,
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
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        // Adaptive decision: prefer horizontal on medium/wide screens for many stops to avoid very tall cards.
        // Force vertical only on narrow layouts.
        final bool forceVerticalByWidth = constraints.maxWidth < 520; // phone narrow portrait
        // Dynamic cell width so long stop lists remain compact.
        final double targetCell = (constraints.maxWidth / (stops.length.clamp(3, 8))).clamp(110.0, 170.0);
        final double stopWidth = targetCell;
        // Previous total width formula added manual spacing + margins which produced extra blank trailing space
        // causing perceived overscroll. Use intrinsic width: sum of tile widths only. Padding is applied outside.
        final double horizontalTotalWidth = stops.length * stopWidth;
        final useHorizontal = !forceVerticalByWidth; // always horizontal if there is width
        final shouldBeVertical = !useHorizontal; // backward name kept for minimal downstream edits

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
          final Color dotColor = isInUser
              ? primary
              : (theme.brightness == Brightness.dark
                  ? theme.colorScheme.outlineVariant.withOpacity(0.45)
                  : theme.colorScheme.outlineVariant.withOpacity(0.55));
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
          final neutral = theme.brightness == Brightness.dark
              ? theme.colorScheme.outlineVariant.withOpacity(0.35)
              : theme.colorScheme.outlineVariant.withOpacity(0.55);
          if (fromIdx == -1 || toIdx == -1) return neutral;
          if (idx > fromIdx && idx <= toIdx) return primary; // segment inside user path
          return neutral;
        }

        Widget buildStopContents(
          int index,
          Map<String, String> stop, {
          TextAlign align = TextAlign.start,
          required bool compact,
        }) {
          final users = usersAtStop(stop['id'] ?? '');
          final isInUser = (fromIdx != -1 && toIdx != -1 && index >= fromIdx && index <= toIdx);
          final baseColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
          final textStyle = TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12.5 : 13.5,
            height: 1.2,
            color: isInUser
                ? (theme.brightness == Brightness.dark ? primary.withOpacity(0.95) : primary.darken())
                : baseColor.withOpacity(compact ? 0.75 : 0.78),
            letterSpacing: 0.15,
          );
          final timeStyle = TextStyle(
            fontSize: compact ? 10.5 : 11.5,
            height: 1.25,
            letterSpacing: 0.2,
            color: isInUser ? baseColor.withOpacity(0.82) : baseColor.withOpacity(0.55),
          );
          final showAvatars = !compact && users.isNotEmpty;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: align == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                stop['name'] ?? '',
                style: textStyle,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
              ),
              if (stop['arrivalTime'] != null && stop['arrivalTime']!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Text('Arrivo: ${stop['arrivalTime']!}', style: timeStyle, textAlign: align),
                ),
              if (showAvatars)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    alignment: align == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
                    spacing: 6,
                    runSpacing: 4,
                    children: users.map((user) {
                      final avatar = ProfilePicture(picture: user['image'], size: 11.0);
                      final wrapped = confirmedWrapper != null ? confirmedWrapper!(user, child: avatar) : avatar;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          wrapped,
                          const SizedBox(width: 3),
                          Text(user['name'] ?? '', style: const TextStyle(fontSize: 11)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }

        if (shouldBeVertical) {
          // Vertical (narrow) presentation – allow scrolling if many stops.
          final estimatedHeight = stops.length * 72.0; // rough per stop
          final maxHeight = 420.0;
          final child = FixedTimeline.tileBuilder(
            theme: TimelineThemeData(
              nodePosition: 0.08,
              color: primary,
              indicatorTheme: const IndicatorThemeData(size: 26.0),
              connectorTheme: const ConnectorThemeData(thickness: 3.0),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  child: buildStopContents(index, stop, compact: false),
                );
              },
            ),
          );
          // Controller to avoid Scrollbar without a ScrollPosition when widget tree reconfigures.
          final scrollController = ScrollController();
          final bool enableInternalScroll = estimatedHeight > maxHeight; // if false whole page scrolls naturally
          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // if too tall, cap and enable scroll
                maxHeight: estimatedHeight > maxHeight ? maxHeight : estimatedHeight,
              ),
              child: enableInternalScroll
                  ? _DesktopDragScroll(
                      axis: Axis.vertical,
                      controller: scrollController,
                      child: ScrollConfiguration(
                        behavior: _NoGlowScrollBehavior(),
                        child: _ProgressScrollArea(
                          controller: scrollController,
                          axis: Axis.vertical,
                          forceVisible: forceShowThumb,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(right: 4),
                            child: Stack(
                              children: [
                                child,
                                // Gradient fades top/bottom to hint scroll
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  height: 18,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 22,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : child,
            ),
          );
        }

        // Horizontal scrollable timeline (wide) to avoid tall cards.
        final timeline = FixedTimeline.tileBuilder(
          direction: Axis.horizontal,
          builder: TimelineTileBuilder.connected(
            connectionDirection: ConnectionDirection.before,
            itemCount: stops.length,
            indicatorBuilder: (context, index) => buildDot(index, stops[index]['id'] ?? ''),
            connectorBuilder: (context, index, type) => SolidLineConnector(color: connectorColor(index)),
            contentsBuilder: (context, index) {
              final stop = stops[index];
              return SizedBox(
                width: stopWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: buildStopContents(index, stop, align: TextAlign.center, compact: true),
                ),
              );
            },
          ),
        );

        final needsScroll = horizontalTotalWidth > constraints.maxWidth;
        final horizontalController = ScrollController();
        return SizedBox(
          height: 210, // fixed comfortable height
          child: Stack(
            children: [
              if (needsScroll)
                Positioned.fill(
                  child: _DesktopDragScroll(
                    axis: Axis.horizontal,
                    controller: horizontalController,
                    child: ScrollConfiguration(
                      behavior: _NoGlowScrollBehavior(),
                      child: _ProgressScrollArea(
                        controller: horizontalController,
                        axis: Axis.horizontal,
                        forceVisible: forceShowThumb,
                        child: SingleChildScrollView(
                          controller: horizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: timeline, // intrinsic width = sum of SizedBox widths in contentsBuilder
                        ),
                      ),
                    ),
                  ),
                )
              else
                Center(child: SizedBox(width: horizontalTotalWidth, child: timeline)),
              if (needsScroll)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 6, // leave a small gap so horizontal progress thumb (bottom) stays fully visible
                  child: IgnorePointer(
                    child: Container(
                      width: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ),
                ),
              if (needsScroll)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 6, // gap for thumb visibility
                  child: IgnorePointer(
                    child: Container(
                      width: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Simple extension for slight darken effect without importing extra libs
extension _ColorShade on Color {
  Color darken([double amount = .12]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

// Thin, non-interactive progress indicator overlay for scroll position.
class _ProgressScrollArea extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Axis axis;
  final bool forceVisible; // show immediately regardless of scroll activity
  const _ProgressScrollArea({required this.child, required this.controller, required this.axis, this.forceVisible = false});

  @override
  State<_ProgressScrollArea> createState() => _ProgressScrollAreaState();
}

class _ProgressScrollAreaState extends State<_ProgressScrollArea> {
  double _progress = 0.0; // 0..1
  // Thumb always visible when scrollable; no fade logic needed now.
  double _thumbFraction = 0.0; // viewport / content
  bool _postFrameScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    _scheduleMetricsUpdate();
  }

  @override
  void didUpdateWidget(covariant _ProgressScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      _onScroll();
    }
    _scheduleMetricsUpdate();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final max = widget.controller.position.maxScrollExtent;
    final p = max <= 0 ? 0.0 : (widget.controller.offset / max).clamp(0.0, 1.0);
    final pos = widget.controller.position;
    final contentExtent = pos.maxScrollExtent + pos.viewportDimension; // total scrollable + viewport
    final vf = contentExtent > 0 ? (pos.viewportDimension / contentExtent).clamp(0.0, 1.0) : 1.0;
    if (p != _progress) {
      setState(() => _progress = p);
    }
    if (vf != _thumbFraction) {
      setState(() => _thumbFraction = vf);
    }
  }

  void _scheduleMetricsUpdate() {
    if (_postFrameScheduled) return;
    _postFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameScheduled = false;
      if (!mounted) return;
      // Force metric update after layout so initial thumb size is correct without user scroll.
      if (widget.controller.hasClients) {
        _onScroll();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = theme.colorScheme.primary.withOpacity(theme.brightness == Brightness.dark ? 0.75 : 0.55);
    final thickness = 3.0; // thumb thickness only
    final minThumb = 20.0; // ensure always visible
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ((widget.forceVisible) || (widget.controller.hasClients && widget.controller.position.maxScrollExtent > 4))
                ? CustomPaint(
                    painter: _ScrollProgressPainter(
                      axis: widget.axis,
                      progress: _progress,
                      barColor: barColor,
                      trackColor: Colors.transparent, // no track
                      thickness: thickness,
                      minThumbExtent: minThumb,
                      viewportFraction: _thumbFraction,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _ScrollProgressPainter extends CustomPainter {
  final Axis axis;
  final double progress;
  final Color barColor;
  final Color trackColor;
  final double thickness;
  final double minThumbExtent;
  final double viewportFraction; // ratio of visible area to total content
  const _ScrollProgressPainter({
    required this.axis,
    required this.progress,
    required this.barColor,
    required this.trackColor,
    required this.thickness,
    required this.minThumbExtent,
    required this.viewportFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBar = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (axis == Axis.vertical) {
      // No track (transparent) => skip drawing
      final vf = viewportFraction == 0 ? 1.0 : viewportFraction;
      final thumbHeight = (size.height * vf).clamp(minThumbExtent, size.height);
      final y = (size.height - thumbHeight) * progress;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - thickness, y, thickness, thumbHeight),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(barRect, paintBar);
    } else {
      // No track
      final vf = viewportFraction == 0 ? 1.0 : viewportFraction;
      final thumbWidth = (size.width * vf).clamp(minThumbExtent, size.width);
      final x = (size.width - thumbWidth) * progress;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - thickness, thumbWidth, thickness),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(barRect, paintBar);
    }
  }

  @override
  bool shouldRepaint(covariant _ScrollProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.barColor != barColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.axis != axis ||
        oldDelegate.viewportFraction != viewportFraction;
  }
}

// Scroll behavior removing default glow (especially on desktop / web)
class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child; // suppress default desktop/web scrollbar
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

// Wrapper enabling click + drag (press & hold) scrolling for desktop/web when wheel / touchpad not used.
class _DesktopDragScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Axis axis;
  const _DesktopDragScroll({required this.child, required this.controller, required this.axis});

  @override
  State<_DesktopDragScroll> createState() => _DesktopDragScrollState();
}

class _DesktopDragScrollState extends State<_DesktopDragScroll> {
  bool _dragging = false;

  bool get _enabledDesktop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _handlePanStart(DragStartDetails d) {
    if (!_enabledDesktop) return;
    _dragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (!_enabledDesktop || !_dragging) return;
    if (!widget.controller.hasClients) return;
    final delta = d.delta;
    if (widget.axis == Axis.horizontal) {
      final newOffset = (widget.controller.offset - delta.dx).clamp(0.0, widget.controller.position.maxScrollExtent);
      widget.controller.jumpTo(newOffset);
    } else {
      final newOffset = (widget.controller.offset - delta.dy).clamp(0.0, widget.controller.position.maxScrollExtent);
      widget.controller.jumpTo(newOffset);
    }
  }

  void _handlePanEnd(DragEndDetails d) {
    _dragging = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabledDesktop) return widget.child; // no change on mobile
    return Listener(
      onPointerSignal: (_) {},
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: (details) {
          // simple inertia based on velocity
          if (widget.controller.hasClients) {
            final double velocity =
                widget.axis == Axis.horizontal ? -details.velocity.pixelsPerSecond.dx : -details.velocity.pixelsPerSecond.dy;
            // Convert velocity to distance (tweak factor)
            final double distance = velocity * 0.25; // factor for deceleration
            final target = (widget.controller.offset + distance).clamp(0.0, widget.controller.position.maxScrollExtent);
            widget.controller.animateTo(
              target,
              duration: const Duration(milliseconds: 480),
              curve: Curves.decelerate,
            );
          }
          _handlePanEnd(details);
        },
        onPanCancel: () => _dragging = false,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
          child: widget.child,
        ),
      ),
    );
  }
}
