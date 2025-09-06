import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ResponsiveCardList extends StatelessWidget {
  final List<Widget> cards;
  final int gridBreakpoint;
  final int? expandedCardIndex;

  const ResponsiveCardList({
    super.key,
    required this.cards,
    this.gridBreakpoint = 600,
    this.expandedCardIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isGrid = constraints.maxWidth > gridBreakpoint;

        if (isGrid) {
          final minCardWidth = 340.0; // widened to avoid cramped content
          final maxCardWidth = 420.0; // cap width so cards don't become too wide
          // Determine how many columns fit respecting min width
          int tentativeCount = (constraints.maxWidth / minCardWidth).floor();
          if (tentativeCount < 1) tentativeCount = 1;
          if (tentativeCount > 6) tentativeCount = 6;
          // Recompute actual card width and adjust if exceeding maxCardWidth
          double computedWidth = constraints.maxWidth / tentativeCount;
          while (computedWidth > maxCardWidth && tentativeCount < 8) {
            tentativeCount += 1;
            computedWidth = constraints.maxWidth / tentativeCount;
          }
          final crossAxisCount = tentativeCount;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: StaggeredGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14.0,
              crossAxisSpacing: 14.0,
              children: cards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;

                if (expandedCardIndex != null && index == expandedCardIndex) {
                  return StaggeredGridTile.fit(
                    crossAxisCellCount: crossAxisCount,
                    child: card,
                  );
                }

                return StaggeredGridTile.fit(
                  crossAxisCellCount: 1,
                  child: card,
                );
              }).toList(),
            ),
          );
        } else {
          // On small screens, use a Column so the parent ListView handles scrolling
          final maxContentWidth = 600.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Column(
                  children: cards,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
