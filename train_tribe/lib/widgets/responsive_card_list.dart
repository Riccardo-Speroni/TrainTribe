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
          final crossAxisCount = (constraints.maxWidth / 200).floor().clamp(2, 5);

            return StaggeredGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
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
            );
          } else {
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return cards[index];
            },
          );
        }
      },
    );
  }
}