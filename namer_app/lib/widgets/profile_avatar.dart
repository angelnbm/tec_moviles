import 'package:flutter/material.dart';
import 'dart:convert';

class ProfileAvatar extends StatelessWidget {
  final String? profileImageBase64;
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  const ProfileAvatar({
    super.key,
    this.profileImageBase64,
    this.radius = 30,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;

    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      try {
        final base64String = profileImageBase64!.split(',').last;
        final bytes = base64Decode(base64String);
        avatarWidget = CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        avatarWidget = CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: Icon(
            Icons.person,
            size: radius * 0.9,
            color: const Color(0xFFD32F2F),
          ),
        );
      }
    } else {
      avatarWidget = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: Icon(
          Icons.person,
          size: radius * 0.9,
          color: const Color(0xFFD32F2F),
        ),
      );
    }

    if (borderWidth > 0) {
      return Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? const Color(0xFFD32F2F),
            width: borderWidth,
          ),
        ),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
