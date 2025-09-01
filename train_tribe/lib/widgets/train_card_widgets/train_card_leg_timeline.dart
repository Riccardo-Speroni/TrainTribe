part of train_card;

class _LegTimeline extends StatefulWidget {
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

  @override
  State<_LegTimeline> createState() => _LegTimelineState();
}

class _LegTimelineState extends State<_LegTimeline> {
  bool _collapsed = true;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  bool _pendingCenterOnExpand = false; // flag to adjust scroll after expanding

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  List<Map<String, String>> usersAtStop(String stopId) {
    final idx = widget.stopIds.indexOf(stopId);
    if (idx == -1) return [];
    return widget.userAvatars.where((user) {
      final from = user['from'];
      final to = user['to'];
      if (from == null || to == null) return false;
      final fromIdx = widget.stopIds.indexOf(from);
      final toIdx = widget.stopIds.indexOf(to);
      if (fromIdx == -1 || toIdx == -1) return false;
      return fromIdx <= idx && idx <= toIdx;
    }).toList();
  }

  void _toggleCollapsed() {
    if (_collapsed) {
      // About to expand: mark to center after build.
      _pendingCenterOnExpand = true;
    }
    setState(() => _collapsed = !_collapsed);
  }

  void _centerOnUser({required bool vertical, required int fromIdx, required double perItemExtent, required int totalStops}) {
    if (fromIdx < 0) return;
    final controller = vertical ? _verticalController : _horizontalController;
    if (!controller.hasClients) return;
    final double anchorIndex = ((fromIdx - 1).clamp(0, totalStops) as num).toDouble(); // show one before similar to collapsed window
    final desiredOffset = (anchorIndex * perItemExtent).clamp(0.0, controller.position.maxScrollExtent);
    controller.jumpTo(desiredOffset); // jump first to avoid long animate from 0
    controller.animateTo(desiredOffset, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final bool forceVerticalByWidth = constraints.maxWidth < 520; // narrow phone
        final stops = widget.stops;
        final stopIds = widget.stopIds;
        final userFrom = widget.userFrom;
        final userTo = widget.userTo;
        final double targetCell = (constraints.maxWidth / (stops.length.clamp(3, 8))).clamp(110.0, 170.0);
        final double stopWidth = targetCell;
        // horizontalTotalWidth replaced by dynamic displayedWidth after displayStops computation
        final useHorizontal = !forceVerticalByWidth;
        final shouldBeVertical = !useHorizontal;

        IconData? stopIconData(String stopId) {
          if (userFrom.isNotEmpty && stopId == userFrom) return MdiIcons.stairsUp;
          if (userTo.isNotEmpty && stopId == userTo) return MdiIcons.stairsDown;
          return null;
        }

        final fromIdx = userFrom.isNotEmpty ? stopIds.indexOf(userFrom) : -1;
        final toIdx = userTo.isNotEmpty ? stopIds.indexOf(userTo) : -1;

        // (local reference to outer helper class declared below)

        List<_DisplayStop> computeDisplayStops() {
          // Show everything if expanded, user segment undefined, or list already short.
          if (!_collapsed || fromIdx == -1 || toIdx == -1 || stops.length <= 5) {
            return [for (int i = 0; i < stops.length; i++) _DisplayStop.real(stops[i], i)];
          }
          // Visible window = one before user's first and one after user's last (clamped)
          int start = (fromIdx - 1).clamp(0, fromIdx);
          // ensure we don't go past user's start
          int end = (toIdx + 1).clamp(toIdx, stops.length - 1);
          final hiddenLeft = start; // indices [0, start-1]
          final hiddenRight = (stops.length - 1) - end; // indices [end+1, last]
          final List<_DisplayStop> result = [];
          if (hiddenLeft > 0) {
            result.add(_DisplayStop.ellipsis(hiddenLeft, prefix: true));
          }
          for (int i = start; i <= end; i++) {
            result.add(_DisplayStop.real(stops[i], i));
          }
          if (hiddenRight > 0) {
            result.add(_DisplayStop.ellipsis(hiddenRight, prefix: false));
          }
          return result;
        }

        final displayStops = computeDisplayStops();

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
                      final wrapped = widget.confirmedWrapper != null ? widget.confirmedWrapper!(user, child: avatar) : avatar;
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
              itemCount: displayStops.length,
              indicatorBuilder: (context, index) {
                final ds = displayStops[index];
                if (ds.isEllipsis) return _ellipsisIndicator(theme, ds.hiddenCount, vertical: true);
                return buildDot(ds.originalIndex!, ds.stop!['id'] ?? '');
              },
              connectorBuilder: (context, index, type) {
                if (index == 0) return const SizedBox.shrink();
                final prev = displayStops[index - 1];
                final cur = displayStops[index];
                final dashed = prev.isEllipsis || cur.isEllipsis;
                if (dashed) {
                  final neutral = theme.brightness == Brightness.dark
                      ? theme.colorScheme.outlineVariant.withOpacity(0.35)
                      : theme.colorScheme.outlineVariant.withOpacity(0.55);
                  return _DashedConnector(color: neutral, axis: Axis.vertical);
                }
                return SolidLineConnector(color: connectorColor(cur.originalIndex!));
              },
              contentsBuilder: (context, index) {
                final ds = displayStops[index];
                if (ds.isEllipsis) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  child: buildStopContents(ds.originalIndex!, ds.stop!, compact: false),
                );
              },
            ),
          );
          final bool enableInternalScroll = estimatedHeight > maxHeight;
          final verticalTimelineCore = AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: enableInternalScroll ? maxHeight : estimatedHeight),
              child: enableInternalScroll
                  ? _DesktopDragScroll(
                      axis: Axis.vertical,
                      controller: _verticalController,
                      child: ScrollConfiguration(
                        behavior: _NoGlowScrollBehavior(),
                        child: _ProgressScrollArea(
                          controller: _verticalController,
                          axis: Axis.vertical,
                          forceVisible: widget.forceShowThumb,
                          child: LayoutBuilder(builder: (context, innerConstraints) {
                            return ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xD8000000),
                                  Color(0x00000000),
                                  Color(0x00000000),
                                  Color(0xD8000000),
                                ],
                                stops: [0.0, 0.085, 0.915, 1.0],
                              ).createShader(rect),
                              blendMode: BlendMode.dstOut,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 12, right: 4),
                                child: SingleChildScrollView(
                                  controller: _verticalController,
                                  physics: const ClampingScrollPhysics(),
                                  child: child,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: child,
                    ),
            ),
          );
          // Schedule centering after expand frame (vertical)
          if (_pendingCenterOnExpand && !_collapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (enableInternalScroll) {
                final perItem = estimatedHeight / widget.stops.length; // approx 72
                _centerOnUser(vertical: true, fromIdx: fromIdx, perItemExtent: perItem, totalStops: widget.stops.length);
              }
              _pendingCenterOnExpand = false; // reset after vertical centering
            });
          }
          final Widget verticalTimeline = verticalTimelineCore; // removed AnimatedSwitcher to avoid duplicate scroll attachments
          return _ExpandableTimelineWrapper(
            collapsed: _collapsed,
            onTap: _toggleCollapsed,
            child: verticalTimeline,
          );
        }

        // Horizontal timeline
        final timeline = FixedTimeline.tileBuilder(
          direction: Axis.horizontal,
          builder: TimelineTileBuilder.connected(
            connectionDirection: ConnectionDirection.before,
            itemCount: displayStops.length,
            indicatorBuilder: (context, index) {
              final ds = displayStops[index];
              if (ds.isEllipsis) return _ellipsisIndicator(theme, ds.hiddenCount, vertical: false);
              return buildDot(ds.originalIndex!, ds.stop!['id'] ?? '');
            },
            connectorBuilder: (context, index, type) {
              if (index == 0) return const SizedBox.shrink();
              final prev = displayStops[index - 1];
              final cur = displayStops[index];
              // For desktop (horizontal) view prefer a clean solid connector even across ellipsis boundaries.
              // Use neutral color (same as non-user segment) for consistency.
              final neutral = theme.brightness == Brightness.dark
                  ? theme.colorScheme.outlineVariant.withOpacity(0.35)
                  : theme.colorScheme.outlineVariant.withOpacity(0.55);
              if (prev.isEllipsis || cur.isEllipsis) {
                return SolidLineConnector(color: neutral);
              }
              return SolidLineConnector(color: connectorColor(cur.originalIndex!));
            },
            contentsBuilder: (context, index) {
              final ds = displayStops[index];
              final width = ds.isEllipsis ? 78.0 : stopWidth;
              if (ds.isEllipsis) {
                // Provide spacing only; indicator already rendered via indicatorBuilder to avoid duplicate ellipsis.
                return SizedBox(width: width);
              }
              return SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: buildStopContents(ds.originalIndex!, ds.stop!, align: TextAlign.center, compact: true),
                ),
              );
            },
          ),
        );

        double displayedWidth = 0;
        for (final ds in displayStops) {
          displayedWidth += ds.isEllipsis ? 78.0 : stopWidth;
        }

        final needsScroll = displayedWidth > constraints.maxWidth;
        final horizontalTimelineCore = SizedBox(
          height: 210,
          child: Stack(children: [
            if (needsScroll)
              Positioned.fill(
                  child: _DesktopDragScroll(
                axis: Axis.horizontal,
                controller: _horizontalController,
                child: ScrollConfiguration(
                  behavior: _NoGlowScrollBehavior(),
                  child: _ProgressScrollArea(
                    controller: _horizontalController,
                    axis: Axis.horizontal,
                    forceVisible: widget.forceShowThumb,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      // Extra padding so ellipsis at start/end sits fully before gradient fade.
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: timeline,
                    ),
                  ),
                ),
              ))
            else
              // Use a non-scrollable SingleChildScrollView to give the internal Row unbounded width
              // along the horizontal axis, preventing minor rounding overflows when timeline width
              // is very close to maxWidth. Disable scrolling/drag; just center the content.
              Positioned.fill(
                child: ScrollConfiguration(
                  behavior: _NoGlowScrollBehavior(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(width: displayedWidth, child: timeline),
                    ),
                  ),
                ),
              ),
            if (needsScroll)
              Positioned(
                  left: 0,
                  top: 0,
                  bottom: 6,
                  child: IgnorePointer(
                      child: Container(
                          width: 20, // reduced fade distance
                          decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [
                            theme.cardColor,
                            theme.cardColor.withOpacity(0.0),
                          ], stops: const [
                            0.0,
                            1.0
                          ]))))),
            if (needsScroll)
              Positioned(
                  right: 0,
                  top: 0,
                  bottom: 6,
                  child: IgnorePointer(
                      child: Container(
                          width: 20, // reduced fade distance
                          decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [
                            theme.cardColor,
                            theme.cardColor.withOpacity(0.0),
                          ], stops: const [
                            0.0,
                            1.0
                          ]))))),
          ]),
        );
        final Widget horizontalTimeline = horizontalTimelineCore; // removed AnimatedSwitcher to avoid controller duplication
        // Schedule centering after expand frame (horizontal)
        if (_pendingCenterOnExpand && !_collapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (needsScroll) {
              final perItem = stopWidth; // constant cell width
              _centerOnUser(vertical: false, fromIdx: fromIdx, perItemExtent: perItem, totalStops: widget.stops.length);
            }
          });
          _pendingCenterOnExpand = false; // reset once scheduled for both orientations
        }
        return _ExpandableTimelineWrapper(
          collapsed: _collapsed,
          onTap: _toggleCollapsed,
          child: horizontalTimeline,
        );
      },
    );
  }
}

