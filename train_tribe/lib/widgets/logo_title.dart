import 'package:flutter/material.dart';

/// Theme-aware logo wordmark for AppBar titles.
/// - Chooses light/dark asset based on current theme brightness.
/// - Height defaults to 24 to fit standard AppBar.
class LogoTitle extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final EdgeInsetsGeometry? padding;

  const LogoTitle({super.key, this.height = 24, this.fit = BoxFit.contain, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark ? 'images/logo_text.png' : 'images/logo_text_black.png';
    final image = Image.asset(asset, height: height, fit: fit);

    // Optional padding wrapper
    final child = padding != null ? Padding(padding: padding!, child: image) : image;

    // Image is non-selectable, but keep semantics for accessibility.
    return Semantics(
      label: 'TrainTribe',
      child: child,
    );
  }
}
