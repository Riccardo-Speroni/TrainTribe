part of '../train_card.dart';

// Simple hover detector wrapper for desktop/web to provide hover state.
class _Hoverable extends StatefulWidget {
  final Widget Function(bool hovering) builder;
  const _Hoverable({required this.builder});

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hovering = false;

  void _setHover(bool value) {
    if (_hovering != value) {
      setState(() => _hovering = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: widget.builder(_hovering),
    );
  }
}
