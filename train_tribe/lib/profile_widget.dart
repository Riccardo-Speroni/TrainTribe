import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';

class ProfilePicture extends StatelessWidget {
  final String? picture; // URL or initials
  final double size;

  const ProfilePicture({Key? key, required this.picture, this.size = 75.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: Colors.teal,
      foregroundImage: (picture != null && picture!.startsWith('http'))
          ? NetworkImage(picture!) // Use the URL if it's a valid image link
          : null,
      child: (picture == null || picture!.startsWith('http'))
          ? Initicon(
              text: picture ?? "?", // Use initials or a fallback "?"
              backgroundColor: Colors.transparent,
              style: TextStyle(
                color: Colors.white,
                fontSize: size / 2,
                fontWeight: FontWeight.bold,
              ),
              size: size * 2, // Match the CircleAvatar's diameter
            )
          : null,
    );
  }
}
