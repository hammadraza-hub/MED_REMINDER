/// ============================================================
/// PRIVACY & SECURITY DATA — backend-ready
///
/// PURPOSE:
/// Settings → Privacy & Security screen ka biometric default,
/// active sessions list aur policy/trust copy.
///
/// Backend: Future mein real session management (sign out remote
/// devices) aur biometric auth (local_auth) yahan se wire honge.
/// ============================================================
library;

import 'package:flutter/material.dart';

/// Ek active device session.
class ActiveSession {
  const ActiveSession({
    required this.icon,
    required this.deviceName,
    required this.lastActive,
    this.isCurrent = false,
  });

  final IconData icon;

  final String deviceName;

  final String lastActive;

  /// true → "this device" (sign out allow nahi).
  final bool isCurrent;
}

class PrivacySecurityData {
  PrivacySecurityData._();

  /// Face ID / biometric lock default (design: ON).
  static const bool defaultBiometricLock = true;

  /// Active Sessions section — screen order.
  static const List<ActiveSession> sessions = [
    ActiveSession(
      icon: Icons.smartphone_rounded,
      deviceName: 'iPhone 15 — this device',
      lastActive: 'Last active: now',
      isCurrent: true,
    ),
    ActiveSession(
      icon: Icons.tablet_mac_rounded,
      deviceName: 'iPad Pro',
      lastActive: 'Last active: 2 days ago',
    ),
  ];

  static const String policyTitle = 'Privacy Policy & HIPAA Terms';

  static const String trustNote =
      'Your health data is end-to-end encrypted with zero-knowledge keys '
      'and never sold to third parties.';
}
