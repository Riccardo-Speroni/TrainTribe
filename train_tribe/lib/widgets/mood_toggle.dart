import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import '../l10n/app_localizations.dart';

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

  const MoodToggle({
    super.key,
    this.initialValue,
    this.width = 260,
    this.saveDebounce = const Duration(milliseconds: 500),
    this.animationDuration = const Duration(milliseconds: 300),
    this.onChanged,
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      bool newVal = true;
      if (snap.exists) {
        final mood = snap.data()?['mood'];
        if (mood is bool) {
          newVal = mood;
        } else {
          // ensure field exists
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({'mood': newVal}, SetOptions(merge: true));
        }
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'mood': newVal}, SetOptions(merge: true));
      }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // cannot save; ignore
    setState(() {
      _value = v;
    });
    widget.onChanged?.call(v);
    _debounce?.cancel();
    _debounce = Timer(widget.saveDebounce, () async {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'mood': v}, SetOptions(merge: true));
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
