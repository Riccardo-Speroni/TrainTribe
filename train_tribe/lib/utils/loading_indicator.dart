import 'package:flutter/material.dart';

class LoadingIndicator extends StatefulWidget {
  final Duration delay;
  const LoadingIndicator({super.key, this.delay = const Duration(milliseconds: 300)});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    return Container(
      color: Colors.black.withOpacity(0.5), // Semi-transparent background
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
