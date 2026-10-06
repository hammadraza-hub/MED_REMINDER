import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'appointments_data.dart';
import '../../features/doctors/doctors_data.dart';
import '../../features/doctors/doctors_screen.dart';
import 'add_appointment_screen.dart';
import 'doctor_notes_screen.dart';

/// ============================================================
/// APPOINTMENTS — upcoming and past appointments
///
/// PURPOSE:
/// Upcoming and past appointments.
///
/// KEY ELEMENTS:
/// • List sorted by date
/// • Prescriber name
/// • Appointment type
/// • Upcoming / Past status (date se computed)
///
/// USER ACTIONS:
/// • Tap appointment to view/edit (reference UI pending)
/// • Tap + to add appointment (reference UI pending)
/// • My Prescribers → DoctorsScreen
///
/// SCREEN TYPE:
/// Pushed detail screen.
///
/// BOTTOM BAR:
/// Shared AppBottomNavigation — baaki detail screens jaisa.
/// Tab tap par shell ke us tab par wapas.
///
/// DATA:
/// UI → AppointmentsData.appointmentsFor(memberId)
///
/// MEMBER ISOLATION:
/// ProfileController.memberId se records filter hote hain —
/// Sarah/Mom/Jake ke appointments alag-alag.
///
/// TODO Backend:
/// Firestore appointments/{id} list with prescriber references.
/// ============================================================
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _showUpcoming = true;

  List<AppointmentEntry> _appointments = [];

  @override
  void initState() {
    super.initState();

    _loadAppointments();
  }

  // ============================================================
  // DATA
  // ============================================================

  void _loadAppointments() {
    final memberId = ProfileController.instance.memberId;

    setState(() {
      _appointments = AppointmentsData.appointmentsFor(memberId);
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BOTTOM NAVIGATION — baaki detail screens jaisa shared pattern
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // FILTERED APPOINTMENTS
  //
  // Status date se computed hai — isliye waqt guzarne par
  // appointment khud Upcoming se Past tab mein chala jayega.
  // ============================================================

  List<AppointmentEntry> get _filteredAppointments {
    final items = _appointments
        .where((appointment) => appointment.isUpcoming == _showUpcoming)
        .toList();

    items.sort(
      (a, b) => _showUpcoming
          ? a.scheduledAt.compareTo(b.scheduledAt)
          : b.scheduledAt.compareTo(a.scheduledAt),
    );

    return items;
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
                  'Appointments',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActionsRow(),

          const SizedBox(height: 12),

          if (_filteredAppointments.isEmpty)
            _buildEmptyState()
          else
            for (final appointment in _filteredAppointments) ...[
              _buildAppointmentCard(appointment),
              const SizedBox(height: 12),
            ],

          const SizedBox(height: 10),

          _buildResources(),

          const SizedBox(height: 20),

          const Text(
            'Tap an appointment to view location and details',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTeal,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS + ADD
  // ============================================================

  Widget _buildActionsRow() {
    return Row(
      children: [
        _buildFilterButton(
          title: 'Upcoming',
          selected: _showUpcoming,
          onTap: () {
            setState(() {
              _showUpcoming = true;
            });
          },
        ),

        const SizedBox(width: 8),

        _buildFilterButton(
          title: 'Past',
          selected: !_showUpcoming,
          onTap: () {
            setState(() {
              _showUpcoming = false;
            });
          },
        ),

        const Spacer(),

        Material(
          color: AppColors.primaryDark,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openAddAppointment,
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.add_rounded,
                color: AppColors.surface,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.divider,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.surface : AppColors.textTeal,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _buildAppointmentCard(AppointmentEntry appointment) {
    return GestureDetector(
      onTap: () {
        _openAppointment(appointment);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Calendar icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: appointment.isUpcoming
                        ? AppColors.upcomingBackground
                        : AppColors.successBackground,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: appointment.isUpcoming
                        ? AppColors.textTeal
                        : AppColors.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        appointment.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTeal,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _buildStatusChip(appointment.isUpcoming),
              ],
            ),

            const SizedBox(height: 11),

            Container(height: 1, color: AppColors.inputFill),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: AppColors.textTeal,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    _formatDate(appointment.scheduledAt),
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusChip(bool upcoming) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: upcoming
            ? AppColors.upcomingBackground
            : AppColors.successBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        upcoming ? 'UPCOMING' : 'PAST',
        style: const TextStyle(
          color: AppColors.textTeal,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ============================================================
  // CLINICAL RESOURCES
  // ============================================================

  Widget _buildResources() {
    final doctorsCount = DoctorsData.allDoctorsFor(
      ProfileController.instance.memberId,
    ).length;

    final doctorsLabel = doctorsCount == 1
        ? '1 doctor on file'
        : '$doctorsCount doctors on file';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLINICAL RESOURCES',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),

        const SizedBox(height: 10),

        _buildResourceCard(
          icon: Icons.medical_services_outlined,
          title: 'My Prescribers',
          subtitle: doctorsLabel,
          onTap: _openPrescribers,
        ),

        const SizedBox(height: 12),

        _buildResourceCard(
          icon: Icons.description_outlined,
          title: 'Questions for my Doctor',
          subtitle: '3 notes',
          onTap: _openDoctorNotes,
        ),
      ],
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
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
              child: Icon(icon, color: AppColors.textTeal, size: 20),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
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
              color: AppColors.textTeal,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.textTeal,
            size: 32,
          ),

          const SizedBox(height: 10),

          Text(
            _showUpcoming ? 'No upcoming appointments' : 'No past appointments',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openAddAppointment() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
    );

    if (result == true && mounted) {
      _loadAppointments();
    }
  }

  void _openAppointment(AppointmentEntry appointment) {
    // TODO: Appointment detail/edit screen — reference UI pending.
    _showMessage('${appointment.doctorName} — ${appointment.type}');
  }

  void _openPrescribers() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DoctorsScreen()));
  }

  void _openDoctorNotes() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotesForDoctorScreen()));
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
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

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    final day = date.day.toString().padLeft(2, '0');

    return '$weekday, $day $month ${date.year} · '
        '$hour:$minute $period';
  }
}
