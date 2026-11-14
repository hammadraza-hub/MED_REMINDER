import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_exception.dart';
import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../core/vitals/symptom_entry.dart';
import '../../core/vitals/symptom_validator.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';
import '../../repositories/firebase_symptom_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';

/// ============================================================
/// ADD SYMPTOM — caregiver log entry form
///
/// PURPOSE:
/// Naya symptom/side-effect record banana:
/// • Symptom name (search field + suggestion chips)
/// • Severity level (1..5 discrete slider)
/// • Linked medication (modal sheet se selection)
/// • Optional notes (250 char limit)
///
/// NAVIGATION:
/// Side Effects → + → Add Symptom
/// Save → toast → pop(true) → Side Effects list refresh
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
/// Naye colors (symptomMild, toastBackground etc.)
/// AppColors mein add kar ke use hue hain.
///
/// BOTTOM BAR:
/// Shared AppBottomNavigation (baaki detail screens jaisi).
///
/// TODO Backend:
/// Firestore side_effects/{id} create:
/// { memberId, medicationId, medicationName, symptom,
///   severity, note, recordedAt: serverTimestamp() }
/// ============================================================
class AddSymptomScreen extends StatefulWidget {
  const AddSymptomScreen({super.key});

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen>
    with SingleTickerProviderStateMixin {
  // Suggestion chips — design mock ki fixed list.
  static const List<String> _suggestions = [
    'Nausea',
    'Headache',
    'Dizziness',
    'Fatigue',
    'Stomach upset',
  ];

  // Severity 1..5 ke design fill positions (non-linear per mock).
  static const Map<int, double> _severityFill = {
    1: 0.10,
    2: 0.35,
    3: 0.60,
    4: 0.80,
    5: 1.00,
  };

  late final TextEditingController _symptomController;
  late final TextEditingController _notesController;

  // Design initial state: input "Nausea", chip active.
  String _selectedChip = 'Nausea';
  int _severity = 3;
  int _notesLength = 0;

  /// Active medications of the selected profile (real data) and the one the
  /// symptom is linked to. The link is optional, so null is a valid choice.
  List<Medication> _medications = const [];
  Medication? _selectedMedication;

  bool _saving = false;

  bool _toastVisible = false;
  Timer? _toastTimer;

  late final String _todayLabel;

  // "Caregiver Log" dot ka pulse animation (design: animate-pulse).
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _symptomController = TextEditingController(text: _selectedChip);
    _notesController = TextEditingController();

    _loadMedications();
    _todayLabel = _buildTodayLabel();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();

    _symptomController.dispose();
    _notesController.dispose();
    _pulseController.dispose();

    super.dispose();
  }

  // ============================================================
  // SEVERITY HELPERS
  // ============================================================

  String get _severityName {
    switch (_severity) {
      case 1:
        return 'Very Mild';
      case 2:
        return 'Mild';
      case 3:
        return 'Moderate';
      case 4:
        return 'Significant';
      case 5:
        return 'Severe';
      default:
        return 'Moderate';
    }
  }

  IconData get _severityIcon {
    switch (_severity) {
      case 1:
        return Icons.sentiment_satisfied_alt_rounded;
      case 2:
        return Icons.sentiment_neutral_rounded;
      case 3:
        return Icons.speed_rounded;
      case 4:
        return Icons.warning_amber_rounded;
      case 5:
        return Icons.error;
      default:
        return Icons.speed_rounded;
    }
  }

  /// Slider thumb/fill position — design percents (10%..100%).
  double get _severityFillPercent => _severityFill[_severity] ?? 0.60;

  /// Drag/tap position se nearest severity step pick karta hai.
  void _handleSliderTouch(double dx, double width) {
    if (width <= 0) return;

    final ratio = (dx / width).clamp(0.0, 1.0);

    int nearest = 1;
    var bestDistance = double.infinity;

    _severityFill.forEach((level, fill) {
      final distance = (fill - ratio).abs();

      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = level;
      }
    });

