import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../utils/profile_picture_widget.dart';
import 'package:flutter/foundation.dart';

part 'train_card_widgets/train_card_hoverable.dart';
part 'train_card_widgets/train_card_scrolling.dart';
part 'train_card_widgets/train_card_leg_timeline.dart';
part 'train_card_widgets/train_card_color_ext.dart';
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
    theme.brightness == Brightness.dark ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.15);
    final borderColor =
        userConfirmed ? (theme.colorScheme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.green) : baseBorderColor;
    // Light mode: give cards a slightly more distinct background vs scaffold and a richer multi-layer shadow.
    final bool isLight = theme.brightness == Brightness.light;
    final Color effectiveCardColor = isLight
        // Blend a touch of surface tint & white to differentiate from pure white backgrounds without looking gray.
  ? Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.015), theme.cardColor.withValues(alpha: 0.985))
        : theme.cardColor;
    final gradient = userConfirmed
        ? LinearGradient(
            colors: theme.colorScheme.brightness == Brightness.dark
                ? [theme.colorScheme.primary.withValues(alpha: 0.15), theme.colorScheme.primary.withValues(alpha: 0.05)]
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
              color: effectiveCardColor,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: borderColor, width: 1.6),
              boxShadow: [
                if (isLight) ...[
                  // Subtle base lift
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035 + hoverElevation * 0.6),
                    blurRadius: 5 + (hovering ? 2 : 0),
                    spreadRadius: 0.5,
                    offset: const Offset(0, 1),
                  ),
                  // Softer ambient shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06 + hoverElevation),
                    blurRadius: 18 + (hovering ? 6 : 2),
                    spreadRadius: 1.2,
                    offset: const Offset(0, 8),
                  ),
                ] else
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: hovering ? 0.12 : 0.07),
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
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Colors.grey,
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
      ? (theme.brightness == Brightness.dark ? theme.colorScheme.primary.withValues(alpha: 0.25) : Colors.green.withValues(alpha: 0.15))
      : theme.colorScheme.secondaryContainer.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.5),
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
              if (!dark) BoxShadow(color: glowColor.withValues(alpha: 0.45), blurRadius: 5, spreadRadius: 0.6),
              if (dark) BoxShadow(color: borderColor.withValues(alpha: 0.22), blurRadius: 3, spreadRadius: 0.3),
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
                if (!dark) BoxShadow(color: glowColor.withValues(alpha: 0.42), blurRadius: 4, spreadRadius: 0.6),
                if (dark) BoxShadow(color: borderColor.withValues(alpha: 0.18), blurRadius: 2.5, spreadRadius: 0.25),
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
                BoxShadow(color: borderColor.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 0.5),
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
  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Colors.grey,
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
          return Builder(builder: (context) {
            // Extra spacing between lists on narrow (mobile) layouts to avoid visual crowding / gradient overlap.
            final bool isNarrow = MediaQuery.of(context).size.width < 520;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isNarrow ? 14.0 : 10.0),
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
          });
        }),
      ],
    );
  }
}
