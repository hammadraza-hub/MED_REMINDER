import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_exception.dart';
import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../core/vitals/vital_input.dart';
import '../../core/vitals/vital_models.dart';
import '../../core/vitals/vital_types.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/firebase_vitals_repository.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'add_vitals_entry_data.dart';
import 'home_data.dart';

/// ============================================================
/// LOG VITALS / ADD VITALS ENTRY
///
/// PURPOSE:
/// Selected user/family member ke liye new health metric log karna.
///
/// TYPES:
/// - Blood Pressure
/// - Glucose
/// - Weight
/// - Heart Rate
///
/// NAVIGATION:
/// Vitals List → + → Log Vitals
/// Save → result return → Vitals List
///
/// M15 step 4:
/// Save writes a real reading to profiles/{memberId}/vitals through
/// [FirebaseVitalsRepository] (rules validate it again). Nothing is
/// pre-filled: the user must type the value, so a dummy number can never be
/// saved by accident. "Last" shows the real latest reading, if any.
///
/// TODO (step 5): Vitals List / Chart still show dummy data.
/// ============================================================
class AddVitalsEntryScreen extends StatefulWidget {
  const AddVitalsEntryScreen({
    super.key,
    required this.userName,
    this.initialType = AddVitalType.bloodPressure,
  });

  final String userName;
  final AddVitalType initialType;

  @override
  State<AddVitalsEntryScreen> createState() => _AddVitalsEntryScreenState();
}

class _AddVitalsEntryScreenState extends State<AddVitalsEntryScreen> {
  late AddVitalType _selectedType;

  late final TextEditingController _primaryController;
  late final TextEditingController _secondaryController;
  late final TextEditingController _pulseController;

  late DateTime _measurementTime;

  bool _isSaving = false;

  /// Latest saved reading of the selected type (null = none / not loaded).
  VitalReading? _previous;

  @override
  void initState() {
    super.initState();

    _selectedType = widget.initialType;
    _measurementTime = DateTime.now();

    _primaryController = TextEditingController();
    _secondaryController = TextEditingController();
    _pulseController = TextEditingController();

    _applyDefaults();
    _loadPrevious();
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _pulseController.dispose();

    super.dispose();
  }

  // ================= DEFAULTS =================

  void _applyDefaults() {
    // Nothing is pre-filled: a health reading must be typed by the user.
    _primaryController.clear();
    _secondaryController.clear();
    _pulseController.clear();
  }

  VitalKind get _selectedKind => _kindFor(_selectedType);

  static VitalKind _kindFor(AddVitalType type) {
    switch (type) {
      case AddVitalType.bloodPressure:
        return VitalKind.bloodPressure;
      case AddVitalType.glucose:
        return VitalKind.glucose;
      case AddVitalType.weight:
        return VitalKind.weight;
      case AddVitalType.heartRate:
        return VitalKind.heartRate;
    }
  }

  /// Loads the real latest reading for "Last: ..." (silent on failure).
  Future<void> _loadPrevious() async {
    final memberId = ProfileController.instance.memberId;
    final kind = _selectedKind;
    if (memberId == null || memberId.isEmpty) return;

    VitalReading? latest;
    try {
      latest = await FirebaseVitalsRepository.instance.latest(memberId, kind);
    } catch (e) {
      debugPrint('Add vitals: could not load last reading — $e');
    }
    // The user may have switched type while this was loading.
    if (!mounted || kind != _selectedKind) return;
    setState(() => _previous = latest);
  }

  String? _previousText(AppLocalizations l10n) {
    final prev = _previous;
    if (prev == null) return null;

    final value = prev.kind == VitalKind.bloodPressure && prev.value2 != null
        ? '${VitalInput.formatNumber(prev.value)}/'
              '${VitalInput.formatNumber(prev.value2!)}'
        : VitalInput.formatNumber(prev.value);
    return l10n.vitalsLast(
      value,
      prev.unit,
      _formatPreviousTime(prev.measuredAt),
    );
  }

  void _changeVitalType(AddVitalType type) {
    if (_selectedType == type) return;

    setState(() {
      _selectedType = type;
      _previous = null;
      _applyDefaults();
    });
    _loadPrevious();
  }

