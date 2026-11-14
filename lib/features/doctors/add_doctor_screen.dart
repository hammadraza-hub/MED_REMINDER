import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_exception.dart';
import '../../core/constants/app_colors.dart';
import '../../core/doctors/doctor_link_diff.dart';
import '../../core/doctors/prescriber_models.dart';
import '../../core/doctors/prescriber_validator.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../models/medication.dart';
import '../../repositories/firebase_prescriber_repository.dart';
import '../../repositories/medication_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/pro_gate_widgets.dart';

/// What happened on the Add / Edit Doctor screen (returned to the list).
enum DoctorFormResult { added, updated, deleted }

/// ============================================================
/// ADD / EDIT DOCTOR — M16 step 4
///
/// Saves to Firestore (profiles/{pid}/prescribers) and links / unlinks the
/// profile's ACTIVE medications (medication.prescriberId). Pass [existing] to
/// edit; the screen then also offers Delete.
/// ============================================================
class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key, this.existing});

  final Prescriber? existing;

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  bool get _isEdit => widget.existing != null;

  String? get _memberId {
    final id = ProfileController.instance.memberId;
    return (id == null || id.isEmpty) ? null : id;
  }

  // ============================================================
  // MEDICATIONS (real, active ones of this profile)
  // ============================================================

  List<Medication> _meds = const [];
  bool _medsLoading = true;
  bool _medsFailed = false;

  /// Medication ids ticked now / linked when the screen opened.
  final Set<String> _selected = {};
  Set<String> _original = {};

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _nameController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _clinicController;
  late final TextEditingController _addressController;

  bool _isSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _specialtyController = TextEditingController(text: e?.specialty ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _clinicController = TextEditingController(text: e?.clinic ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');

    _loadMeds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _clinicController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  Future<void> _loadMeds() async {
    final memberId = _memberId;
    if (memberId == null) {
      setState(() => _medsLoading = false);
      return;
    }
    setState(() {
      _medsLoading = true;
      _medsFailed = false;
    });
    try {
      final meds = await MedicationRepository.instance
          .watchActiveMedications(memberId)
          .first;
      if (!mounted) return;
      final doctorId = widget.existing?.id;
      final linked = doctorId == null
          ? <String>{}
          : meds
                .where((m) => m.prescriberId == doctorId)
                .map((m) => m.id)
                .toSet();
      setState(() {
        _meds = meds;
        _original = linked;
        _selected
          ..clear()
          ..addAll(linked);
        _medsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _medsLoading = false;
        _medsFailed = true;
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _medLabel(Medication m) {
    final strength = m.strength?.trim() ?? '';
    return strength.isEmpty ? m.name : '${m.name} $strength';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// First problem in the form as a message, or null when it is fine.
  String? _formError(AppLocalizations l10n) {
    final errors = PrescriberValidator.validate(
      name: _nameController.text,
      specialty: _specialtyController.text,
      phone: _phoneController.text,
      clinic: _clinicController.text,
      address: _addressController.text,
    );
    if (errors.contains(PrescriberError.nameMissing)) {
      return l10n.doctorsNameRequired;
    }
    if (errors.contains(PrescriberError.nameTooLong)) {
      return l10n.doctorsErrNameTooLong;
    }
    if (errors.contains(PrescriberError.phoneInvalid)) {
      return l10n.doctorsErrPhone;
    }
    if (errors.isNotEmpty) return l10n.doctorsErrTooLong;
    return null;
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // SAVE / DELETE
  // ============================================================

  Future<void> _saveDoctor() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context);

    final memberId = _memberId;
    if (memberId == null) {
      _showMessage(l10n.vitalsErrNoProfile);
      return;
    }

    final problem = _formError(l10n);
    if (problem != null) {
      _showMessage(problem);
      return;
    }

    final doctor = Prescriber(
      id: widget.existing?.id ?? '',
      name: _nameController.text,
      specialty: _specialtyController.text,
      phone: _phoneController.text,
      clinic: _clinicController.text,
      address: _addressController.text,
    );

    if (!await ensureProForWrite(context, memberId)) return;
    if (!mounted) return;

    setState(() => _isSaving = true);

    final repo = FirebasePrescriberRepository.instance;
    String doctorId;
    try {
      if (_isEdit) {
        await repo.update(memberId, doctor);
        doctorId = doctor.id;
      } else {
        doctorId = (await repo.add(memberId, doctor)).id;
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (isProDenied(e)) {
        await showProRequiredDialog(context);
      } else {
        _showMessage(l10n.doctorsSaveFailed);
      }
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(l10n.doctorsSaveFailed);
      return;
    }

    // Medication links (only when the medication list loaded properly).
    var linksFailed = false;
    if (!_medsFailed && !_medsLoading) {
      final diff = DoctorLinkDiff.compute(
        original: _original,
        selected: _selected,
      );
      if (!diff.isEmpty) {
        try {
          await repo.setMedicationLinks(
            memberId,
            doctorId,
            toLink: diff.toLink,
            toUnlink: diff.toUnlink,
          );
        } catch (_) {
          linksFailed = true;
        }
      }
    }

    if (!mounted) return;
    if (linksFailed) _showMessage(l10n.doctorsLinkFailed);
    Navigator.of(context)
        .pop(_isEdit ? DoctorFormResult.updated : DoctorFormResult.added);
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    final memberId = _memberId;
    if (existing == null || memberId == null || _isSaving) return;
    final l10n = AppLocalizations.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.doctorsDeleteTitle),
        content: Text(l10n.doctorsDeleteBody(existing.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.doctorsDeleteAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await FirebasePrescriberRepository.instance.delete(memberId, existing.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(l10n.doctorsDeleteFailed);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(DoctorFormResult.deleted);
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
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: _buildForm(),
                ),
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
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

              const SizedBox(width: 2),

              Expanded(
                child: Text(
                  _isEdit
                      ? AppLocalizations.of(context).doctorsEditTitle
                      : AppLocalizations.of(context).doctorsAdd,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
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
  // FORM
  // ============================================================

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.doctorsDetailsSection,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 14),

        _buildFieldLabel(l10n.doctorsFieldFullName),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _nameController,
          hintText: l10n.doctorsHintFullName,
          textInputAction: TextInputAction.next,
          maxLength: PrescriberLimits.nameMax,
        ),

        const SizedBox(height: 14),

        _buildFieldLabel(l10n.doctorsFieldSpecialty),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _specialtyController,
          hintText: l10n.doctorsHintSpecialty,
          textInputAction: TextInputAction.next,
          maxLength: PrescriberLimits.specialtyMax,
        ),

        const SizedBox(height: 14),

        _buildFieldLabel(l10n.doctorsFieldPhone),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _phoneController,
          hintText: l10n.doctorsHintPhone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          suffixIcon: const Icon(
            Icons.phone_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
            LengthLimitingTextInputFormatter(30),
          ],
        ),

        const SizedBox(height: 14),

        _buildFieldLabel(l10n.doctorsFieldClinicOnly),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _clinicController,
          hintText: l10n.doctorsHintClinicOnly,
          textInputAction: TextInputAction.next,
          maxLength: PrescriberLimits.clinicMax,
        ),

        const SizedBox(height: 14),

        _buildFieldLabel(l10n.doctorsFieldAddress),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _addressController,
          hintText: l10n.doctorsHintAddress,
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.done,
          maxLines: 2,
          minHeight: 72,
          maxLength: PrescriberLimits.addressMax,
        ),

        const SizedBox(height: 26),

        // ======================================================
        // LINK MEDICATIONS
        // ======================================================
        Text(
          l10n.doctorsLinkMedications,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          l10n.doctorsLinkPrompt,
          style: const TextStyle(
            color: AppColors.textTeal,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          l10n.doctorsReplacesOtherDoctor,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
          ),
        ),

        const SizedBox(height: 8),

        _buildMedicationsCard(),

        const SizedBox(height: 20),

        // ======================================================
        // SAVE
        // ======================================================
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveDoctor,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.primaryDark.withValues(
                alpha: 0.65,
              ),
              elevation: 4,
              shadowColor: AppColors.primaryDark.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : Text(
                    l10n.doctorsSave,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // ======================================================
        // CANCEL
        // ======================================================
        Center(
          child: TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: AppColors.textTeal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

        if (_isEdit)
          Center(
            child: TextButton.icon(
              onPressed: _isSaving ? null : _confirmDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
              label: Text(
                l10n.doctorsDeleteAction,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    int maxLines = 1,
    double minHeight = 50,
    int? maxLength,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: [
          ...?inputFormatters,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        maxLines: maxLines,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.fieldHint,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.textTeal, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.textTeal),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICATIONS CARD
  // ============================================================

  Widget _buildMedicationsCard() {
    final l10n = AppLocalizations.of(context);

    Widget message(String text, {bool retry = false}) => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          if (retry)
            TextButton(onPressed: _loadMeds, child: Text(l10n.doctorsRetry)),
        ],
      ),
    );

    Widget body;
    if (_medsLoading) {
      body = const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_medsFailed) {
      body = message(l10n.doctorsMedsLoadFailed, retry: true);
    } else if (_meds.isEmpty) {
      body = message(l10n.doctorsNoMeds);
    } else {
      body = Column(
        children: [
          for (int i = 0; i < _meds.length; i++) ...[
            _buildMedicationRow(_meds[i]),
            if (i != _meds.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.inputFill,
              ),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: body,
    );
  }

  // ============================================================
  // MEDICATION ROW
  // ============================================================

  Widget _buildMedicationRow(Medication med) {
    final selected = _selected.contains(med.id);
    final liquid = (med.form ?? '').toLowerCase().contains('liquid');
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputFill),
            ),
            child: Icon(
              liquid
                  ? Icons.medication_liquid_outlined
                  : Icons.medication_outlined,
              color: AppColors.textTeal,
              size: 18,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _medLabel(med),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if ((med.form ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    liquid ? l10n.doseFormLiquid : med.form!,
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: selected,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        if (value) {
                          _selected.add(med.id);
                        } else {
                          _selected.remove(med.id);
                        }
                      });
                    },
              activeColor: AppColors.surface,
              activeTrackColor: AppColors.primaryDark,
              inactiveThumbColor: AppColors.surface,
              inactiveTrackColor: AppColors.divider,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
