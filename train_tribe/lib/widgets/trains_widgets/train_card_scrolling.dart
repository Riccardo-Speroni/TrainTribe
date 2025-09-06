part of 'train_card.dart';

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
    final barColor = theme.colorScheme.secondary.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.35);
    final thickness = 3.0; // thumb thickness only
    final minThumb = 20.0; // ensure always visible
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ((widget.forceVisible) || (widget.controller.hasClients && widget.controller.position.maxScrollExtent > 4))
                ? CustomPaint(
                    key: ValueKey('scrollProgress_${widget.axis == Axis.vertical ? 'v' : 'h'}'),
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
