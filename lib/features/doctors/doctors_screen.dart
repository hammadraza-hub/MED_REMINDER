import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_avatar.dart';
import 'add_doctor_screen.dart';
import 'doctors_data.dart';
import '../../features/meds/appointment_screen.dart';

/// ============================================================
/// DOCTORS — prescriber list screen
///
/// PURPOSE:
/// File par saare doctors (prescribers) dikhana:
/// • Doctors count + Add Doctor action
/// • Prescriber cards (avatar, specialty, linked meds chip)
/// • Upcoming Visits banner
///
/// SCREEN TYPE:
/// Pushed detail screen — bottom bar NAHI hai.
/// Bottom navigation sirf MedRemindShell (main 5 tabs) mein hai.
/// Back arrow se previous screen par wapas.
///
/// DATA:
/// UI → DoctorsData.allDoctorsFor(memberId)
///
/// MEMBER ISOLATION:
/// ProfileController.memberId se records filter hote hain —
/// Sarah/Mom/Jake ke doctors alag-alag.
///
/// NAVIGATION:
/// Home → Quick Access → Doctors
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// Firestore prescribers/{id} list with linked medication names.
/// ============================================================
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  late List<PrescriberDoctor> _doctors;

  @override
  void initState() {
    super.initState();
    _doctors = DoctorsData.allDoctorsFor(ProfileController.instance.memberId);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _countLabel(AppLocalizations l10n) =>
      l10n.doctorsCountOnFile(_doctors.length);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // NAVIGATION — Appointments
  // ============================================================

  void _openAppointments() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
  }
  // ============================================================
  // BUILD
  //
  // AnnotatedRegion:
  // Status bar style sirf ISI screen par scoped hai.
  // Pop karne par khud revert ho jata hai.
  //
  // IMPORTANT:
  // Bottom bar yahan NAHI hai — ye pushed detail screen hai.
  // Bottom navigation sirf MedRemindShell (main tabs) mein hai.
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

              Expanded(
                child: Text(
                  AppLocalizations.of(context).doctorsTitle,
                  style: const TextStyle(
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopRow(),

          const SizedBox(height: 16),

          if (_doctors.isEmpty)
            _buildEmptyState()
          else
            for (final doctor in _doctors) ...[
              _buildDoctorCard(doctor),

              const SizedBox(height: 16),
            ],

          _buildUpcomingVisitsBanner(),

          const SizedBox(height: 8),

          _buildHint(),
        ],
      ),
    );
  }

  // ============================================================
  // TOP ROW — count + Add Doctor button
  // ============================================================

  Widget _buildTopRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _countLabel(AppLocalizations.of(context)),
            style: const TextStyle(
              color: AppColors.textTeal,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        GestureDetector(
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
            );

            if (!mounted) return;

            if (result == true) {
              setState(() {
                _doctors = DoctorsData.allDoctorsFor(
                  ProfileController.instance.memberId,
                );
              });

              _showMessage(AppLocalizations.of(context).doctorsAdded);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '+',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),

                const SizedBox(width: 6),

                Text(
                  AppLocalizations.of(context).doctorsAdd,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_off_outlined,
            color: AppColors.fieldHint,
            size: 42,
          ),

          const SizedBox(height: 10),

          Text(
            l10n.doctorsEmptyTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            l10n.doctorsEmptySubtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRESCRIBER CARD
  // ============================================================

  Widget _buildDoctorCard(PrescriberDoctor doctor) {
    return GestureDetector(
      onTap: () {
        // TODO: Doctor detail/edit screen — reference UI pending.
        _showMessage(AppLocalizations.of(context).comingSoon(doctor.name));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Doctor avatar — initials (backend photo later).
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.upcomingBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      doctor.initials,
                      style: const TextStyle(
                        color: AppColors.textTeal,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        doctor.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Meds count chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.upcomingBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.textTeal.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    doctor.chipLabel(AppLocalizations.of(context)).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            _buildLinkedMedsFooter(doctor),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedMedsFooter(PrescriberDoctor doctor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inputFill)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 14,
            color: AppColors.textTeal,
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              doctor.medsSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(width: 8),

          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.fieldHint,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPCOMING VISITS BANNER
  // ============================================================

  Widget _buildUpcomingVisitsBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.upcomingBackground, AppColors.successBackground],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textTeal.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: AppColors.textTeal,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.doctorsUpcomingVisits,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.doctorsAppointmentsScheduled(2),
                  style: const TextStyle(
                    color: AppColors.textTeal,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: _openAppointments,
            child: Text(
              l10n.doctorsView,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HINT
  // ============================================================

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        AppLocalizations.of(context).doctorsHint,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textTeal,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
