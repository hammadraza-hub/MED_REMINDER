import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/doctors/appointment_models.dart';
import '../../core/profile/profile_controller.dart';
import '../../core/services/appointment_reminders.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../repositories/firebase_appointment_repository.dart';
import '../../repositories/firebase_doctor_note_repository.dart';
import '../../repositories/firebase_prescriber_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/pro_gate_widgets.dart';
import '../../core/services/pro_access.dart';
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
/// DATA (M16 step 5):
/// FirebaseAppointmentRepository (profiles/{pid}/appointments) +
/// FirebasePrescriberRepository for the doctor names.
///
/// MEMBER ISOLATION:
/// ProfileController.memberId se records filter hote hain —
/// Sarah/Mom/Jake ke appointments alag-alag.
/// ============================================================
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _showUpcoming = true;

  List<Appointment> _appointments = [];
  Map<String, String> _doctorNames = {};
  int _doctorCount = 0;
  int _openNotes = 0;
  bool _loading = true;
  bool _failed = false;
  bool _pro = true;

  @override
  void initState() {
    super.initState();

    _loadAppointments();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadAppointments() async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null || memberId.isEmpty) {
      setState(() {
        _loading = false;
        _appointments = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final appointments = await FirebaseAppointmentRepository.instance.list(
        memberId,
      );

      var names = <String, String>{};
      var doctorCount = 0;
      try {
        final doctors = await FirebasePrescriberRepository.instance.list(
          memberId,
        );
        names = {for (final d in doctors) d.id: d.name};
        doctorCount = doctors.length;
      } catch (_) {
        // Appointments still show; the doctor name is just left out.
      }

      final pro = await ProAccess.gate.canWrite(memberId);

      var openNotes = 0;
      try {
        openNotes = await FirebaseDoctorNoteRepository.instance.openCount(
          memberId,
        );
      } catch (_) {
        // Only the subtitle of the notes card; leave it at 0.
      }

      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _doctorNames = names;
        _doctorCount = doctorCount;
        _openNotes = openNotes;
        _pro = pro;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
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

  List<Appointment> get _filteredAppointments {
    final items = _appointments
        .where((appointment) => appointment.isUpcoming() == _showUpcoming)
        .toList();

    items.sort(
      (a, b) => _showUpcoming
          ? a.startsAt.compareTo(b.startsAt)
          : b.startsAt.compareTo(a.startsAt),
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

              Expanded(
                child: Text(
                  AppLocalizations.of(context).apptTitle,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_loading && !_pro) const ProReadOnlyBanner(),

          _buildActionsRow(),

          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failed)
            _buildErrorState()
          else if (_filteredAppointments.isEmpty)
            _buildEmptyState()
          else
            for (final appointment in _filteredAppointments) ...[
              _buildAppointmentCard(appointment),
              const SizedBox(height: 12),
            ],

          const SizedBox(height: 10),

          _buildResources(),

          const SizedBox(height: 20),

          Text(
            AppLocalizations.of(context).apptListHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
          title: AppLocalizations.of(context).apptUpcoming,
          selected: _showUpcoming,
          onTap: () {
            setState(() {
              _showUpcoming = true;
            });
          },
        ),

        const SizedBox(width: 8),

        _buildFilterButton(
          title: AppLocalizations.of(context).apptPast,
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

  Widget _buildAppointmentCard(Appointment appointment) {
    final l10n = AppLocalizations.of(context);
    final doctorName = _doctorNames[appointment.prescriberId];
    final upcoming = appointment.isUpcoming();

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
                    color: upcoming
                        ? AppColors.upcomingBackground
                        : AppColors.successBackground,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: upcoming ? AppColors.textTeal : AppColors.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName ??
                            AppointmentTexts.typeLabel(l10n, appointment.type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      if (doctorName != null)
                        Text(
                          AppointmentTexts.typeLabel(l10n, appointment.type),
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

                _buildStatusChip(upcoming),
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
                    _formatDate(appointment.startsAt),
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
        upcoming
            ? AppLocalizations.of(context).apptStatusUpcoming
            : AppLocalizations.of(context).apptStatusPast,
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
    final l10n = AppLocalizations.of(context);
    final doctorsLabel = l10n.doctorsCountOnFile(_doctorCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.apptResources,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),

        const SizedBox(height: 10),

        _buildResourceCard(
          icon: Icons.medical_services_outlined,
          title: l10n.apptMyPrescribers,
          subtitle: doctorsLabel,
          onTap: _openPrescribers,
        ),

        const SizedBox(height: 12),

        _buildResourceCard(
          icon: Icons.description_outlined,
          title: l10n.apptQuestionsForDoctor,
          subtitle: l10n.apptQuestionsCount(_openNotes),
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.fieldHint,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.apptLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadAppointments, child: Text(l10n.apptRetry)),
        ],
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
            _showUpcoming
                ? AppLocalizations.of(context).apptNoUpcoming
                : AppLocalizations.of(context).apptNoPast,
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

  Future<void> _openAddAppointment() => _openForm();

  Future<void> _openForm({Appointment? existing}) async {
    // Adding is a Solo Pro feature; opening an existing appointment is always
    // fine (its Save is checked again on the form).
    if (existing == null) {
      final memberId = ProfileController.instance.memberId;
      if (memberId != null && memberId.isNotEmpty) {
        if (!await ensureProForWrite(context, memberId)) return;
      }
      if (!mounted) return;
    }

    final result = await Navigator.of(context).push<AppointmentFormResult>(
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(existing: existing),
      ),
    );

    if (result == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    _showMessage(switch (result) {
      AppointmentFormResult.added => l10n.apptSaved,
      AppointmentFormResult.updated => l10n.apptUpdated,
      AppointmentFormResult.deleted => l10n.apptDeleted,
    });
    _loadAppointments();
  }

  void _openAppointment(Appointment appointment) =>
      _openForm(existing: appointment);

  void _openPrescribers() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DoctorsScreen()));
  }

  Future<void> _openDoctorNotes() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotesForDoctorScreen()));
    if (mounted) _loadAppointments(); // the open-notes count may have changed
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) =>
      DateFormat.yMMMEd(AppLocalizations.of(context).localeName)
          .add_jm()
          .format(date);
}