    if (nearest != _severity) {
      setState(() => _severity = nearest);
    }
  }

  // ============================================================
  // BOTTOM NAVIGATION — shared shell pattern
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // SAVE + TOAST
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadMedications() async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null || memberId.isEmpty) return;

    try {
      // Same source as the Meds screen (M5 `status == active`).
      final meds = await MedicationRepository.instance
          .watchActiveMedications(memberId)
          .first;
      meds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() => _medications = meds);
    } catch (e) {
      // The link is optional: the screen still works without the list.
      debugPrint('Add symptom: could not load medications — $e');
    }
  }

  Future<void> _saveSymptom() async {
    if (_saving || _toastVisible) return;
    final l10n = AppLocalizations.of(context);

    final symptom = _symptomController.text.trim();
    final note = _notesController.text.trim();
    final occurredAt = DateTime.now();

    final check = SymptomValidator.validate(
      name: symptom,
      severity: _severity,
      notes: note,
      occurredAt: occurredAt,
    );
    if (!check.isValid) {
      switch (check.error!) {
        case SymptomError.nameEmpty:
          _showMessage(l10n.symptomErrNameEmpty);
        case SymptomError.nameTooLong:
          _showMessage(
            l10n.symptomErrNameTooLong(SymptomValidator.maxNameLength),
          );
        case SymptomError.notesTooLong:
          _showMessage(
            l10n.symptomErrNotesTooLong(SymptomValidator.maxNotesLength),
          );
        case SymptomError.severityOutOfRange:
        case SymptomError.timeInFuture:
          _showMessage(l10n.symptomSaveFailed);
      }
      return;
    }

    final memberId = ProfileController.instance.memberId;
    if (memberId == null || memberId.isEmpty) {
      _showMessage(l10n.vitalsErrNoProfile);
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseSymptomRepository.instance.add(
        memberId,
        SymptomEntry(
          symptom: symptom,
          severity: _severity,
          medicationId: _selectedMedication?.id,
          occurredAt: occurredAt,
          notes: note.isEmpty ? null : note,
        ),
      );
      if (!mounted) return;
      _showToast();
    } on AppException catch (e) {
      debugPrint('Add symptom: save failed (${e.type}) — ${e.message}');
      if (mounted) {
        _showMessage(
          e.type == AppExceptionType.permission
              ? l10n.symptomSavePermission
              : l10n.symptomSaveFailed,
        );
      }
    } catch (e) {
      debugPrint('Add symptom: save failed — $e');
      if (mounted) _showMessage(l10n.symptomSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showToast() {
    _toastTimer?.cancel();

    setState(() => _toastVisible = true);

    // Design: toast 2.5s baad hide hota hai.
    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      Navigator.of(context).pop(true);
    });
  }

  // ============================================================
  // DATE/TIME LABEL — design: "Today, 2:45 PM"
  // ============================================================

  String _buildTodayLabel() {
    final now = DateTime.now();

    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    final twelveHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return 'Today, $twelveHour:$minute $period';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),

              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),

          // Save feedback toast — design se fixed bottom.
          _buildToast(),
        ],
      ),

      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ============================================================
  // DARK HEADER — baaki detail screens jaisa
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),

              const SizedBox(width: 4),

              const Expanded(
                child: Text(
                  'Add Symptom',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppAvatar(
                size: 35,
                ringColor: AppColors.surface,
                ringWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildContextRow(),

          const SizedBox(height: 16),

          _buildSymptomSection(),

          const SizedBox(height: 16),

          _buildSeveritySection(),

          const SizedBox(height: 16),

          _buildMedicationSection(),

          const SizedBox(height: 16),

          _buildNotesSection(),

          const SizedBox(height: 16),

          _buildActionButtons(),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEXT ROW — pulsing dot + caregiver log + time
  // ============================================================

  Widget _buildContextRow() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Opacity(
              opacity: Tween<double>(
                begin: 1,
                end: 0.35,
              ).transform(_pulseController.value),
              child: child,
            );
          },
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.textTeal,
              shape: BoxShape.circle,
            ),
          ),
        ),

        const SizedBox(width: 7),

        const Expanded(
          child: Text(
            'CAREGIVER LOG  ',
            style: TextStyle(
              color: AppColors.textTeal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),

        Text(
          _todayLabel,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION LABEL — design: uppercase label-sm
  // ============================================================

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  // ============================================================
  // SECTION 1 — SYMPTOM NAME (input + suggestion chips)
  // ============================================================

  Widget _buildSymptomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Symptom Name'),

        const SizedBox(height: 8),

        _buildSymptomInput(),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in _suggestions)
              _buildSuggestionChip(suggestion),
          ],
        ),
      ],
    );
  }

  Widget _buildSymptomInput() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _symptomController,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. Headache, Nausea, Dizziness',
          hintStyle: const TextStyle(
            color: AppColors.fieldHint,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textTeal,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (value) {
          final trimmed = value.trim();

          if (trimmed != _selectedChip) {
            setState(() => _selectedChip = '');
          }
        },
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    final selected = _selectedChip == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChip = label;
          _symptomController.text = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.surface,
              ),
              const SizedBox(width: 4),
            ],

            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.surface : AppColors.textTeal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 2 — SEVERITY LEVEL (badge + slider card + pill)
  // ============================================================

  Widget _buildSeveritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('Severity Level'),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.cardFill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Level $_severity of 5',
                style: const TextStyle(
                  color: AppColors.textTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        _buildSeverityCard(),
      ],
    );
  }

  Widget _buildSeverityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Extremes markers — Mild left, Severe right.
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _SeverityDot(color: AppColors.symptomMildDot),
                  SizedBox(width: 6),
                  Text(
                    'Mild',
                    style: TextStyle(
                      color: AppColors.symptomMild,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Severe',
                    style: TextStyle(
                      color: AppColors.symptomSevere,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  _SeverityDot(color: AppColors.symptomSevere),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          _buildSeveritySlider(),

          const SizedBox(height: 10),

          _buildSeverityStatusPill(),
        ],
      ),
    );
  }

  // ============================================================
  // DISCRETE SLIDER — 5 steps, tap/drag se value change
  // ============================================================

  Widget _buildSeveritySlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbCenter = width * _severityFillPercent;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _handleSliderTouch(details.localPosition.dx, width);
          },
          onHorizontalDragUpdate: (details) {
            _handleSliderTouch(details.localPosition.dx, width);
          },
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Track
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.cardFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Fill
                Positioned(
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: thumbCenter,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.formAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Discrete step dots
                Positioned(
                  left: 4,
                  right: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _StepDot(),
                      _StepDot(),
                      _StepDot(),
                      _StepDot(),
                      _StepDot(),
                    ],
                  ),
                ),

                // Thumb
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  left: thumbCenter - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.headerDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STATUS PILL — "Moderate" label tag
  // ============================================================

  Widget _buildSeverityStatusPill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_severityIcon, size: 18, color: AppColors.textTeal),

            const SizedBox(width: 8),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                _severityName,
                key: ValueKey(_severityName),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 3 — LINKED MEDICATION (card + helper note)
  // ============================================================

  Widget _buildMedicationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Linked Medication'),

        const SizedBox(height: 8),

        _buildMedicationCard(),

        const SizedBox(height: 8),

        Row(
          children: const [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppColors.textTeal,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Select which medication this symptom is linked to',
                style: TextStyle(color: AppColors.textTeal, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationCard() {
    final l10n = AppLocalizations.of(context);
    final med = _selectedMedication;

    return GestureDetector(
      onTap: _openMedicationPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail pill image
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.cardFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 20,
                color: AppColors.textTeal,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          med == null
                              ? l10n.symptomNoMedication
                              : '${med.name} ${med.strength ?? ''}'.trim(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.textTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Text(
                    med == null
                        ? l10n.symptomSelectMedication
                        : (med.form ?? ''),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.cardFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEDICATION PICKER — modal sheet (MedsData se)
  // ============================================================

  void _openMedicationPicker() {
    final l10n = AppLocalizations.of(context);
    final medicines = _medications;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: Text(
                    l10n.symptomSelectMedication,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // "No medication": the symptom is not linked to anything.
                ListTile(
                  leading: const Icon(
                    Icons.link_off_rounded,
                    color: AppColors.textTeal,
                  ),
                  title: Text(
                    l10n.symptomNoMedication,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: _selectedMedication == null
                      ? const Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: AppColors.formAccent,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedMedication = null);
                    Navigator.of(sheetContext).pop();
                  },
                ),

                if (medicines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(
                      l10n.symptomNoMedicationsFound,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),

                for (final medicine in medicines)
                  ListTile(
                    leading: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.textTeal,
                    ),
                    title: Text(
                      '${medicine.name} ${medicine.strength ?? ''}'.trim(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: (medicine.form ?? '').isEmpty
                        ? null
                        : Text(
                            medicine.form!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                    trailing: medicine.id == _selectedMedication?.id
                        ? const Icon(
                            Icons.check_circle_rounded,
                            size: 22,
                            color: AppColors.formAccent,
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedMedication = medicine);
                      Navigator.of(sheetContext).pop();
                    },
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION 4 — NOTES (textarea + char counter)
  // ============================================================

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Notes (Optional)'),

        const SizedBox(height: 8),

        Container(
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: null,
            minLines: 4,
            maxLength: 250,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText:
                  'Any additional details about this symptom '
                  '(e.g. onset, with food)...',
              hintStyle: TextStyle(color: AppColors.fieldHint, fontSize: 14),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              counterText: '',
              isDense: true,
            ),
            onChanged: (value) {
              setState(() => _notesLength = value.length);
            },
          ),
        ),

        const SizedBox(height: 6),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_notesLength/250',
            style: const TextStyle(
              color: AppColors.textTeal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 5/6 — SAVE BUTTON + CANCEL
  // ============================================================

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _saveSymptom,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.formAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.surface,
                ),
                SizedBox(width: 8),
                Text(
                  'Save Symptom',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).maybePop();
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOAST — save feedback (design: fixed bottom, 2.5s)
  // ============================================================

  Widget _buildToast() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: AnimatedSlide(
        offset: _toastVisible ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _toastVisible ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_toastVisible,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.toastBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    size: 20,
                    color: AppColors.toastIcon,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      _selectedMedication == null
                          ? AppLocalizations.of(context).symptomRecorded
                          : AppLocalizations.of(context)
                                .symptomRecordedFor(_selectedMedication!.name),
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Text(
                    'Synced',
                    style: TextStyle(
                      color: AppColors.toastSynced,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SMALL HELPERS
// ============================================================

/// Mild/Severe extreme marker dot.
class _SeverityDot extends StatelessWidget {
  const _SeverityDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Slider track ka chhota inactive step dot.
class _StepDot extends StatelessWidget {
  const _StepDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
    );
  }
}
