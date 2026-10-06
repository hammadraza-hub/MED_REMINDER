import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'appointments_data.dart';
import '../../features/doctors/doctors_data.dart';

/// ============================================================
/// ADD APPOINTMENT
///
/// PURPOSE:
/// Schedule an appointment reminder.
///
/// KEY ELEMENTS:
/// • Date/time picker
/// • Prescriber picker (member ke doctors on file se — live)
/// • Appointment type
/// • Notes field
/// • Smart caregiver alert
///
/// USER ACTIONS:
/// • Select date/time
/// • Select prescriber
/// • Select appointment type
/// • Add optional notes
/// • Save appointment
/// • System schedules reminder notification (notification phase)
///
/// DATA:
/// UI → AppointmentsData.addAppointment(memberId, ...)
///
/// MEMBER ISOLATION:
/// Prescriber list ProfileController.memberId se filter hoti hai —
/// Sarah ke doctors Mom/Jake ko nahi dikhenge.
///
/// NAVIGATION:
/// Appointments → + → Add Appointment
/// Save → pop(true) → Appointments List (reload)
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// BOTTOM BAR:
/// Shared AppBottomNavigation (baaki detail screens jaisi).
///
/// TODO Backend:
/// Firestore appointments/{id} create.
/// TODO Notification:
/// Reminder 24 hours before appointment (flutter_local_notifications).
/// ============================================================
class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _notesController = TextEditingController();

  /// Default: aaj se 7 din aage, 10:30 AM.
  /// Hardcoded 2026 date nahi — hamesha future mein rahega.
  late DateTime _selectedDateTime = _defaultDateTime();

  PrescriberDoctor? _selectedDoctor;

  String _selectedType = 'Follow-up';

  bool _isSaving = false;

  static const List<String> _appointmentTypes = [
    'Follow-up',
    'Checkup',
    'Lab Review',
    'Other',
  ];

  // ============================================================
  // DOCTORS — member se filter
  // ============================================================

  List<PrescriberDoctor> get _memberDoctors {
    return DoctorsData.allDoctorsFor(ProfileController.instance.memberId);
  }

  static DateTime _defaultDateTime() {
    final now = DateTime.now();
    final target = now.add(const Duration(days: 7));

    return DateTime(target.year, target.month, target.day, 10, 30);
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Default: member ka pehla doctor pre-selected (agar ho).
    final doctors = _memberDoctors;

    if (doctors.isNotEmpty) {
      _selectedDoctor = doctors.first;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

    DateTime initialDate = _selectedDateTime;

    if (initialDate.isBefore(DateTime(now.year, now.month, now.day))) {
      initialDate = DateTime(now.year, now.month, now.day);
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
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
  // PRESCRIBER PICKER — member ke doctors se (live data)
  // ============================================================

  void _showPrescriberPicker() {
    final doctors = _memberDoctors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Prescriber',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                if (doctors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.textTeal,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'No doctors on file. Add a doctor first.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < doctors.length; i++) ...[
                    _buildDoctorOption(
                      sheetContext: sheetContext,
                      doctor: doctors[i],
                    ),

                    if (i != doctors.length - 1)
                      const Divider(color: AppColors.divider),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorOption({
    required BuildContext sheetContext,
    required PrescriberDoctor doctor,
  }) {
    final selected = _selectedDoctor?.id == doctor.id;

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
      subtitle: Text(
        doctor.specialty,
        style: const TextStyle(color: AppColors.textTeal, fontSize: 10),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textTeal),
      onTap: () {
        setState(() {
          _selectedDoctor = doctor;
        });

        Navigator.of(sheetContext).pop();
      },
    );
  }

  // ============================================================
  // SAVE — AppointmentsData mein persist hota hai
  // ============================================================

  Future<void> _saveAppointment() async {
    if (_isSaving) return;

    if (_selectedDateTime.isBefore(DateTime.now())) {
      _showMessage('Please select a future date and time.');
      return;
    }

    final doctor = _selectedDoctor;

    if (doctor == null) {
      _showMessage('Please select a doctor.');
      return;
    }

    final memberId = ProfileController.instance.memberId;

    if (memberId == null || memberId.isEmpty) {
      _showMessage('No family member selected.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Appointment in-memory save — Appointments list isse
    // reload karegi. Backend phase mein Firestore create hoga.
    AppointmentsData.addAppointment(
      memberId: memberId,
      doctorName: doctor.name,
      type: _selectedType,
      scheduledAt: _selectedDateTime,
      note: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    // TODO Notification:
    // flutter_local_notifications phase:
    // Reminder 24 hours before _selectedDateTime schedule hoga.

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BUILD
  //
  // AnnotatedRegion:
  // Status bar style sirf ISI screen par scoped hai.
  // Pop karne par khud revert ho jata hai.
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

              const Expanded(
                child: Text(
                  'Add Appointment',
                  style: TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // APPOINTMENT DETAILS
        // ======================================================

        Row(
          children: [
            const Expanded(
              child: Text(
                'APPOINTMENT DETAILS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),

            _buildStepChip(),
          ],
        ),

        const SizedBox(height: 14),

        // ======================================================
        // DATE & TIME
        // ======================================================
        _buildLabel('Date & Time'),

        const SizedBox(height: 6),

        _buildDateTimeCard(),

        const SizedBox(height: 14),

        // ======================================================
        // DOCTOR
        // ======================================================
        _buildLabel('Doctor'),

        const SizedBox(height: 6),

        _buildDoctorCard(),

        const SizedBox(height: 14),

        // ======================================================
        // APPOINTMENT TYPE
        // ======================================================
        _buildLabel('Appointment Type'),

        const SizedBox(height: 8),

        _buildTypeSelector(),

        const SizedBox(height: 16),

        // ======================================================
        // NOTES
        // ======================================================
        Row(
          children: [
            _buildLabel('Notes'),

            const Spacer(),

            const Text(
              'Optional',
              style: TextStyle(color: AppColors.textTeal, fontSize: 9),
            ),
          ],
        ),

        const SizedBox(height: 6),

        _buildNotesField(),

        const SizedBox(height: 16),

        // ======================================================
        // SMART ALERT
        // ======================================================
        _buildSmartAlert(),

        const SizedBox(height: 20),

        // ======================================================
        // SAVE
        // ======================================================
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
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 17),
                      SizedBox(width: 7),
                      Text(
                        'Save Appointment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 10),

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
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textTeal,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP CHIP
  // ============================================================

  Widget _buildStepChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.upcomingBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: AppColors.primary),

          SizedBox(width: 4),

          Text(
            'Step 1 of 1',
            style: TextStyle(
              color: AppColors.textTeal,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

  Widget _buildDateTimeCard() {
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

                  const Text(
                    'Synchronized with calendar',
                    style: TextStyle(color: AppColors.textTeal, fontSize: 9),
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

  Widget _buildDoctorCard() {
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
                _selectedDoctor?.initials ?? '?',
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
                    _selectedDoctor?.name ?? 'Select doctor',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _selectedDoctor?.specialty ?? 'No doctors on file',
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 9,
                    ),
                  ),
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

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _appointmentTypes.map((type) {
        final selected = _selectedType == type;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDark : AppColors.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? AppColors.primaryDark : AppColors.divider,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: selected ? AppColors.surface : AppColors.textTeal,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      minLines: 3,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
      decoration: InputDecoration(
        hintText:
            'e.g. Bring last blood test reports, ask about dosage changes...',
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
      ),
    );
  }

  // ============================================================
  // SMART CAREGIVER ALERT
  // ============================================================

  Widget _buildSmartAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: AppColors.primary,
            size: 20,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Caregiver Alert',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'A reminder notification will be scheduled '
                  'automatically 24 hours before this appointment.',
                  style: TextStyle(
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

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

    final weekday = weekdays[date.weekday - 1];

    final month = months[date.month - 1];

    final day = date.day.toString().padLeft(2, '0');

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$weekday, $day $month ${date.year} · '
        '$hour:$minute $period';
  }
}
