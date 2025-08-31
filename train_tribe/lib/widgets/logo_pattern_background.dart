import 'dart:math';
import 'package:flutter/material.dart';

/// Reusable background pattern made of non-overlapping logo images.
///
/// Features:
/// - Generates particles only once for the initial size.
/// - When the available space expands, adds new particles only in the new area.
/// - Particles never move, rotate or overlap after being placed.
/// - Keeps a stable look across rebuilds (state kept in the widget's State).
class LogoPatternBackground extends StatefulWidget {
  final Widget child;
  final String assetPath;
  final int initialCount; // approximate baseline count for initial size
  final double minSize;
  final double maxSize;
  final double minOpacity;
  final double maxOpacity;
  final double spacing; // minimal gap between particles

  const LogoPatternBackground({
    super.key,
    required this.child,
    this.assetPath = 'images/small_logo.png',
    this.initialCount = 85,
    this.minSize = 20,
    this.maxSize = 80,
    this.minOpacity = 0.12,
    this.maxOpacity = 0.25,
    this.spacing = 6,
  });

  @override
  State<LogoPatternBackground> createState() => _LogoPatternBackgroundState();
}

class _LogoPatternBackgroundState extends State<LogoPatternBackground> {
  final Random _rng = Random();
  final List<_Particle> _particles = [];
  double? _width; // size already populated
  double? _height;
  double? _density; // particles per pixel^2

  @override
  Widget build(BuildContext context) {
  return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
        if (w.isFinite && h.isFinite) {
          if (_particles.isEmpty) {
            // Initial population
            _generateInitial(w, h);
          } else if (w > (_width ?? 0) || h > (_height ?? 0)) {
            _extend(w, h);
          }
        }
        return Container(
          color: bgColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_particles.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: _particles
                          .map((p) => Positioned(
                                left: p.left,
                                top: p.top,
                                width: p.size,
                                height: p.size,
                                child: Opacity(
                                  opacity: p.opacity,
                                  child: Image.asset(
                                    widget.assetPath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              widget.child,
            ],
          ),
        );
      },
    );
  }

  void _generateInitial(double w, double h) {
    // Derive initial target count proportionally to area using baseline on  (approx 1920*1080)
    final referenceArea = 1920 * 1080;
    final area = w * h;
    final scaledTarget = max(1, (widget.initialCount * (area / referenceArea)).round());
    _placeParticles(scaledTarget, w, h);
    _width = w;
    _height = h;
    _density = _particles.length / area;
  }

  void _extend(double newW, double newH) {
    final oldW = _width ?? newW;
    final oldH = _height ?? newH;
    final newArea = newW * newH;
    final targetCount = (_density ?? (_particles.length / (oldW * oldH))) * newArea;
    final toAdd = targetCount.round() - _particles.length;
    if (toAdd > 0) {
      _placeParticles(toAdd, newW, newH, restrictToNewArea: true, oldW: oldW, oldH: oldH);
    }
    _width = newW;
    _height = newH;
  }

  void _placeParticles(int count, double w, double h,
      {bool restrictToNewArea = false, double? oldW, double? oldH}) {
    const int attemptsPerParticle = 140;
    int placed = 0;
    while (placed < count) {
      bool added = false;
      for (int attempt = 0; attempt < attemptsPerParticle && !added; attempt++) {
        final size = widget.minSize + _rng.nextDouble() * (widget.maxSize - widget.minSize);
        if (size > w || size > h) continue;
        final left = _rng.nextDouble() * (w - size);
        final top = _rng.nextDouble() * (h - size);

        if (restrictToNewArea && oldW != null && oldH != null) {
          final insideOld = left + size <= oldW && top + size <= oldH;
            if (insideOld) continue; // only new strips
        }

        final rect = Rect.fromLTWH(left, top, size, size).inflate(widget.spacing);
        bool overlap = false;
        for (final p in _particles) {
          final o = Rect.fromLTWH(p.left, p.top, p.size, p.size).inflate(widget.spacing);
          if (rect.overlaps(o)) { overlap = true; break; }
        }
        if (overlap) continue;

        _particles.add(_Particle(
          left: left,
          top: top,
          size: size,
          opacity: widget.minOpacity + _rng.nextDouble() * (widget.maxOpacity - widget.minOpacity),
        ));
        placed++;
        added = true;
      }
      if (!added) break; // can't place more
    }
  // Nessun setState qui: la lista viene modificata durante il build e già usata nello stesso frame.
  }
}

class _Particle {
  final double left;
  final double top;
  final double size;
  final double opacity;
  const _Particle({
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
  });
}
