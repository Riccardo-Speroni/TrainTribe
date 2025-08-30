part of train_card;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final bool forceVerticalByWidth = constraints.maxWidth < 520; // narrow phone
        final double targetCell = (constraints.maxWidth / (stops.length.clamp(3, 8))).clamp(110.0, 170.0);
        final double stopWidth = targetCell;
        final double horizontalTotalWidth = stops.length * stopWidth;
        final useHorizontal = !forceVerticalByWidth;
        final shouldBeVertical = !useHorizontal;

        IconData? stopIconData(String stopId) {
          if (userFrom.isNotEmpty && stopId == userFrom) return MdiIcons.stairsUp;
          if (userTo.isNotEmpty && stopId == userTo) return MdiIcons.stairsDown;
          return null;
        }

        final fromIdx = userFrom.isNotEmpty ? stopIds.indexOf(userFrom) : -1;
        final toIdx = userTo.isNotEmpty ? stopIds.indexOf(userTo) : -1;

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
                Container(width: 24, height: 24, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: isUnboarding ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0)) : Matrix4.identity(),
                      child: Icon(iconData,
                          color: const Color.fromARGB(230, 255, 255, 255),
                          size: 14,
                          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(1, 1), blurRadius: 1)]),
                    ),
                  ),
                ),
              ],
            );
          }
          return Container(width: 18, height: 18, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle));
        }

        Color connectorColor(int idx) {
          final neutral = theme.brightness == Brightness.dark
              ? theme.colorScheme.outlineVariant.withOpacity(0.35)
              : theme.colorScheme.outlineVariant.withOpacity(0.55);
          if (fromIdx == -1 || toIdx == -1) return neutral;
          if (idx > fromIdx && idx <= toIdx) return primary; // preserve logic
          return neutral;
        }

        Widget buildStopContents(int index, Map<String, String> stop, {TextAlign align = TextAlign.start, required bool compact}) {
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
              Text(stop['name'] ?? '', style: textStyle, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis, textAlign: align),
              if (stop['arrivalTime'] != null && stop['arrivalTime']!.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text('Arrivo: ${stop['arrivalTime']!}', style: timeStyle, textAlign: align)),
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
                          children: [wrapped, const SizedBox(width: 3), Text(user['name'] ?? '', style: const TextStyle(fontSize: 11))]);
                    }).toList(),
                  ),
                ),
            ],
          );
        }

        if (shouldBeVertical) {
          final estimatedHeight = stops.length * 72.0;
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
              indicatorBuilder: (context, index) => buildDot(index, stops[index]['id'] ?? ''),
              connectorBuilder: (context, index, type) => SolidLineConnector(color: connectorColor(index)),
              contentsBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                child: buildStopContents(index, stops[index], compact: false),
              ),
            ),
          );
          final scrollController = ScrollController();
          final bool enableInternalScroll = estimatedHeight > maxHeight;
          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: enableInternalScroll ? maxHeight : estimatedHeight),
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
                            child: Stack(children: [
                              child,
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
                                                  colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)]))))),
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
                                                  colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)]))))),
                            ]),
                          ),
                        ),
                      ),
                    )
                  : child,
            ),
          );
        }

        // Horizontal timeline
        final timeline = FixedTimeline.tileBuilder(
          direction: Axis.horizontal,
          builder: TimelineTileBuilder.connected(
            connectionDirection: ConnectionDirection.before,
            itemCount: stops.length,
            indicatorBuilder: (context, index) => buildDot(index, stops[index]['id'] ?? ''),
            connectorBuilder: (context, index, type) => SolidLineConnector(color: connectorColor(index)),
            contentsBuilder: (context, index) => SizedBox(
              width: stopWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: buildStopContents(index, stops[index], align: TextAlign.center, compact: true),
              ),
            ),
          ),
        );

        final needsScroll = horizontalTotalWidth > constraints.maxWidth;
        final horizontalController = ScrollController();
        return SizedBox(
          height: 210,
          child: Stack(children: [
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
                      child: timeline,
                    ),
                  ),
                ),
              ))
            else
              Center(child: SizedBox(width: horizontalTotalWidth, child: timeline)),
            if (needsScroll)
              Positioned(
                  left: 0,
                  top: 0,
                  bottom: 6,
                  child: IgnorePointer(
                      child: Container(
                          width: 28,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)]))))),
            if (needsScroll)
              Positioned(
                  right: 0,
                  top: 0,
                  bottom: 6,
                  child: IgnorePointer(
                      child: Container(
                          width: 28,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [theme.cardColor, theme.cardColor.withOpacity(0.0)]))))),
          ]),
        );
      },
    );
  }
}
