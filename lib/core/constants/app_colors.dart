import 'package:flutter/material.dart';

/// App ki SAARI colors sirf yahan define hoti hain.
/// Kisi bhi screen mein hex color hardcode na karein — hamesha AppColors use karein.
class AppColors {
  AppColors._(); // private constructor — direct instance banane se rokta hai

  // ================= PRIMARY GREEN =================
  /// Main app green — buttons, active dots (onboarding design se)
  static const Color primary = Color(0xFF007A5E);

  /// Primary ka dark shade — button shadows
  static const Color primaryDark = Color(0xFF006F56);

  /// Primary ka halka tint — fallback backgrounds
  static const Color primaryLight = Color(0xFFEAF3F3);

  // ================= BRAND (SPLASH) =================
  /// Splash logo image wala teal — sirf splash screen mein
  static const Color brandTeal = Color(0xFF137A73);

  /// Brand pill ke chhote circle logo ka green
  static const Color logoBadge = Color(0xFF168D7A);

  // ================= INPUTS =================
  /// Text fields ka halka fill — borderless design style
  static const Color inputFill = Color(0xFFF0F5F5);

  // ================= TEXT =================
  /// Headings aur titles — dark navy
  static const Color textPrimary = Color(0xFF003F5C);

  /// Subtitles, Skip text — teal
  static const Color textTeal = Color(0xFF08718A);

  /// Input hints, muted text — grey
  static const Color textSecondary = Color(0xFF6B7280);

  // ================= BACKGROUNDS =================
  /// Scaffold background — halka blueish white
  static const Color background = Color(0xFFF8FBFD);

  /// Cards, sheets — pure white
  static const Color surface = Colors.white;

  // ================= DOTS / INDICATORS =================
  static const Color dotInactive = Color(0xFFC4DDDA);

  // ================= BORDERS =================
  static const Color divider = Color(0xFFE5E7EB);

  // ================= ACCENTS (logo design se) =================
  static const Color accentYellow = Color(0xFFF1C40F);
  static const Color accentOrange = Color(0xFFE8853D);

  // ================= STATUS =================
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF22C55E);

  /// Success banner background — halki green tint (reset password)
  static const Color successBackground = Color(0xFFE5F4EE);
  // ================= HINT CARD (Notifications) =================
  /// Warning card ka halka yellow background
  static const Color hintBackground = Color(0xFFFEF7E6);

  /// Warning card ki yellow stripe/icon
  static const Color hintAccent = Color(0xFFF5A623);

  /// Hint card ka dark brown text
  static const Color hintText = Color(0xFF6B5B3E);

  // ================= DOSE STATUS (Home) =================
  /// Upcoming dose ka blue
  static const Color statusUpcoming = Color(0xFF3D7AB8);

  /// Pending chip ka halka orange background
  static const Color pendingBackground = Color(0xFFFDF0E3);

  /// Upcoming chip ka halka blue background
  static const Color upcomingBackground = Color(0xFFE8F0FB);

  /// Pending badge ka dark orange text
  static const Color statusPendingText = Color(0xFFB7791F);

  /// Medication card ki halki fill
  static const Color cardFill = Color(0xFFEDF2F0);
  // ================= HOME HEADER (dark design) =================
  /// Header ka dark teal background
  static const Color headerDark = Color(0xFF00566C);

  /// Header ke andar halka text (date, sub-labels)
  static const Color headerSubtext = Color(0xFFD2E2E6);

  /// Streak badge ka green
  static const Color streakGreen = Color(0xFF7FE0A8);

  /// Streak flame icon color
  static const Color streakFlame = Color(0xFF7FE0A8);

  /// Family avatar circle ki fill
  static const Color avatarFill = Color(0xFFD8E4E6);

  /// Family avatar ka selected ring (mint green)
  static const Color avatarSelected = Color(0xFF20C6A1);

  /// Progress ring ka track
  static const Color progressTrack = Color(0xFFE1E8E8);

  /// Notification red dot
  static const Color notificationDot = Color(0xFFFF4D4D);

  // ================= FORM (Signup design ke exact colors) =================
  /// Signup design ka action green — buttons, links, strength bars
  static const Color formAccent = Color(0xFF007A67);

  /// Signup input fields ka border
  static const Color fieldBorder = Color(0xFF0D7890);

  /// Signup input fields ka halka fill
  static const Color fieldFill = Color(0xFFF5FAFB);

  /// Input placeholder text
  static const Color fieldHint = Color(0xFF94B3BF);

  /// Input icons + checkbox border
  static const Color formIcon = Color(0xFF087C91);

  /// Subtitle aur "Already have..." text
  static const Color formSubtitle = Color(0xFF08738A);

  /// Google button jaisi light border
  static const Color outline = Color(0xFFD9E0E3);

  /// Divider lines
  static const Color hairline = Color(0xFFDDE5E8);

  /// "or continue with" muted text
  static const Color mutedText = Color(0xFF9BB3BD);

  /// Strength bar ka khali segment
  static const Color barEmpty = Color(0xFFE0E6E8);

  /// Pills fallback background
  static const Color pillPlaceholder = Color(0xFFF1F7F7);
}
