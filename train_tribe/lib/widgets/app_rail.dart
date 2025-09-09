import 'package:flutter/material.dart';

/// Custom adaptive navigation rail extracted from RootPage.
class AppRail extends StatelessWidget {
  final List<String> titles;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool expanded;
  final ValueChanged<bool> onToggleExpanded;

  const AppRail({
    super.key,
    required this.titles,
    required this.currentIndex,
    required this.onSelect,
    required this.expanded,
    required this.onToggleExpanded,
  });

  static const double _collapsedWidth = 72;
  static const double _itemHeight = 56;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle labelStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    double computeMaxLabelWidth() {
      double maxW = 0;
      final TextDirection textDirection = Directionality.of(context);
      for (final t in titles) {
        final tp = TextPainter(
          text: TextSpan(text: t, style: labelStyle),
          maxLines: 1,
          textDirection: textDirection,
        )..layout();
        if (tp.width > maxW) maxW = tp.width;
      }
      return maxW;
    }

    final double hPad = 16; // internal horizontal padding for extended labels region
    final double gap = 12;  // gap between icon and label
    final double maxLabelWidth = expanded ? computeMaxLabelWidth() : 0;
    final double dynamicExtendedWidth = _collapsedWidth + (maxLabelWidth > 0 ? (maxLabelWidth + gap + hPad) : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double itemSpacing = 8; // total vertical spacing (4+4 margin)
        final double contentHeight = titles.length * _itemHeight + (titles.length - 1) * itemSpacing;
        const double toggleTotalHeight = 52; // button + padding
        final double available = constraints.maxHeight;
        double topPad = (available - toggleTotalHeight - contentHeight) / 2;
        if (topPad < 12) topPad = 12;

        if (!expanded) {
          // Collapsed Rail
            return SizedBox(
            width: _collapsedWidth,
            child: Column(
              children: [
                SizedBox(height: topPad),
                for (int i = 0; i < titles.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelect(i),
                      child: Container(
                        width: 56,
                        height: _itemHeight,
                        decoration: BoxDecoration(
                          color: currentIndex == i ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          [Icons.home, Icons.people, Icons.train, Icons.calendar_today, Icons.person][i],
                          color: currentIndex == i ? scheme.primary : scheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RailToggleButton(
                    expanded: false,
                    onPressed: () => onToggleExpanded(true),
                  ),
                ),
              ],
            ),
          );
        }

        // Extended Rail
        Widget buildDestination(int index) {
          final bool selected = currentIndex == index;
          final Color selectedIconColor = scheme.primary;
          final Color unselectedIconColor = scheme.onSurfaceVariant;
          final Color selectedBg = scheme.primary.withValues(alpha: 0.12);
          final iconList = [
            Icons.home,
            Icons.people,
            Icons.train,
            Icons.calendar_today,
            Icons.person,
          ];
          final icon = Icon(iconList[index], color: selected ? selectedIconColor : unselectedIconColor, size: 24);
          final label = Text(
            titles[index],
            style: labelStyle.copyWith(
              color: selected ? selectedIconColor : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            overflow: TextOverflow.fade,
            softWrap: false,
          );
          return SizedBox(
            height: _itemHeight,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(index),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    icon,
                    SizedBox(width: gap),
                    Flexible(child: label),
                  ],
                ),
              ),
            ),
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: dynamicExtendedWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPad),
              for (int i = 0; i < titles.length; i++) buildDestination(i),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _RailToggleButton(
                    expanded: true,
                    onPressed: () => onToggleExpanded(false),
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

class _RailToggleButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;
  const _RailToggleButton({required this.expanded, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            expanded ? Icons.chevron_left : Icons.chevron_right,
            size: 22,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
