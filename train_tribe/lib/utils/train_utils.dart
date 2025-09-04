
// Determines if short day labels should be used based on available total width.
// Mirrors logic originally in TrainsPage._shouldUseShortDayLabels.
bool shouldUseShortDayLabels(double totalWidth) {
  final effectiveWidth = totalWidth - 16; // margin
  final perCellWidth = effectiveWidth / 7.0;
  const longestFullChars = 9; // e.g., Wednesday
  const charPx = 8.0;
  const chipHorizontalPad = 24.0; // padding + border spacing
  const estimatedNeeded = longestFullChars * charPx + chipHorizontalPad; // 96
  return estimatedNeeded > perCellWidth;
}

// Join train ids to build a route signature.
String routeSignature(List<String> ids) => ids.join('+');
