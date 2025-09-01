import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? iconWidget;
  final Color color;
  final VoidCallback onPressed;

  const CustomTextButton({
    super.key,
    required this.text,
    this.icon,
    this.iconWidget,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      icon: iconWidget ?? (icon != null ? Icon(icon, color: Colors.white, size: 18) : const SizedBox.shrink()),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
