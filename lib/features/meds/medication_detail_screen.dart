import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/app_exception.dart';
import '../../models/medication.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/medication_repository.dart';
import 'edit_medication_screen.dart';

/// Medication Detail Screen (M5)
///
/// Shows full details of a medication:
///   • Drug info (name, strength, form, dose, instructions, rxcui)
///   • Schedule details (type, times, weekdays/cyclical/taper, meal relation, dates)
///   • Flags (lowStock, interaction — empty in Phase A)
///   • Next 3 doses (empty in Phase A — no M6 trigger)
///   • 30-day dose history (empty in Phase A)
///
/// Actions:
///   • Edit (Step 9 — TODO)
///   • Archive/Discontinue (with reason dialog)
///
/// Uses real-time stream for medication document updates.
class MedicationDetailScreen extends StatefulWidget {
  final String profileId;
  final String medicationId;

  const MedicationDetailScreen({
    super.key,
    required this.profileId,
    required this.medicationId,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  bool _isArchiving = false;

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<void> _showArchiveDialog() async {
    final reasonController = TextEditingController();

    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discontinue Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This medication will be archived. '
              'You can still view it in the archived list, '
              'but it will no longer appear in your active medications.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Switched to alternative, Course completed',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (shouldArchive != true) return;

    setState(() => _isArchiving = true);

    try {
      final userId = AuthRepository.instance.currentUid ?? 'unknown';
      await MedicationRepository.instance.archiveMedication(
        profileId: widget.profileId,
        medicationId: widget.medicationId,
        reason: reasonController.text.trim().isEmpty
            ? 'Discontinued by user'
            : reasonController.text.trim(),
        archivedBy: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medication archived.')));
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }

  // ============================================================
  // EDIT (Step 9 — TODO)
  // ============================================================

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMedicationScreen(
          profileId: widget.profileId,
          medicationId: widget.medicationId,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Medication?>(
      stream: MedicationRepository.instance.watchMedication(
        profileId: widget.profileId,
        medicationId: widget.medicationId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: _buildErrorState(snapshot.error.toString()),
          );
        }

        final medication = snapshot.data;

        if (medication == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: _buildNotFoundState(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              medication.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _isArchiving ? null : _navigateToEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: _isArchiving ? null : _showArchiveDialog,
                icon: _isArchiving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.archive_outlined),
                tooltip: 'Discontinue',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBadge(medication),
                const SizedBox(height: 16),
                _buildDrugSection(medication),
                const SizedBox(height: 20),
                _buildScheduleSection(medication),
                const SizedBox(height: 20),
                _buildFlagsSection(medication),
                const SizedBox(height: 20),
                _buildDosesSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(Medication med) {
    final isActive = med.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.formAccent.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.archive,
            size: 16,
            color: isActive ? AppColors.formAccent : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Active' : 'Archived',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.formAccent : Colors.grey,
            ),
          ),
          const Spacer(),
          if (med.isArchived && med.archivedReason != null)
            Expanded(
              child: Text(
                med.archivedReason!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DRUG SECTION
  // ============================================================

  Widget _buildDrugSection(Medication med) {
    return _buildSectionCard(
      title: 'Drug',
      icon: Icons.medication_rounded,
      children: [
        _buildInfoRow('Name', med.name),
        if (med.strength != null) _buildInfoRow('Strength', med.strength!),
        if (med.form != null) _buildInfoRow('Form', med.form!),
        if (med.doseAmount != null)
          _buildInfoRow(
            'Dose Amount',
            '${med.doseAmount} ${med.doseUnit ?? ''}'.trim(),
          ),
        if (med.instructions != null && med.instructions!.isNotEmpty)
          _buildInfoRow('Instructions', med.instructions!),
        if (med.hasRxcui) _buildInfoRow('RxNorm ID', med.rxcui!),
        _buildInfoRow('Source', med.source.label),
      ],
    );
  }

  // ============================================================
  // SCHEDULE SECTION
  // ============================================================

  Widget _buildScheduleSection(Medication med) {
    final s = med.schedule;
    return _buildSectionCard(
      title: 'Schedule',
      icon: Icons.schedule_rounded,
      children: [
        _buildInfoRow('Type', s.type.label),
        _buildInfoRow('Summary', s.description),
        if (s.times.isNotEmpty) _buildInfoRow('Times', s.times.join(', ')),
        if (s.weekdays.isNotEmpty)
          _buildInfoRow('Weekdays', s.weekdays.map(_weekdayName).join(', ')),
        if (s.cycleOn != null && s.cycleOff != null)
          _buildInfoRow(
            'Cycle',
            '${s.cycleOn} days on, ${s.cycleOff} days off',
          ),
        if (s.taperSteps.isNotEmpty)
          _buildInfoRow('Taper Steps', '${s.taperSteps.length} step(s)'),
        _buildInfoRow('Meal Relation', s.mealRelation.label),
        _buildInfoRow('Start Date', _formatDate(s.startDate)),
        if (s.endDate != null)
          _buildInfoRow('End Date', _formatDate(s.endDate!)),
      ],
    );
  }

  // ============================================================
  // FLAGS SECTION (empty in Phase A — no M9/M10)
  // ============================================================

  Widget _buildFlagsSection(Medication med) {
    final hasFlags = med.hasLowStockFlag || med.hasInteractionFlag;
    return _buildSectionCard(
      title: 'Safety Flags',
      icon: Icons.flag_outlined,
      children: [
        if (!hasFlags)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No active warnings.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.fieldHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else ...[
          if (med.hasInteractionFlag)
            _buildFlagRow(
              'Drug Interaction',
              'This medication may interact with another active medication.',
              Icons.warning,
              Colors.orange,
            ),
          if (med.hasLowStockFlag)
            _buildFlagRow(
              'Low Stock',
              'Running low on supply. Consider refilling soon.',
              Icons.inventory_2,
              AppColors.error,
            ),
        ],
        const SizedBox(height: 8),
        Text(
          'Phase A: Flags are auto-maintained by Cloud Functions (M9, M10). '
          'Available when Blaze plan is enabled.',
          style: TextStyle(fontSize: 11, color: AppColors.fieldHint),
        ),
      ],
    );
  }

  Widget _buildFlagRow(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
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
  // DOSES SECTION (empty in Phase A — no M6 trigger)
  // ============================================================

  Widget _buildDosesSection() {
    return _buildSectionCard(
      title: 'Doses',
      icon: Icons.event_note_outlined,
      children: [
        const Text(
          'No doses generated yet.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.fieldHint,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Phase A: Doses are generated by M6 Cloud Function (Blaze plan). '
          'When enabled, next 3 doses and 30-day history will appear here.',
          style: TextStyle(fontSize: 11, color: AppColors.fieldHint),
        ),
      ],
    );
  }

  // ============================================================
  // STATES
  // ============================================================

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load',
              style: TextStyle(
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

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.fieldHint),
            const SizedBox(height: 16),
            const Text(
              'Medication Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This medication may have been deleted or you may not have access.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.formAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _weekdayName(int day) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day];
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
