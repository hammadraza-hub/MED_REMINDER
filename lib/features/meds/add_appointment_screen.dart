import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/doctors/appointment_models.dart';
import '../../core/doctors/appointment_reminder_service.dart';
import '../../core/doctors/appointment_validator.dart';
import '../../core/doctors/prescriber_models.dart';
import '../../core/profile/profile_controller.dart';
import '../../core/services/appointment_reminders.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../repositories/firebase_appointment_repository.dart';
import '../../repositories/firebase_prescriber_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/pro_gate_widgets.dart';

/// What happened on the Add / Edit Appointment screen (returned to the list).
enum AppointmentFormResult { added, updated, deleted }

/// ============================================================
/// ADD / EDIT APPOINTMENT — M16 step 5
///
/// Saves to Firestore (profiles/{pid}/appointments) and sets the reminders on
/// this phone (flutter_local_notifications; Spark has no Cloud Tasks).
/// Pass [existing] to edit: the reminders are replaced and Delete is offered.
///
/// Appointments are for the selected profile (ProfileController.memberId);
/// the doctor is optional.
/// ============================================================
class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key, this.existing});

  final Appointment? existing;

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  bool get _isEdit => widget.existing != null;

  String? get _memberId {
    final id = ProfileController.instance.memberId;
    return (id == null || id.isEmpty) ? null : id;
  }

  // ============================================================
  // STATE
  // ============================================================

  late DateTime _selectedDateTime;
  late AppointmentType _selectedType;
  late final Set<int> _offsets;
  late final List<int> _offsetChoices;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Prescriber> _doctors = const [];
  bool _doctorsFailed = false;
  String? _selectedDoctorId;

  bool _isSaving = false;

  static DateTime _defaultDateTime() {
    final target = DateTime.now().add(const Duration(days: 7));
    return DateTime(target.year, target.month, target.day, 10, 30);
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final e = widget.existing;
    _selectedDateTime = e?.startsAt ?? _defaultDateTime();
    _selectedType = e?.type ?? AppointmentType.followUp;
    _offsets = {...(e?.reminderOffsets ?? AppointmentLimits.defaultOffsets)};
    _offsetChoices = ReminderOffsetOptions.withExtras(_offsets);
    _selectedDoctorId = e?.prescriberId;
    _locationController.text = e?.location ?? '';
    _notesController.text = e?.notes ?? '';

    _loadDoctors();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    final memberId = _memberId;
    if (memberId == null) return;
    try {
      final list = await FirebasePrescriberRepository.instance.list(memberId);
      if (!mounted) return;
      setState(() {
        _doctors = list;
        _doctorsFailed = false;
        // A doctor that no longer exists is not selected any more.
        if (_selectedDoctorId != null &&
            !list.any((d) => d.id == _selectedDoctorId)) {
          _selectedDoctorId = null;
        }
        // New appointment: start with the first doctor, like before.
        if (!_isEdit && _selectedDoctorId == null && list.isNotEmpty) {
          _selectedDoctorId = list.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _doctorsFailed = true);
    }
  }

  Prescriber? get _selectedDoctor {
    for (final d in _doctors) {
      if (d.id == _selectedDoctorId) return d;
    }
    return null;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDateTime(DateTime date) =>
      DateFormat.yMMMEd(AppLocalizations.of(context).localeName)
          .add_jm()
          .format(date);

  String _offsetLabel(AppLocalizations l10n, int minutes) => switch (minutes) {
    10080 => l10n.apptOffsetWeek,
    1440 => l10n.apptOffsetDay,
    120 => l10n.apptOffsetHours2,
    60 => l10n.apptOffsetHour,
    30 => l10n.apptOffsetMinutes30,
    _ => l10n.apptOffsetCustom(minutes),
  };

  String? _formError(AppLocalizations l10n) {
    final errors = AppointmentValidator.validate(
      startsAt: _selectedDateTime,
      location: _locationController.text,
      notes: _notesController.text,
      reminderOffsets: _offsets.toList(),
      requireFuture: !_isEdit,
    );
    if (errors.contains(AppointmentError.startsAtInPast)) {
      return l10n.apptErrFuture;
    }
    if (errors.contains(AppointmentError.locationTooLong) ||
        errors.contains(AppointmentError.notesTooLong)) {
      return l10n.apptErrTooLong;
    }
    if (errors.isNotEmpty) return l10n.apptErrReminders;
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
  // DATE / TIME PICKER
  // ============================================================

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Editing an old appointment may keep its past date.
    final first = _selectedDateTime.isBefore(today)
        ? DateTime(
            _selectedDateTime.year,
            _selectedDateTime.month,
            _selectedDateTime.day,
          )
        : today;

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isBefore(first)
          ? first
          : _selectedDateTime,
      firstDate: first,
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // ============================================================
  // DOCTOR PICKER
  // ============================================================

  void _showPrescriberPicker() {
    final l10n = AppLocalizations.of(context);

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.apptPickDoctorTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildNoDoctorOption(sheetContext, l10n),

                  if (_doctors.isEmpty || _doctorsFailed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.textTeal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _doctorsFailed
                                  ? l10n.doctorsLoadFailed
                                  : l10n.apptNoDoctorsOnFile,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final doctor in _doctors) ...[
                      const Divider(color: AppColors.divider),
                      _buildDoctorOption(sheetContext, doctor),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoDoctorOption(
    BuildContext sheetContext,
    AppLocalizations l10n,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.upcomingBackground,
        child: Icon(
          Icons.person_off_outlined,
          size: 18,
          color: AppColors.textTeal,
        ),
      ),
      title: Text(
        l10n.apptNoDoctor,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: _selectedDoctorId == null
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _selectedDoctorId = null);
        Navigator.of(sheetContext).pop();
      },
    );
  }

  Widget _buildDoctorOption(BuildContext sheetContext, Prescriber doctor) {
    final selected = _selectedDoctorId == doctor.id;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.upcomingBackground,
        child: Text(
          doctor.initials,
          style: const TextStyle(
            color: AppColors.textTeal,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        doctor.name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: (doctor.specialty ?? '').isEmpty
          ? null
          : Text(
              doctor.specialty!,
              style: const TextStyle(color: AppColors.textTeal, fontSize: 10),
            ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textTeal),
      onTap: () {
        setState(() => _selectedDoctorId = doctor.id);
        Navigator.of(sheetContext).pop();
      },
    );
  }

  // ============================================================
  // SAVE / DELETE
  // ============================================================

  Future<void> _saveAppointment() async {
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

    final draft = Appointment(
      id: widget.existing?.id ?? '',
      startsAt: _selectedDateTime,
      prescriberId: _selectedDoctorId,
      type: _selectedType,
      location: _locationController.text,
      notes: _notesController.text,
      reminderOffsets: Appointment.normalizeOffsets(_offsets.toList()),
    );

    if (!await ensureProForWrite(context, memberId)) return;
    if (!mounted) return;

    setState(() => _isSaving = true);

    final repo = FirebaseAppointmentRepository.instance;
    Appointment saved;
    try {
      if (_isEdit) {
        await repo.update(memberId, draft);
        saved = draft;
      } else {
        saved = await repo.add(memberId, draft);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (isProDenied(e)) {
        await showProRequiredDialog(context);
      } else {
        _showMessage(l10n.apptSaveFailed);
      }
      return;
    }

    // Reminders on this phone. Never blocks or undoes the saved appointment.
    await AppointmentReminders.instance.schedule(
      memberId,
      saved,
      doctorName: _selectedDoctor?.name,
    );

    if (!mounted) return;
    Navigator.of(context).pop(
      _isEdit ? AppointmentFormResult.updated : AppointmentFormResult.added,
    );
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    final memberId = _memberId;
    if (existing == null || memberId == null || _isSaving) return;
    final l10n = AppLocalizations.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.apptDeleteTitle),
        content: Text(l10n.apptDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.apptDeleteAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseAppointmentRepository.instance.delete(
        memberId,
        existing.id,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(l10n.apptDeleteFailed);
      return;
    }

    await AppointmentReminders.instance.cancel(existing);

    if (!mounted) return;
    Navigator.of(context).pop(AppointmentFormResult.deleted);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    child: _buildContent(),
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
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
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
                  _isEdit ? l10n.apptEditTitle : l10n.apptAddTitle,
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
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.apptDetailsSection,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),

        const SizedBox(height: 14),

        _buildLabel(l10n.apptDateTime),
        const SizedBox(height: 6),
        _buildDateTimeCard(l10n),

        const SizedBox(height: 14),

        _buildLabel(l10n.apptDoctor),
        const SizedBox(height: 6),
        _buildDoctorCard(l10n),

        const SizedBox(height: 14),

        _buildLabel(l10n.apptType),
        const SizedBox(height: 8),
        _buildTypeSelector(l10n),

        const SizedBox(height: 16),

        _buildLabel(l10n.apptLocation),
        const SizedBox(height: 6),
        _buildLocationField(l10n),

        const SizedBox(height: 16),

        Row(
          children: [
            _buildLabel(l10n.apptNotes),
            const Spacer(),
            Text(
              l10n.apptOptional,
              style: const TextStyle(color: AppColors.textTeal, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildNotesField(l10n),

        const SizedBox(height: 16),

        _buildLabel(l10n.apptRemindersTitle),
        const SizedBox(height: 2),
        Text(
          l10n.apptRemindersSubtitle,
          style: const TextStyle(color: AppColors.textTeal, fontSize: 10),
        ),
        const SizedBox(height: 8),
        _buildReminderChips(l10n),

        const SizedBox(height: 14),

        _buildReminderNote(l10n),

        const SizedBox(height: 20),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.primaryDark.withValues(
                alpha: 0.65,
              ),
              elevation: 4,
              shadowColor: AppColors.primaryDark.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
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
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 17),
                      const SizedBox(width: 7),
                      Text(
                        l10n.apptSave,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 10),

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
                fontSize: 11,
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
                l10n.apptDeleteAction,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // DATE TIME CARD
  // ============================================================

  Widget _buildDateTimeCard(AppLocalizations l10n) {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.upcomingBackground,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.textTeal,
                size: 20,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateTime(_selectedDateTime),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    l10n.apptDateTimeHint,
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DOCTOR CARD
  // ============================================================

  Widget _buildDoctorCard(AppLocalizations l10n) {
    final doctor = _selectedDoctor;

    return InkWell(
      onTap: _showPrescriberPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.upcomingBackground,
              child: Text(
                doctor?.initials ?? '?',
                style: const TextStyle(
                  color: AppColors.textTeal,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor?.name ?? l10n.apptSelectDoctor,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if ((doctor?.specialty ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      doctor!.specialty!,
                      style: const TextStyle(
                        color: AppColors.textTeal,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYPE SELECTOR
  // ============================================================

  Widget _buildTypeSelector(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppointmentType.values.map((type) {
        return _buildChoiceChip(
          label: AppointmentTexts.typeLabel(l10n, type),
          selected: _selectedType == type,
          onTap: () => setState(() => _selectedType = type),
        );
      }).toList(),
    );
  }

  // ============================================================
  // REMINDER CHIPS
  // ============================================================

  Widget _buildReminderChips(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _offsetChoices.map((minutes) {
        return _buildChoiceChip(
          label: _offsetLabel(l10n, minutes),
          selected: _offsets.contains(minutes),
          icon: Icons.notifications_active_outlined,
          onTap: () {
            setState(() {
              if (!_offsets.remove(minutes)) _offsets.add(minutes);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? AppColors.surface : AppColors.textTeal,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.surface : AppColors.textTeal,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELDS
  // ============================================================

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.fieldHint, fontSize: 10),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildLocationField(AppLocalizations l10n) {
    return TextField(
      controller: _locationController,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        LengthLimitingTextInputFormatter(AppointmentLimits.locationMax),
      ],
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
      decoration: _fieldDecoration(l10n.apptLocationHint),
    );
  }

  Widget _buildNotesField(AppLocalizations l10n) {
    return TextField(
      controller: _notesController,
      minLines: 3,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      inputFormatters: [
        LengthLimitingTextInputFormatter(AppointmentLimits.notesMax),
      ],
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
      decoration: _fieldDecoration(l10n.apptNotesHint),
    );
  }

  // ============================================================
  // REMINDER NOTE
  // ============================================================

  Widget _buildReminderNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.primary,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.apptReminderNoteTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  l10n.apptReminderNote,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
