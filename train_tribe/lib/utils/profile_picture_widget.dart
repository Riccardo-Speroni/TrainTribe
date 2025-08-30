import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  final String? picture; // URL or stored initials/text
  final double size; // radius
  final VoidCallback? onTap;
  final bool showEditIcon;
  final int ringWidth; // >0 draws green ring of this thickness
  // Fallback sources for initials if picture is null/empty or removed
  final String? firstName;
  final String? lastName;
  final String? username;

  const ProfilePicture({
    super.key,
    required this.picture,
    this.size = 75.0,
    this.onTap,
    this.showEditIcon = false,
    this.firstName,
    this.lastName,
    this.username,
    this.ringWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
  final bool hasNetwork = picture != null && picture!.startsWith('http');
    final String initials = _buildInitials();
    final avatarCore = CircleAvatar(
      radius: size,
      backgroundColor: Colors.teal,
      foregroundImage: hasNetwork ? NetworkImage(picture!) : null,
      child: hasNetwork
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
    );

    final avatar = ringWidth > 0
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: ringWidth.toDouble()),
            ),
            child: ClipOval(child: avatarCore),
          )
        : avatarCore;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: avatar,
        ),
        if (showEditIcon)
          Positioned(
            bottom: -2,
            right: -2,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.translucent,
              child: Semantics(
                button: true,
                label: 'Edit profile picture',
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _buildInitials() {
    // If explicit non-URL picture string is provided (custom initials), keep it.
    if (picture != null && picture!.isNotEmpty && !picture!.startsWith('http')) {
      final trimmed = picture!.trim();
      // If user stored custom initials (possibly with space) keep first two meaningful chars excluding spaces.
      final chars = trimmed.replaceAll(RegExp(r'\s+'), '');
      if (chars.isNotEmpty) {
        return chars.substring(0, chars.length.clamp(0, 2)).toUpperCase();
      }
    }

    String first = (firstName ?? '').trim();
    String last = (lastName ?? '').trim();

    // Fallback to username if both names empty.
    if (first.isEmpty && last.isEmpty) {
      final un = (username ?? '').trim();
      if (un.isNotEmpty) return un.substring(0, 1).toUpperCase();
      return '?';
    }

  String takeInitial(String s) => s.isEmpty ? '' : s[0].toUpperCase();

    final fi = takeInitial(first);
    final li = takeInitial(last);
  final combined = (fi + li);
    if (combined.isNotEmpty) return combined;
    return '?';
  }
}
