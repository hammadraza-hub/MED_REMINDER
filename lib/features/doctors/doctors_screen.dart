import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/doctors/prescriber_models.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medication.dart';
import '../../repositories/firebase_appointment_repository.dart';
import '../../repositories/firebase_prescriber_repository.dart';
import '../../repositories/medication_repository.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/pro_gate_widgets.dart';
import '../../core/services/pro_access.dart';
import 'add_doctor_screen.dart';
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
/// DATA (M16 step 4):
/// FirebasePrescriberRepository (profiles/{pid}/prescribers) + the profile's
/// active medications, grouped by medication.prescriberId.
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
/// ============================================================
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

/// One doctor plus the names of the active medications that name them.
class _DoctorCard {
  const _DoctorCard(this.doctor, this.medNames);

  final Prescriber doctor;
  final List<String> medNames;
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<_DoctorCard> _doctors = const [];
  int _upcomingCount = 0;
  bool _loading = true;
  bool _failed = false;
  bool _pro = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null || memberId.isEmpty) {
      setState(() {
        _loading = false;
        _doctors = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final doctors = await FirebasePrescriberRepository.instance.list(
        memberId,
      );
      final pro = await ProAccess.gate.canWrite(memberId);
      final meds = await MedicationRepository.instance
          .watchActiveMedications(memberId)
          .first;

      var upcoming = 0;
      try {
        upcoming = (await FirebaseAppointmentRepository.instance.list(
          memberId,
          from: DateTime.now(),
        )).length;
      } catch (_) {
        // The banner count is a nice-to-have; the doctors still show.
      }

      final byDoctor = <String, List<String>>{};
      for (final m in meds) {
        final id = m.prescriberId;
        if (id == null || id.isEmpty) continue;
        byDoctor.putIfAbsent(id, () => []).add(_medLabel(m));
      }

      if (!mounted) return;
      setState(() {
        _doctors = [
          for (final d in doctors) _DoctorCard(d, byDoctor[d.id] ?? const []),
        ];
        _upcomingCount = upcoming;
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

  static String _medLabel(Medication m) {
    final strength = m.strength?.trim() ?? '';
    return strength.isEmpty ? m.name : '${m.name} $strength';
  }

  Future<void> _openForm({Prescriber? existing}) async {
    // Adding is a Solo Pro feature; opening an existing doctor is always fine
    // (its Save is checked again on the form).
    if (existing == null) {
      final memberId = ProfileController.instance.memberId;
      if (memberId != null && memberId.isNotEmpty) {
        if (!await ensureProForWrite(context, memberId)) return;
      }
      if (!mounted) return;
    }

    final result = await Navigator.of(context).push<DoctorFormResult>(
      MaterialPageRoute(builder: (_) => AddDoctorScreen(existing: existing)),
    );

    if (!mounted || result == null) return;

    final l10n = AppLocalizations.of(context);
    _showMessage(switch (result) {
      DoctorFormResult.added => l10n.doctorsAdded,
      DoctorFormResult.updated => l10n.doctorsUpdated,
      DoctorFormResult.deleted => l10n.doctorsDeleted,
    });
    _load();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _countLabel(AppLocalizations l10n) =>
      _loading ? '' : l10n.doctorsCountOnFile(_doctors.length);

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
          if (!_loading && !_pro) const ProReadOnlyBanner(),

          _buildTopRow(),

          const SizedBox(height: 16),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failed)
            _buildErrorState()
          else if (_doctors.isEmpty)
            _buildEmptyState()
          else
            for (final card in _doctors) ...[
              _buildDoctorCard(card),

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
          onTap: () => _openForm(),
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
            l10n.doctorsLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: Text(l10n.doctorsRetry)),
        ],
      ),
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRESCRIBER CARD
  // ============================================================

  Widget _buildDoctorCard(_DoctorCard card) {
    final doctor = card.doctor;
    return GestureDetector(
      onTap: () => _openForm(existing: doctor),
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
                        doctor.specialty ?? '',
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
                    AppLocalizations.of(context)
                        .doctorsMedCount(card.medNames.length)
                        .toUpperCase(),
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

            _buildLinkedMedsFooter(card),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedMedsFooter(_DoctorCard card) {
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
              card.medNames.isEmpty
                  ? AppLocalizations.of(context).doctorsNoMedsLinked
                  : card.medNames.join(', '),
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
                  l10n.doctorsAppointmentsScheduled(_upcomingCount),
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
