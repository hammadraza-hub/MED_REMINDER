import 'package:flutter/material.dart';

/// ============================================================
/// MEMBER PERMISSIONS — DATA
///
/// PURPOSE:
/// Caregiver (e.g. Mom) ke liye access level (Viewer / Co-Manager)
/// aur granular visibility toggles ka model + dummy provider.
///
/// SCREEN:
/// features/profile/member_permissions_screen.dart ise use karta hai.
///
/// TODO Backend:
/// Firestore mein `members/{memberId}` par accessLevel aur
/// permissions map ({doseLog: true, medicationList: true, ...})
/// read/write hoga. Abhi yeh sirf in-memory dummy data hai.
/// ============================================================

/// Caregiver ka role — do options.
enum AccessLevel { viewer, coManager }

extension AccessLevelLabel on AccessLevel {
  /// Radio row ka title.
  String get label => this == AccessLevel.viewer ? 'Viewer' : 'Co-Manager';

  /// Radio row ka subtitle.
  String get description => this == AccessLevel.viewer
      ? 'See adherence & scheduled doses only'
      : 'Edit medication schedules & log doses';
}

/// Ek visibility toggle row.
class PermissionCategory {
  const PermissionCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isEnabled,
  });

  /// Stable key (Firestore map key ke liye).
  final String id;

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isEnabled;

  PermissionCategory copyWith({bool? isEnabled}) => PermissionCategory(
        id: id,
        title: title,
        subtitle: subtitle,
        icon: icon,
        isEnabled: isEnabled ?? this.isEnabled,
      );
}

/// Screen par load hone wala member + uske permissions.
class MemberPermissionProfile {
  const MemberPermissionProfile({
    required this.memberId,
    required this.displayName,
    required this.relationship,
    required this.linkedSinceLabel,
    this.profileImagePath,
    required this.accessLevel,
    required this.categories,
  });

  final String memberId;
  final String displayName;
  final String relationship;

  /// e.g. "01 Sep 2026" — null jab join date na ho (TODO Backend).
  final String? linkedSinceLabel;
  final String? profileImagePath;
  final AccessLevel accessLevel;
  final List<PermissionCategory> categories;
}

/// Dummy provider — sirf design-mock data.
class MemberPermissionsData {
  MemberPermissionsData._();

  static const String defaultMemberId = 'local_mom';

  /// Member ke permissions (abhi sirf Mom ke liye full dummy data).
  ///
  /// Caller (Linked-Profile Dashboard) asli member details override
  /// kar sakta hai — tab screen per-member data dikhati hai.
  static MemberPermissionProfile profileForMember(
    String memberId, {
    String? displayName,
    String? relationship,
    String? profileImagePath,
  }) {
    // TODO Backend: Firestore permission doc fetch + member record join.
    final bool isMom = memberId == defaultMemberId;

    return MemberPermissionProfile(
      memberId: memberId,
      displayName: displayName ?? (isMom ? 'Mom' : 'Member'),
      relationship: relationship ?? 'Mother',
      linkedSinceLabel: isMom ? '01 Sep 2026' : null,
      profileImagePath: profileImagePath,
      accessLevel: AccessLevel.coManager,
      categories: defaultCategories(),
    );
  }

  /// HTML design ke exact 4 toggles:
  /// doseLog ON, medicationList ON, vitals OFF, reportsExport OFF.
  static List<PermissionCategory> defaultCategories() {
    return const [
      PermissionCategory(
        id: 'doseLog',
        title: 'Dose log & adherence',
        subtitle: 'Real-time daily status checks',
        icon: Icons.checklist,
        isEnabled: true,
      ),
      PermissionCategory(
        id: 'medicationList',
        title: 'Medication list',
        subtitle: 'Names, pill colors & strengths',
        icon: Icons.medication_outlined,
        isEnabled: true,
      ),
      PermissionCategory(
        id: 'vitals',
        title: 'Vitals & health data',
        subtitle: 'Blood pressure, heart rate logs',
        icon: Icons.favorite_border,
        isEnabled: false,
      ),
      PermissionCategory(
        id: 'reportsExport',
        title: 'Reports export',
        subtitle: 'PDF summaries for physician visits',
        icon: Icons.download_for_offline,
        isEnabled: false,
      ),
    ];
  }
}