  // ================= NAVIGATION =================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ================= SAVE =================

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context);

    final parsed = VitalInput.parse(
      kind: _selectedKind,
      primaryText: _primaryController.text,
      secondaryText: _secondaryController.text,
      pulseText: _pulseController.text,
      measuredAt: _measurementTime,
    );
    final reading = parsed.reading;
    if (reading == null) {
      _showMessage(_issueMessage(l10n, parsed.issue!));
      return;
    }

    final memberId = ProfileController.instance.memberId;
    if (memberId == null || memberId.isEmpty) {
      _showMessage(l10n.vitalsErrNoProfile);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final saved = await FirebaseVitalsRepository.instance.addManual(
        memberId,
        reading,
      );
      if (!mounted) return;

      Navigator.of(context).pop(
        AddVitalsEntryResult(
          type: _selectedType,
          recordedAt: saved.measuredAt,
          primaryValue: saved.value,
          secondaryValue: saved.value2,
          pulse: saved.pulse?.round(),
        ),
      );
    } on AppException catch (e) {
      debugPrint('Add vitals: save failed (${e.type}) — ${e.message}');
      if (mounted) {
        _showMessage(
          e.type == AppExceptionType.permission
              ? l10n.vitalsSavePermission
              : l10n.vitalsSaveFailed,
        );
      }
    } catch (e) {
      debugPrint('Add vitals: save failed — $e');
      if (mounted) _showMessage(l10n.vitalsSaveFailed);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _issueMessage(AppLocalizations l10n, VitalInputIssue issue) {
    String n(double? v) => v == null ? '' : VitalInput.formatNumber(v);

    switch (issue.problem) {
      case VitalInputProblem.empty:
        return l10n.vitalsErrEmpty;
      case VitalInputProblem.notANumber:
        return l10n.vitalsErrNotNumber;
      case VitalInputProblem.range:
        return l10n.vitalsErrRange(
          n(issue.min),
          n(issue.max),
          AddVitalsEntryData.unitFor(_selectedType),
        );
      case VitalInputProblem.diastolicMissing:
        return l10n.vitalsErrDiastolicMissing;
      case VitalInputProblem.diastolicRange:
        return l10n.vitalsErrDiastolicRange(n(issue.min), n(issue.max));
      case VitalInputProblem.diastolicNotLower:
        return l10n.vitalsErrDiastolicNotLower;
      case VitalInputProblem.pulseRange:
        return l10n.vitalsErrPulseRange(n(issue.min), n(issue.max));
      case VitalInputProblem.timeInFuture:
        return l10n.vitalsErrFuture;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= BUILD =================

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
      body: Column(
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

      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.surface,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 2),

                const Expanded(
                  child: Text(
                    'Log Vitals',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                AppAvatar(
                  size: 36,
                  imagePath: HomeData.userProfileImage(),
                  ringColor: AppColors.surface,
                  ringWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= CONTENT =================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVitalTypeSection(),

          const SizedBox(height: 18),

          _buildValueSection(),

          const SizedBox(height: 12),

          if (_selectedType == AddVitalType.bloodPressure) ...[
            _buildPulseCard(),
            const SizedBox(height: 16),
          ],

          _buildTimestampSection(),

          const SizedBox(height: 16),

          _buildInformationCard(),

          const SizedBox(height: 24),

          _buildSaveButton(),

          const SizedBox(height: 8),

          _buildCancelButton(),
        ],
      ),
    );
  }

  // ================= VITAL TYPE =================

  Widget _buildVitalTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'VITAL TYPE',
                style: TextStyle(
                  color: AppColors.headerDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),

            const Icon(
              Icons.bluetooth_rounded,
              color: AppColors.formAccent,
              size: 15,
            ),

            const SizedBox(width: 4),

            const Text(
              'Bluetooth Monitor Ready',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _vitalTypeChip(
              type: AddVitalType.bloodPressure,
              icon: Icons.monitor_heart_rounded,
            ),
            _vitalTypeChip(
              type: AddVitalType.glucose,
              icon: Icons.water_drop_outlined,
            ),
            _vitalTypeChip(
              type: AddVitalType.weight,
              icon: Icons.monitor_weight_outlined,
            ),
            _vitalTypeChip(
              type: AddVitalType.heartRate,
              icon: Icons.favorite_border_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _vitalTypeChip({required AddVitalType type, required IconData icon}) {
    final selected = _selectedType == type;

    return GestureDetector(
      onTap: () => _changeVitalType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.formAccent : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.surface : AppColors.formAccent,
            ),
            const SizedBox(width: 5),
            Text(
              AddVitalsEntryData.titleFor(type),
              style: TextStyle(
                color: selected ? AppColors.surface : AppColors.formAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= VALUES =================

  Widget _buildValueSection() {
    final lastText = _previousText(AppLocalizations.of(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedType == AddVitalType.bloodPressure
                    ? 'BLOOD PRESSURE VALUES'
                    : '${AddVitalsEntryData.titleFor(_selectedType).toUpperCase()} VALUE',
                style: const TextStyle(
                  color: AppColors.headerDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Target: ${AddVitalsEntryData.targetFor(_selectedType)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        _buildValueField(
          label: AddVitalsEntryData.primaryLabel(_selectedType),
          controller: _primaryController,
          unit: AddVitalsEntryData.unitFor(_selectedType),
          decimal: _selectedType == AddVitalType.weight,
        ),

        if (_selectedType == AddVitalType.bloodPressure) ...[
          const SizedBox(height: 8),

          _buildValueField(
            label: 'DIASTOLIC (BOTTOM)',
            controller: _secondaryController,
            unit: 'mmHg',
          ),
        ],

        const SizedBox(height: 8),

        Row(
          children: [
            if (lastText != null) ...[
              const Icon(
                Icons.history_rounded,
                color: AppColors.formAccent,
                size: 15,
              ),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(
                lastText ?? '',
                style: const TextStyle(
                  color: AppColors.formSubtitle,
                  fontSize: 11,
                ),
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildValueField({
    required String label,
    required TextEditingController controller,
    required String unit,
    bool decimal = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(13, 9, 8, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),

                TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: decimal,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
                    ),
                  ],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '--',
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          Container(
            height: 44,
            constraints: const BoxConstraints(minWidth: 76),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.formAccent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              unit,
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final primary = double.tryParse(_primaryController.text.trim());

    final secondary = double.tryParse(_secondaryController.text.trim());

    if (primary == null) {
      return const SizedBox.shrink();
    }

    final status = AddVitalsEntryData.valueStatus(
      _selectedType,
      primary,
      secondary: secondary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'Review'
            ? AppColors.hintBackground
            : AppColors.successBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: status == 'Review' ? AppColors.hintAccent : AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ================= PULSE =================

  Widget _buildPulseCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.035),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.error,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONCURRENT PULSE',
                  style: TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: TextField(
                        controller: _pulseController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '--',
                        ),
                      ),
                    ),
                    const Text(
                      'BPM',
                      style: TextStyle(
                        color: AppColors.formSubtitle,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              AppLocalizations.of(context).vitalsOptional,
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TIMESTAMP =================

  Widget _buildTimestampSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIMESTAMP',
          style: TextStyle(
            color: AppColors.headerDark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),

        const SizedBox(height: 9),

        GestureDetector(
          onTap: _changeMeasurementTime,
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.formAccent,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MEASUREMENT TIME',
                        style: TextStyle(
                          color: AppColors.formAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatMeasurementTime(_measurementTime),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit_outlined,
                  color: AppColors.formAccent,
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Defaults to your local device time',
          style: TextStyle(color: AppColors.formSubtitle, fontSize: 11),
        ),
      ],
    );
  }

  // ================= INFO =================

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.formAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.surface,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Consistent morning vitals help your care team '
                  'detect subtle trends. Make sure you are rested '
                  'and seated for 5 minutes before logging.',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sync_rounded,
                  color: AppColors.formAccent,
                  size: 15,
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Syncs automatically with care team',
                    style: TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: AppColors.formAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUTTONS =================

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _isSaving ? null : _saveEntry,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.formAccent,
          disabledBackgroundColor: AppColors.formAccent.withValues(alpha: 0.6),
          foregroundColor: AppColors.surface,
          elevation: 3,
          shadowColor: AppColors.formAccent.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 19),
                  SizedBox(width: 6),
                  Text(
                    'Save Entry',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isSaving
          ? null
          : () {
              Navigator.of(context).pop();
            },
      child: const Text(
        'Cancel',
        style: TextStyle(
          color: AppColors.formAccent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================= TIME PICKER =================

  Future<void> _changeMeasurementTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measurementTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measurementTime),
    );

    if (time == null || !mounted) return;

    setState(() {
      _measurementTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // ================= FORMATTERS =================

  String _formatMeasurementTime(DateTime value) {
    final now = DateTime.now();

    final isToday =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;

    final dayText = isToday ? 'Today' : _formatDate(value);

    return '$dayText, ${_formatTime(value)}';
  }

  String _formatPreviousTime(DateTime value) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final day = DateTime(value.year, value.month, value.day);

    final difference = today.difference(day).inDays;

    if (difference == 0) {
      return 'Today, ${_formatTime(value)}';
    }

    if (difference == 1) {
      return 'Yesterday, ${_formatTime(value)}';
    }

    return '${_formatDate(value)}, ${_formatTime(value)}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;

    final minute = value.minute.toString().padLeft(2, '0');

    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[value.month - 1]} '
        '${value.day}, ${value.year}';
  }
}
