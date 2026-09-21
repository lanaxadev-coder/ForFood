// ============================================================
// PROFILE AVATAR — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;
    final avatarSize = size * widthScale;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: const ShapeDecoration(
        color: AppColor.yellow2,
        shape: OvalBorder(),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? (imageUrl!.startsWith('http://') ||
                    imageUrl!.startsWith('https://'))
                // ✅ Remote URL → Image.network
                ? Image.network(
                    imageUrl!,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(avatarSize),
                  )
                // ✅ Local file path → Image.file
                : Image.file(
                    File(imageUrl!),
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(avatarSize),
                  )
            : _fallback(avatarSize),
      ),
    );
  }

  Widget _fallback(double avatarSize) {
    return Container(
      color: AppColor.yellow2,
      child: Icon(
        Icons.person,
        size: avatarSize * 0.55,
        color: AppColor.nearWhite,
      ),
    );
  }
}