import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Smart Avatar — image ho to image, warna icon. Triple-safe fallback!
///
/// Rules:
/// 1. [imagePath] null/empty → icon
/// 2. [imagePath] set → image
/// 3. Image load fail → icon (errorBuilder)
///
/// Backend-ready: imagePath user account se aayega (Firebase photoURL).
/// User ne pic set ki → URL | remove ki → null → icon wapas. Bas!
///
/// Family avatars, user avatar, comment avatars — SAB yahi use karenge.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.size,
    this.imagePath,
    this.icon = Icons.person,
    this.ringColor,
    this.ringWidth = 0,
  });

  final double size;

  /// null = icon. Abhi asset path — backend aane par network URL.
  final String? imagePath;

  final IconData icon;

  /// Selection ring (family member wali green ring!)
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: ringWidth > 0 ? const EdgeInsets.all(2) : null,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: (ringColor != null && ringWidth > 0)
            ? Border.all(color: ringColor!, width: ringWidth)
            : null,
      ),
      child: ClipOval(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: _content,
        ),
      ),
    );
  }

  Widget get _content {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (hasImage) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        // Image missing/corrupt → icon (app kabhi crash nahi)
        errorBuilder: (context, error, stackTrace) => _iconBox,
      );
    }

    return _iconBox;
  }

  Widget get _iconBox {
    return Container(
      color: AppColors.avatarFill,
      child: Icon(icon, size: size * 0.55, color: AppColors.fieldHint),
    );
  }
}
