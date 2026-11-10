import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../models/dose.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/dose_repository.dart';

/// Dashboard Screen (M7 — Today's Doses)
///
/// Shows today's scheduled doses in real-time with logging actions.
/// Per M7 plan: "Dashboard: doses where scheduledAt between startOfDay
///              and endOfDay orderBy scheduledAt as a snapshot listener."
///
/// Actions per dose:
///   • Pending: Take / Skip / Snooze
///   • Taken/Skipped: Undo (within 24h)
///   • Missed: Take / Skip + Reason
///   • Snoozed: Take / Skip
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProfileController.instance.initialize();
    });
  }

  // ============================================================
  // DOSE LOGGING ACTIONS
  // ============================================================

  Future<void> _logDose(Dose dose, DoseStatus status) async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;

    final userId = AuthRepository.instance.currentUid ?? 'unknown';

    try {
      await DoseRepository.instance.logDose(
        profileId: memberId,
        doseId: dose.id,
        status: status,
        loggedBy: userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _undoDose(Dose dose) async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;

    try {
      await DoseRepository.instance.undoDose(
        profileId: memberId,
        doseId: dose.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Dose undone')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _snoozeDose(Dose dose) async {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;

    try {
      await DoseRepository.instance.snoozeDose(
        profileId: memberId,
        doseId: dose.id,
        snoozeDuration: const Duration(minutes: 15),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Snoozed 15 min')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final memberId = ProfileController.instance.memberId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Today'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: memberId == null || memberId.isEmpty
          ? _buildNoProfileState()
          : _buildDosesList(memberId),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 64,
            color: AppColors.fieldHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Profile Selected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a profile to view today\'s doses.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDosesList(String memberId) {
    return StreamBuilder<List<Dose>>(
      stream: DoseRepository.instance.watchTodaysDoses(memberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final doses = snapshot.data ?? [];

        if (doses.isEmpty) {
          return _buildEmptyState();
        }

        // Sort doses by scheduledAt
        doses.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        // Calculate summary
        int taken = 0;
        int total = 0;
        for (final dose in doses) {
          if (!dose.isPrn) {
            total++;
            if (dose.isTaken) taken++;
          }
        }

        return Column(
          children: [
            _buildSummaryHeader(taken, total),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: doses.length,
                itemBuilder: (context, index) {
                  return _buildDoseCard(doses[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUMMARY HEADER
  // ============================================================

  Widget _buildSummaryHeader(int taken, int total) {
    final percentage = total > 0 ? (taken / total * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Row(
        children: [
          // Progress circle
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? taken / total : 0,
                  strokeWidth: 4,
                  backgroundColor: AppColors.outline,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(DoseStatus.taken.colorValue),
                  ),
                ),
                Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$taken of $total taken',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
  // DOSE CARD
  // ============================================================

  Widget _buildDoseCard(Dose dose) {
    final time = _formatTime(dose.scheduledAt.toLocal());
    final statusColor = Color(dose.status.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dose.isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: time + status badge
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppColors.fieldHint),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(dose.status),
              ],
            ),
            const SizedBox(height: 8),
            // Medication name + dose label
            Text(
              dose.medName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (dose.doseLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                dose.doseLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            // Action buttons
            const SizedBox(height: 8),
            _buildDoseActions(dose, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DoseStatus status) {
    final color = Color(status.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // DOSE ACTION BUTTONS
  // ============================================================

  Widget _buildDoseActions(Dose dose, Color statusColor) {
    // Pending or Missed or Snoozed → Take + Skip + (Snooze for pending)
    if (dose.isPending || dose.isMissed || dose.isSnoozed) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _logDose(dose, DoseStatus.taken),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(DoseStatus.taken.colorValue),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Take', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _logDose(dose, DoseStatus.skipped),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(DoseStatus.skipped.colorValue),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: Color(DoseStatus.skipped.colorValue)
                      .withValues(alpha: 0.5),
                ),
              ),
              child: const Text('Skip', style: TextStyle(fontSize: 13)),
            ),
          ),
          if (dose.isPending) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _snoozeDose(dose),
              icon: const Icon(Icons.snooze, size: 18),
              color: Color(DoseStatus.snoozed.colorValue),
              tooltip: 'Snooze 15 min',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      );
    }

    // Taken or Skipped → Undo button (if within 24h)
    if (dose.canUndo()) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _undoDose(dose),
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('Undo', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // No actions available
    return const SizedBox.shrink();
  }

  // ============================================================
  // STATES
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_available,
              size: 64,
              color: AppColors.fieldHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Doses Today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a medication with a schedule to see doses here.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load doses',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  String _formatDate(DateTime dt) {
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}
