part of '../train_card.dart';

extension _ColorShade on Color {
  Color darken([double amount = .12]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
