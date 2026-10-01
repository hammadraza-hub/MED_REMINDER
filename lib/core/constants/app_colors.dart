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
  // ================= MEDS (quick tools + progress) =================
  /// MANAGE tile icon box background
  static const Color manageIconFill = Color(0xFFE3F1EF);

  /// Low-stock badge background (halki red)
  static const Color lowBadgeBackground = Color(0xFFFFDFDF);

  /// Low-stock badge text/icon red
  static const Color lowBadgeText = Color(0xFFFF4C4C);

  /// Count badge ki light red border
  static const Color lowBadgeBorder = Color(0xFFFF7B7B);

  /// Progress bar ka empty track
  static const Color progressTrackLight = Color(0xFFE5E5E5);

  /// Search hint text
  static const Color searchHint = Color(0xFFA4BAC3);

  /// Step indicator — active circle green
  static const Color stepActive = Color(0xFF008467);

  /// Step indicator — inactive circle background
  static const Color stepInactiveBg = Color(0xFFF0F7F5);

  /// Step indicator — inactive text
  static const Color stepInactiveText = Color(0xFF76AFA6);

  /// Step indicator — track line
  static const Color stepTrack = Color(0xFFDCE7E7);

  /// Editable field ka green border (OCR data feel)
  static const Color fieldEditBorder = Color(0xFF008467);

  /// Editable field ka halka fill
  static const Color fieldEditFill = Color(0xFFF8FCFB);

  /// Field hint text (light)
  static const Color fieldHintLight = Color(0xFF9BAEB4);

  /// Scanner frame ka bright green (CustomPainter mein use)
  static const Color scannerFrame = Color(0xFF00D69A);

  /// READY badge ka green
  static const Color scannerGreen = Color(0xFF00A478);

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

  // ================= MEDICATION COLOR SELECTOR =================
  /// Add Manual screen — medicine physical color options.
  /// Screen mein direct hex use nahi hoga.

  /// White medicine
  static const Color medicineWhite = Colors.white;

  /// Yellow medicine
  static const Color medicineYellow = Color(0xFFFFE878);

  /// Pink medicine
  static const Color medicinePink = Color(0xFFFFB7D2);

  /// Blue medicine
  static const Color medicineBlue = Color(0xFFBEE7FA);

  /// Orange medicine
  static const Color medicineOrange = Color(0xFFFFD3A7);

  /// Peach medicine
  static const Color medicinePeach = Color(0xFFFFC0BD);

  /// Green medicine
  static const Color medicineGreen = Color(0xFF00745C);
  // ================= UTILITY =================
  /// Fully transparent — dialogs / overlays ke liye
  static const Color transparent = Colors.transparent;
  // ================= CALENDAR / ADHERENCE =================
  /// Calendar header toggle background
  static const Color calendarToggleBackground = Color(0xFF326B82);

  /// Calendar header secondary button
  static const Color calendarHeaderButton = Color(0xFF1E607B);

  /// Calendar circular previous/next buttons
  static const Color calendarCircleButton = Color(0xFF28677F);

  /// Calendar weekday labels
  static const Color calendarWeekdayText = Color(0xFF39768A);

  /// Day with all doses taken
  static const Color calendarTaken = Color(0xFF008768);

  /// Taken day light background
  static const Color calendarTakenBackground = Color(0xFFE7F5EF);

  /// Partial adherence
  static const Color calendarPartial = Color(0xFFFFAD17);

  /// Partial day light background
  static const Color calendarPartialBackground = Color(0xFFFFF1CF);

  /// Missed adherence
  static const Color calendarMissed = Color(0xFFE94F5D);

  /// Missed day light background
  static const Color calendarMissedBackground = Color(0xFFFFE6E8);

  /// Today indicator
  static const Color calendarToday = Color(0xFF08728D);

  /// Calendar muted / no-data day
  static const Color calendarNoDataBackground = Color(0xFFF3F7F9);

  /// Calendar muted day text
  static const Color calendarNoDataText = Color(0xFFB8C9D1);

  /// Calendar dose card background
  static const Color calendarDoseBackground = Color(0xFFF5F8FA);

  /// Calendar legend secondary text
  static const Color calendarLegendText = Color(0xFF416979);
  // ================= ADHERENCE DETAIL =================

  /// Taken summary card
  static const Color adherenceTakenBackground = Color(0xFFE8F6F1);

  /// Missed summary card
  static const Color adherenceMissedBackground = Color(0xFFFFE8E8);

  /// Skipped summary card
  static const Color adherenceSkippedBackground = Color(0xFFFFF5DE);

  /// Skipped status
  static const Color adherenceSkipped = Color(0xFFF2A000);

  /// Adherence secondary card background
  static const Color adherenceCardBackground = Color(0xFFF7FAFB);

  static const Color adherenceExportGreen = Color(0xFF36B37E);
  static const Color adherenceExportRed = Color(0xFFE85D68);
  static const Color adherenceExportBlue = Color(0xFF2F80ED);
  // ============================================================
  // STREAKS & STATS
  // ============================================================

  static const Color streakHeader = Color(0xFF075A78);
  static const Color streakHeaderCard = Color(0xFF176B85);

  static const Color streakFire = Color(0xFFFF6B1A);
  static const Color streakFireBackground = Color(0xFFFFEFE5);

  static const Color streakGold = Color(0xFFF5A300);
  static const Color streakGoldBackground = Color(0xFFFFF4D8);

  static const Color streakMint = Color(0xFF00896D);
  static const Color streakMintBackground = Color(0xFFE9F6F1);

  static const Color streakTrend = Color(0xFF087B70);
  static const Color streakTrendTarget = Color(0xFFF2A000);
  static const Color streakTrendGrid = Color(0xFFDDE9ED);

  static const Color streakAchievementBackground = Color(0xFFF8FAFB);
  static const Color streakCardShadow = Color(0x140A4054);

  // Home streak pill
  static const Color homeStreakPill = Color(0xFFFF7A1A);
  static const Color homeStreakPillText = Color(0xFFFFFFFF);
  static const Color homeStreakFlame = Color(0xFFFFD54F);
  // ============================================================
  // MISSED DOSE REASON MODAL
  // ============================================================

  static const Color missedReasonDanger = Color(0xFFE84F5F);
  static const Color missedReasonDangerBackground = Color(0xFFFFECEE);

  static const Color missedReasonSelected = Color(0xFF00866A);
  static const Color missedReasonSelectedBackground = Color(0xFFE8F5F1);

  static const Color missedReasonWarning = Color(0xFFF2A000);
  static const Color missedReasonWarningBackground = Color(0xFFFFF5DF);

  static const Color missedReasonFieldBackground = Color(0xFFF3F7F8);
  static const Color missedReasonBorder = Color(0xFFD6E5E7);
  static const Color missedReasonCloseBackground = Color(0xFFF0F6F5);
  // ============================================================
  // INVENTORY
  // ============================================================
  // ================= INVENTORY =================

  static const Color inventoryLow = Color(0xFFCF1B1F);
  static const Color inventoryLowBackground = Color(0xFFFFE9E9);

  static const Color inventoryOk = Color(0xFF00866A);
  static const Color inventoryOkBackground = Color(0xFFE8F5F1);

  static const Color inventoryWarning = Color(0xFFCF1B1F);
  static const Color inventoryProgressTrack = Color(0xFFE5EDEF);

  static const Color inventorySyncBackground = Color(0xFFDCEFED);
  static const Color inventoryAdjustBackground = Color(0xFFE6F2F0);
  static const Color inventoryFilterBackground = Color(0xFFF4F8F8);

  static const Color inventoryCardShadow = Color(0x120A4054);
  static const Color inventoryBorder = Color(0xFFD6E5E7);
}
