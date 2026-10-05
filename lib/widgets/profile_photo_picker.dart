import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../core/profile/profile_controller.dart';

/// ============================================================
/// PROFILE PHOTO PICKER
///
/// Reusable profile-photo flow.
///
/// CURRENT LOCAL FLOW:
/// Gallery / Camera
///      ↓
/// image_picker
///      ↓
/// ProfileController
///      ↓
/// LocalProfileRepository
///      ↓
/// App Documents directory
///      ↓
/// All AppAvatar widgets update
///
/// FUTURE FIREBASE FLOW:
/// Gallery / Camera
///      ↓
/// ProfileController
///      ↓
/// FirebaseProfileRepository
///      ↓
/// Firebase Storage + Firestore
///
/// UI ko storage implementation change karne ki zarurat nahi hogi.
/// ============================================================

Future<void> showProfilePhotoPicker(BuildContext context) async {
  final action = await showModalBottomSheet<_ProfilePhotoAction>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return const _ProfilePhotoPickerSheet();
    },
  );

  if (action == null || !context.mounted) {
    return;
  }

  switch (action) {
    case _ProfilePhotoAction.gallery:
      await _pickAndSaveImage(context, source: ImageSource.gallery);
      break;

    case _ProfilePhotoAction.camera:
      await _pickAndSaveImage(context, source: ImageSource.camera);
      break;

    case _ProfilePhotoAction.remove:
      await _removeProfileImage(context);
      break;
  }
}

// ============================================================
// ACTIONS
// ============================================================

enum _ProfilePhotoAction { gallery, camera, remove }

// ============================================================
// PICK + SAVE
// ============================================================

Future<void> _pickAndSaveImage(
  BuildContext context, {
  required ImageSource source,
}) async {
  try {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1400,
      maxHeight: 1400,
    );

    if (image == null || !context.mounted) {
      return;
    }

    await ProfileController.instance.saveProfileImage(image.path);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully ✓')),
      );

    // TODO Backend / Firebase Storage:
    // FirebaseProfileRepository active hone par isi controller call ke
    // through image Storage par upload aur Firestore URL update hoga.
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Could not update profile photo. Please try again.'),
        ),
      );

    debugPrint('Profile image selection failed: $error');
  }
}

// ============================================================
// REMOVE
// ============================================================

Future<void> _removeProfileImage(BuildContext context) async {
  try {
    await ProfileController.instance.removeProfileImage();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile photo removed')));
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Could not remove profile photo. Please try again.'),
        ),
      );

    debugPrint('Profile image removal failed: $error');
  }
}

// ============================================================
// BOTTOM SHEET
// ============================================================

class _ProfilePhotoPickerSheet extends StatelessWidget {
  const _ProfilePhotoPickerSheet();

  @override
  Widget build(BuildContext context) {
    final hasProfileImage = ProfileController.instance.profileImagePath != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Profile Photo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Choose how you want to update your profile photo.',
              style: TextStyle(color: AppColors.formSubtitle, fontSize: 14),
            ),

            const SizedBox(height: 20),

            _PhotoActionTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from Gallery',
              subtitle: 'Select a photo already on this device',
              onTap: () {
                Navigator.of(context).pop(_ProfilePhotoAction.gallery);
              },
            ),

            const SizedBox(height: 10),

            _PhotoActionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take a Photo',
              subtitle: 'Use your camera to take a new photo',
              onTap: () {
                Navigator.of(context).pop(_ProfilePhotoAction.camera);
              },
            ),

            if (hasProfileImage) ...[
              const SizedBox(height: 10),

              _PhotoActionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Remove Photo',
                subtitle: 'Return to the default profile icon',
                destructive: true,
                onTap: () {
                  Navigator.of(context).pop(_ProfilePhotoAction.remove);
                },
              ),
            ],

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACTION TILE
// ============================================================

class _PhotoActionTile extends StatelessWidget {
  const _PhotoActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accentColor = destructive ? AppColors.error : AppColors.formAccent;

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: destructive
                      ? AppColors.hintBackground
                      : AppColors.successBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accentColor, size: 23),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive
                            ? AppColors.error
                            : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(Icons.chevron_right_rounded, color: accentColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
