import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

import '../../core/profile/profile_controller.dart';
import '../../models/medication.dart';

import '../../repositories/medication_repository.dart';
import 'add_medication_manual_screen.dart';
import 'add_medication_scan_screen.dart';
import 'add_medication_search_screen.dart';
import 'medication_detail_screen.dart';

/// Meds Screen (M5 — Firestore-based)
///
/// Shows a real-time list of active medications for the current profile.
/// Uses MedicationRepository.watchActiveMedications() stream.
///
/// FAB (+) opens a bottom sheet with 3 options:
///   1. Search Drug Catalog (M4) → AddMedicationSearchScreen → Manual
///   2. Scan Label (M4) → AddMedicationScanScreen → Manual
///   3. Manual Entry → AddMedicationManualScreen (empty)
///
/// Tap a medication card → MedicationDetailScreen (Step 8)
class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure ProfileController is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProfileController.instance.initialize();
    });
  }

  // ============================================================
  // ADD MEDICATION — Bottom Sheet with 3 options
  // ============================================================

  void _showAddOptions() {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null || memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No profile selected. Please select a profile first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Medication',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildAddOption(
                icon: Icons.search,
                title: 'Search Drug Catalog',
                subtitle: 'Find from 55+ common drugs',
                onTap: () => _navigateToSearch(memberId),
              ),
              _buildAddOption(
                icon: Icons.document_scanner,
                title: 'Scan Label',
                subtitle: 'Take photo of prescription label',
                onTap: () => _navigateToScan(memberId),
              ),
              _buildAddOption(
                icon: Icons.edit,
                title: 'Manual Entry',
                subtitle: 'Type drug details yourself',
                onTap: () => _navigateToManual(memberId),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.formAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.formAccent),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.fieldHint),
      onTap: onTap,
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _navigateToSearch(String memberId) async {
    Navigator.of(context).pop(); // Close bottom sheet
    final drug = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationSearchScreen()),
    );

    if (drug != null && mounted) {
      // Navigate to Manual screen with pre-selected drug
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddMedicationManualScreen(
            profileId: memberId,
            preselectedDrug: drug,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToScan(String memberId) async {
    Navigator.of(context).pop(); // Close bottom sheet
    final scanResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScanScreen()),
    );

    if (scanResult != null && mounted) {
      // Navigate to Manual screen with scan result
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddMedicationManualScreen(
            profileId: memberId,
            scanResult: scanResult,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToManual(String memberId) async {
    Navigator.of(context).pop(); // Close bottom sheet
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationManualScreen(profileId: memberId),
      ),
    );
  }

  void _navigateToDetail(Medication medication) {
    final memberId = ProfileController.instance.memberId;
    if (memberId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationDetailScreen(
          profileId: memberId,
          medicationId: medication.id,
        ),
      ),
    );
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
        title: const Text('Medications'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: AppColors.formAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: memberId == null || memberId.isEmpty
          ? _buildNoProfileState()
          : _buildMedicationsList(memberId),
    );
  }

  // ============================================================
  // STATES
  // ============================================================

  Widget _buildNoProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 80,
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
              'Please select a profile from the Home screen to view medications.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsList(String memberId) {
    return StreamBuilder<List<Medication>>(
      stream: MedicationRepository.instance.watchActiveMedications(memberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final medications = snapshot.data ?? [];

        if (medications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            return _buildMedicationCard(medications[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 80,
              color: AppColors.fieldHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Medications Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button below to add your first medication.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.formAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
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
            const Icon(Icons.error_outline, size: 80, color: AppColors.error),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.formAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEDICATION CARD
  // ============================================================

  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(medication),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Drug icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.formAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: AppColors.formAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Drug info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (medication.strength != null ||
                        medication.form != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (medication.strength != null) medication.strength!,
                          if (medication.form != null) medication.form!,
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.fieldHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            medication.schedule.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.fieldHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status + flags
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Source badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.outline, width: 0.5),
                    ),
                    child: Text(
                      medication.source.label.substring(0, 3).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (medication.hasInteractionFlag) ...[
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.warning_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ],
                  if (medication.hasLowStockFlag) ...[
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