// Helper model for collapsed/expanded stop rendering
class _DisplayStop {
  final Map<String, String>? stop;
  final int? originalIndex; // null for ellipsis
  final bool isEllipsis;
  final int hiddenCount;
  final bool prefix; // leading side indicator
  const _DisplayStop.ellipsis(this.hiddenCount, {required this.prefix})
      : stop = null,
        originalIndex = null,
        isEllipsis = true;
  const _DisplayStop.real(this.stop, this.originalIndex)
      : isEllipsis = false,
        hiddenCount = 0,
        prefix = false;
}

// Dashed connector (custom since timelines_plus may not provide one)
class _DashedConnector extends StatelessWidget {
  final Color color;
  final Axis axis;
  const _DashedConnector({required this.color, required this.axis});
  @override
  Widget build(BuildContext context) {
    const double t = 3; // thickness
    return CustomPaint(
      size: axis == Axis.vertical ? const Size(3, double.infinity) : const Size(double.infinity, 3),
      painter: _DashedLinePainter(color: color, axis: axis, dash: 6, gap: 4, thickness: t),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final Axis axis;
  final double dash;
  final double gap;
  final double thickness;
  _DashedLinePainter({required this.color, required this.axis, required this.dash, required this.gap, required this.thickness});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    double pos = 0.0;
    final double length = axis == Axis.vertical ? size.height : size.width;
    while (pos < length) {
      final double end = (pos + dash).clamp(0, length);
      if (axis == Axis.vertical) {
        canvas.drawLine(Offset(size.width / 2, pos), Offset(size.width / 2, end), paint);
      } else {
        canvas.drawLine(Offset(pos, size.height / 2), Offset(end, size.height / 2), paint);
      }
      pos += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color || old.axis != axis || old.dash != dash || old.gap != gap || old.thickness != thickness;
}

Widget _ellipsisIndicator(ThemeData theme, int hidden, {required bool vertical}) {
  final neutralBase = theme.colorScheme.outlineVariant;
  final neutral = neutralBase.withOpacity(theme.brightness == Brightness.dark ? 0.30 : 0.34);
  final bg = theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceVariant.withOpacity(0.12)
      : theme.colorScheme.surfaceVariant.withOpacity(0.10);
  final txt = theme.textTheme.bodySmall?.color?.withOpacity(0.50) ?? Colors.black54;
  final dots = Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
        3,
        (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.9),
            child: Container(width: 3.6, height: 3.6, decoration: BoxDecoration(color: txt.withOpacity(0.55), shape: BoxShape.circle)))),
  );
  final label = Text('+$hidden', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: txt));
  final content = Row(mainAxisSize: MainAxisSize.min, children: [dots, const SizedBox(width: 4), label]);
  return AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: neutral.withOpacity(0.55), width: 0.8),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.14 : 0.05),
            blurRadius: 2.5,
            offset: const Offset(0, 1)),
      ],
    ),
    child: content,
  );
}

class _ExpandableTimelineWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool collapsed;
  const _ExpandableTimelineWrapper({required this.child, required this.onTap, required this.collapsed});
  @override
  State<_ExpandableTimelineWrapper> createState() => _ExpandableTimelineWrapperState();
}

class _ExpandableTimelineWrapperState extends State<_ExpandableTimelineWrapper> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = theme.colorScheme.primary.withOpacity(theme.brightness == Brightness.dark ? 0.05 : 0.05);
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.22);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: _hover
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 0.9),
                  color: highlight,
                )
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
