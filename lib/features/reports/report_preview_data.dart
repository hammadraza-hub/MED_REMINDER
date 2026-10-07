import 'package:flutter/material.dart';

/// ============================================================
/// REPORT PREVIEW DATA
///
/// Dummy content for the Clinical Adherence Report (PDF preview).
/// HTML design ke exact values yahan se aati hain.
///
/// TODO Backend:
/// Patient name, date range, adherence %, week calendar,
/// vitals aur share options backend par depend karte hain.
/// ============================================================

/// Week calendar ka ek din (M–S) + uska dose status.
enum ReportDayStatus {
  /// Dose confirmed (green check).
  taken,

  /// Dose missed / flagged (red priority_high).
  missed,

  /// Dose pending / incomplete (grey horizontal_rule).
  pending,
}

/// Ek calendar day — letter + status.
class ReportDay {
  const ReportDay({required this.letter, required this.status});

  /// Day ka initial (M, T, W…).
  final String letter;

  /// Dose status (taken / missed / pending).
  final ReportDayStatus status;
}

/// Logged vitals ki ek row (label + value + unit).
class ReportVitalRow {
  const ReportVitalRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;
}

/// Share sheet ka ek grid tile (Email / Print / Files / AirDrop).
class ReportShareTile {
  const ReportShareTile({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Share sheet ki ek secondary row (CSV / Documents).
class ReportShareRowAction {
  const ReportShareRowAction({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Config screen ka ek quick range chip (Last 7/30/90 + Custom).
class ReportRangePreset {
  const ReportRangePreset({required this.label, this.days});

  /// Chip ka label ("Last 7 Days").
  final String label;

  /// Kitne days; null = Custom (date picker kholega).
  final int? days;
}

/// Export karne ke data types (requirement: checkboxes).
enum ReportExportOption {
  /// Dose execution % + weekly calendar.
  adherence,

  /// Logged vitals panel.
  vitals,

  /// Reported side effects panel.
  sideEffects,
}

/// Checkbox rows ke labels/descriptions.
extension ReportExportOptionLabels on ReportExportOption {
  String get label => switch (this) {
        ReportExportOption.adherence => 'Adherence',
        ReportExportOption.vitals => 'Vitals',
        ReportExportOption.sideEffects => 'Side Effects',
      };

  String get description => switch (this) {
        ReportExportOption.adherence =>
          'Dose log, scheduled times & streak history',
        ReportExportOption.vitals =>
          'Blood pressure, glucose, weight, & heart rate',
        ReportExportOption.sideEffects => 'Symptoms, severity index & notes',
      };

  /// Row ka icon (Build Report design ke filled icons).
  IconData get icon => switch (this) {
        ReportExportOption.adherence => Icons.verified,
        ReportExportOption.vitals => Icons.monitor_heart,
        ReportExportOption.sideEffects => Icons.healing,
      };
}

/// Side effect ki severity.
enum ReportSeverity { low, medium, high }

extension ReportSeverityLabel on ReportSeverity {
  String get label => switch (this) {
        ReportSeverity.low => 'Low',
        ReportSeverity.medium => 'Medium',
        ReportSeverity.high => 'High',
      };
}

/// Report mein dikhne wali ek side-effect row.
class ReportSideEffectRow {
  const ReportSideEffectRow({
    required this.medication,
    required this.effect,
    required this.severity,
  });

  final String medication;
  final String effect;
  final ReportSeverity severity;
}

/// Screen ke saare static labels + dummy report content.
class ReportPreviewData {
  const ReportPreviewData._();

  // ---- Export configuration (requirement) -------------------------
  static const String defaultProfile = 'Sarah Jenkins';

  static const List<String> exportProfiles = [
    'Sarah Jenkins',
    'Mom',
    'Jake',
  ];

  static final DateTime exportRangeStart = DateTime(2026, 9, 11);
  static final DateTime exportRangeEnd = DateTime(2026, 9, 17);

  /// Build Report ke quick range chips.
  static const List<ReportRangePreset> rangePresets = [
    ReportRangePreset(label: 'Last 7 Days', days: 7),
    ReportRangePreset(label: 'Last 30 Days', days: 30),
    ReportRangePreset(label: 'Last 90 Days', days: 90),
    ReportRangePreset(label: 'Custom'),
  ];

  // ---- Build Report (config screen) -------------------------------
  static const String profileHelp =
      'Whose data to include in the exported clinical summary';

  static const String fromLabel = 'From';
  static const String toLabel = 'To';
  static const String daysTotalSuffix = 'Days Total';
  static const String selectedSuffix = 'Selected';

  static const String pdfCardTitle = 'Doctor-Ready PDF Export';
  static const String pdfCardSubtitle =
      'Includes barcode validation & chart legends';
  static const String pdfReadyLabel = 'Ready';

  static const String compilingLabel = 'Compiling Summary...';
  static const String generatedLabel = 'Report Generated!';
  static const String lockNote = 'Protected PDF with AES-256 encryption';

  /// Profile card ki caption — default profile primary hai.
  static String profileCaptionFor(String name) {
    return name == defaultProfile
        ? 'Primary Profile • Caregiver Sync'
        : 'Linked Profile • Caregiver Sync';
  }

  // ---- Pagination -------------------------------------------------
  static const int totalPages = 3;

  // ---- Report document -------------------------------------------
  static const String clinicalLabel = 'CLINICAL SUMMARY';
  static const String reportTitle = 'Medication Adherence Report';

  // ---- Compliance metric -----------------------------------------
  static const String adherenceLabel = '86% Adherence';
  static const double adherencePercent = 86;
  static const String dosesConfirmed = '12 of 14 scheduled doses confirmed';
  static const String targetChipLabel = 'Target met';

  // ---- Week calendar ---------------------------------------------
  static const String dailySectionLabel = 'DAILY DOSE EXECUTION';
  static const String weekLabel = 'Week 37';

  static const List<ReportDay> weekDays = [
    ReportDay(letter: 'M', status: ReportDayStatus.taken),
    ReportDay(letter: 'T', status: ReportDayStatus.taken),
    ReportDay(letter: 'W', status: ReportDayStatus.taken),
    ReportDay(letter: 'T', status: ReportDayStatus.taken),
    ReportDay(letter: 'F', status: ReportDayStatus.taken),
    ReportDay(letter: 'S', status: ReportDayStatus.missed),
    ReportDay(letter: 'S', status: ReportDayStatus.pending),
  ];

  // ---- Logged vitals ---------------------------------------------
  static const String vitalsLabel = 'LOGGED HEALTH VITALS';

  static const String syncNote =
      'Synchronized during morning intake protocols (08:00 AM window)';

  static const List<ReportVitalRow> vitals = [
    ReportVitalRow(label: 'Blood Pressure', value: '128/82', unit: 'mmHg'),
    ReportVitalRow(label: 'Resting Heart Rate', value: '74', unit: 'bpm'),
    ReportVitalRow(label: 'Body Weight', value: '72.4', unit: 'kg'),
  ];

  // ---- Reported side effects -------------------------------------
  static const String sideEffectsLabel = 'REPORTED SIDE EFFECTS';

  static const List<ReportSideEffectRow> sideEffects = [
    ReportSideEffectRow(
      medication: 'Amlodipine 5mg',
      effect: 'Mild ankle swelling',
      severity: ReportSeverity.low,
    ),
    ReportSideEffectRow(
      medication: 'Metformin 500mg',
      effect: 'Stomach upset after intake',
      severity: ReportSeverity.medium,
    ),
    ReportSideEffectRow(
      medication: 'Sertraline 50mg',
      effect: 'Light dizziness in morning',
      severity: ReportSeverity.low,
    ),
  ];

  // ---- PDF footer stamp ------------------------------------------
  static const String verifiedLabel = 'MedRemind Verified PDF';
  static const String aesLabel = 'AES-256';

  // ---- Actions ----------------------------------------------------
  static const String regenerateLabel = 'Regenerate with different options';

  static const String shareButtonLabel = 'Share Report';
  static const String shareCaption =
      'Export as a password-protected PDF or send directly to verified physician contacts.';

  // ---- Share sheet ------------------------------------------------
  static const String shareSheetTitle = 'Share Report';
  static const String shareNowLabel = 'Share Now';
  static const String cancelLabel = 'Cancel';

  /// "Adherence Report · Sarah · 3 pages · PDF"
  static String shareSheetSubtitle(String firstName) {
    return 'Adherence Report · $firstName · $totalPages pages · PDF';
  }

  static const List<ReportShareTile> shareTiles = [
    ReportShareTile(label: 'Email', icon: Icons.mail_outline_rounded),
    ReportShareTile(label: 'Print', icon: Icons.print_outlined),
    ReportShareTile(label: 'Save to Files', icon: Icons.folder_outlined),
    ReportShareTile(label: 'AirDrop', icon: Icons.cell_tower),
  ];

  static const List<ReportShareRowAction> shareRowActions = [
    ReportShareRowAction(
      label: 'Save as CSV',
      icon: Icons.bar_chart_rounded,
    ),
    ReportShareRowAction(
      label: 'Save to Documents',
      icon: Icons.copy_rounded,
    ),
  ];
}
