import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/profile/profile_controller.dart';

/// ============================================================
/// APP AVATAR — centralized profile image renderer
///
/// IMAGE SUPPORT:
/// 1. Explicit [imagePath] diya ho → wahi image use hogi
/// 2. [imagePath] na diya ho aur [useSelectedProfileImage] true ho
///    → current selected profile ki image
/// 3. [useSelectedProfileImage] false ho aur imagePath null ho
///    → fallback person icon
/// 4. assets/... → Image.asset
/// 5. http / https → Image.network
/// 6. Device/app local file path → Image.file
/// 7. Missing/broken image → fallback icon
///
/// IMPORTANT:
/// Family-member avatars ke liye [useSelectedProfileImage] false
/// use karo. Isse Sarah ki selected/global image Mom/Jake ke
/// null image path par leak nahi hogi.
///
/// CURRENT STORAGE:
/// LocalProfileRepository image ko app documents directory mein
/// save karta hai.
///
/// FUTURE:
/// FirebaseProfileRepository Firebase Storage URL provide karegi.
/// AppAvatar ko rewrite nahi karna padega.
/// ============================================================
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.size,
    this.imagePath,
    this.useSelectedProfileImage = true,
    this.icon = Icons.person,
    this.ringColor,
    this.ringWidth = 0,
  });

  final double size;

  /// Supported values:
  /// - assets/images/profile.jpg
  /// - /device/app/documents/profiles/member.jpg
  /// - https://firebase...
  final String? imagePath;

  /// true:
  /// [imagePath] null ho to currently selected ProfileController
  /// image use hogi.
  ///
  /// false:
  /// [imagePath] null ho to fallback icon use hoga.
  ///
  /// Family member lists mein false use karo taake har member
  /// ki image isolated rahe.
  final bool useSelectedProfileImage;

  final IconData icon;

  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    // Explicit/member-only avatar ko global ProfileController ki
    // changes listen karne ki zarurat nahi.
    if (!useSelectedProfileImage) {
      return _buildAvatar(imagePath);
    }

    return ListenableBuilder(
      listenable: ProfileController.instance,
      builder: (context, child) {
        final effectiveImagePath =
            imagePath ?? ProfileController.instance.profileImagePath;

        return _buildAvatar(effectiveImagePath);
      },
    );
  }

  // ============================================================
  // AVATAR SHELL
  // ============================================================

  Widget _buildAvatar(String? effectiveImagePath) {
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
          child: _buildContent(effectiveImagePath),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(String? value) {
    final path = value?.trim();

    if (path == null || path.isEmpty) {
      return _iconBox;
    }

    if (_isNetworkImage(path)) {
      return _buildNetworkImage(path);
    }

    if (_isAssetImage(path)) {
      return _buildAssetImage(path);
    }

    return _buildLocalFileImage(path);
  }

  // ============================================================
  // TYPE DETECTION
  // ============================================================

  bool _isNetworkImage(String path) {
    final uri = Uri.tryParse(path);

    if (uri == null) {
      return false;
    }

    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  bool _isAssetImage(String path) {
    return path.startsWith('assets/');
  }

  // ============================================================
  // ASSET IMAGE
  // ============================================================

  Widget _buildAssetImage(String path) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return _iconBox;
      },
    );
  }

  // ============================================================
  // LOCAL FILE IMAGE
  // ============================================================

  Widget _buildLocalFileImage(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return _iconBox;
      },
    );
  }

  // ============================================================
  // NETWORK / FIREBASE STORAGE
  // ============================================================

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _loadingBox;
      },
      errorBuilder: (context, error, stackTrace) {
        return _iconBox;
      },
    );
  }

  // ============================================================
  // FALLBACK
  // ============================================================

  Widget get _iconBox {
    return Container(
      color: AppColors.avatarFill,
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.55, color: AppColors.fieldHint),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget get _loadingBox {
    return Container(
      color: AppColors.avatarFill,
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.34,
        height: size * 0.34,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.formAccent,
        ),
      ),
    );
  }
}
