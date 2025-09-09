import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import '../l10n/app_localizations.dart';
import '../utils/mood_repository.dart';

/// Reusable slider/toggle for selecting the user's mood (solo / group).
/// Handles:
///  - Loading current mood from Firestore (if not provided)
///  - Debounced persistence
///  - Immediate visual sync of background color
///  - Error handling with SnackBar and revert
class MoodToggle extends StatefulWidget {
  final bool? initialValue; // if null, it loads from Firestore
  final double width;
  final Duration saveDebounce;
  final Duration animationDuration;
  final void Function(bool value)? onChanged; // callback after local state change
  final MoodRepository? repository; // injectable
  final String? userIdOverride; // testing override

  const MoodToggle({
    super.key,
    this.initialValue,
    this.width = 260,
    this.saveDebounce = const Duration(milliseconds: 500),
    this.animationDuration = const Duration(milliseconds: 300),
    this.onChanged,
    this.repository,
    this.userIdOverride,
  });

  @override
  State<MoodToggle> createState() => _MoodToggleState();
}

class _MoodToggleState extends State<MoodToggle> {
  bool _value = true; // true = group, false = solo
  Timer? _debounce;
  bool _loaded = false; // becomes true after initial value resolved

  @override
  void initState() {
    super.initState();
    final init = widget.initialValue;
    if (init != null) {
      _value = init;
      _loaded = true;
    } else {
      _loadFromFirestore();
    }
  }

  Future<void> _loadFromFirestore() async {
    // Skip remote load if Firebase not initialized (e.g. widget tests) to avoid exceptions.
    if (Firebase.apps.isEmpty) {
      setState(() => _loaded = true);
      return;
    }
    final userId = widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final repo = widget.repository ?? FirebaseMoodRepository();
      final newVal = await repo.load(userId);
      if (!mounted) return;
      setState(() {
        _value = newVal;
        _loaded = true;
      });
    } catch (e) {
      // ignore - keep defaults
    }
  }

  void _toggle(bool v) {
    final userId = widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // cannot save; ignore
    setState(() {
      _value = v;
    });
    widget.onChanged?.call(v);
    _debounce?.cancel();
    _debounce = Timer(widget.saveDebounce, () async {
      try {
        final repo = widget.repository ?? FirebaseMoodRepository();
        await repo.save(userId, v);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _value = !v; // revert
        });
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.translate('unexpected_error'))),
        );
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = !_loaded;
    return SizedBox(
      width: widget.width,
      height: 70,
      child: loading
          ? Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)))
          : AnimatedToggleSwitch<bool>.dual(
              current: _value,
              first: false,
              second: true,
              spacing: 100.0,
              style: ToggleStyle(
                indicatorColor: Colors.white,
        backgroundColor: _value
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
          : Theme.of(context).colorScheme.error.withValues(alpha: 0.18),
              ),
              borderWidth: 4.0,
              customIconBuilder: (context, local, global) {
                return Icon(
                  _value ? Icons.groups : Icons.person_outline,
                  color: _value ? Colors.green : Colors.red,
                  size: 34,
                );
              },
              height: 70,
              onChanged: _toggle,
              animationCurve: Curves.easeInOut,
              animationDuration: widget.animationDuration,
            ),
    );
  }
}
