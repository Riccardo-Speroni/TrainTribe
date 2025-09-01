import 'package:flutter/material.dart';

/// Model describing a single legend item.
class LegendItem {
  final Color ringColor;
  final Color glowColor;
  final String label;
  final bool showCheck;
  final bool isUser; // Reserved for future styling needs.
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData icon;

  const LegendItem({
    required this.ringColor,
    required this.glowColor,
    required this.label,
    this.showCheck = false,
    this.isUser = false,
    this.backgroundColor,
    this.iconColor,
    this.icon = Icons.person,
  });
}

/// Shows a reusable legend dialog.
/// Provide a [title], a list of [items], and optional [infoText].
Future<void> showLegendDialog({
  required BuildContext context,
  required String title,
  required List<LegendItem> items,
  String? infoText,
  String okLabel = 'OK',
}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final subtleTextColor = theme.brightness == Brightness.dark
          ? theme.colorScheme.onSurfaceVariant.withOpacity(0.92)
          : theme.colorScheme.onSurfaceVariant.withOpacity(0.78);
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                for (int i = 0; i < items.length; i++) ...[
                  _LegendRow(item: items[i]),
                  if (i != items.length - 1) const SizedBox(height: 14),
                ],
                if (infoText != null && infoText.trim().isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    infoText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.35,
                      color: subtleTextColor,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ],
            ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: Text(okLabel),
          ),
        ],
      );
    },
  );
}

class _LegendRow extends StatelessWidget {
  final LegendItem item;
  const _LegendRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: item.ringColor, width: 2),
                boxShadow: [
                  if (item.glowColor != Colors.transparent)
                    BoxShadow(color: item.glowColor.withOpacity(0.6), blurRadius: 6, spreadRadius: 1),
                ],
                color: item.backgroundColor ?? Colors.white,
              ),
              child: Icon(item.icon, size: 16, color: item.iconColor ?? Colors.grey),
            ),
            if (item.showCheck)
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: item.ringColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: item.ringColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 0.5),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 9, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(item.label)),
      ],
    );
  }
}
