import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/app_exception.dart';
import '../../models/drug.dart';
import '../../models/medication.dart';
import '../../models/schedule.dart';
import '../../repositories/medication_repository.dart';
import '../../repositories/auth_repository.dart';
import 'add_medication_scan_screen.dart';
import 'add_medication_search_screen.dart';
import 'schedule_picker_screen.dart';

/// Add Medication – Manual Screen (M5)
///
/// Integration screen that combines:
///   • M4 Drug Search / Label Scan (pre-filled drug data)
///   • M5 Schedule Picker (schedule configuration)
///   • Manual entry fields (dose, instructions, etc.)
///
/// Accepts optional pre-filled data from M4:
///   • preselectedDrug (from AddMedicationSearchScreen)
///   • scanResult (from AddMedicationScanScreen)
///
/// If neither is provided, starts empty (pure manual entry).
///
/// On save, creates a Medication via MedicationRepository and pops
/// with the new medication ID.
class AddMedicationManualScreen extends StatefulWidget {
  final String profileId;

  /// Pre-selected drug from M4 Search screen (optional)
  final Drug? preselectedDrug;

  /// Scan result from M4 Scan screen (optional)
  final MedicationScanResult? scanResult;

  const AddMedicationManualScreen({
    super.key,
    required this.profileId,
    this.preselectedDrug,
    this.scanResult,
  });

  @override
  State<AddMedicationManualScreen> createState() =>
      _AddMedicationManualScreenState();
}

class _AddMedicationManualScreenState extends State<AddMedicationManualScreen> {
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _formController = TextEditingController();
  final _doseAmountController = TextEditingController();
  final _doseUnitController = TextEditingController();
  final _instructionsController = TextEditingController();

  Schedule? _schedule;
  bool _isLoading = false;
  bool _hasInitialized = false;

  late MedicationSource _source;

  @override
  void initState() {
    super.initState();
    _source = MedicationSource.manual;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _initializeFields();
      _hasInitialized = true;
    }
  }

  void _initializeFields() {
    if (widget.preselectedDrug != null) {
      final drug = widget.preselectedDrug!;
      _nameController.text = drug.name;
      _strengthController.text = drug.strength ?? '';
      _formController.text = drug.doseForm ?? '';
      _source = MedicationSource.search;
    } else if (widget.scanResult != null) {
      final scan = widget.scanResult!;
      _nameController.text = scan.drugName;
      _strengthController.text = scan.strength;
      _formController.text = scan.doseForm;
      _instructionsController.text = scan.directions;
      _source = MedicationSource.scan;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _formController.dispose();
    _doseAmountController.dispose();
    _doseUnitController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // ============================================================
  // SCHEDULE PICKER
  // ============================================================

  Future<void> _pickSchedule() async {
    final result = await Navigator.push<Schedule>(
      context,
      MaterialPageRoute(
        builder: (_) => SchedulePickerScreen(initialSchedule: _schedule),
      ),
    );

    if (result != null) {
      setState(() => _schedule = result);
    }
  }

  // ============================================================
  // SEARCH (for changing drug)
  // ============================================================

  Future<void> _searchDrug() async {
    final drug = await Navigator.push<Drug>(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationSearchScreen()),
    );

    if (drug != null) {
      setState(() {
        _nameController.text = drug.name;
        _strengthController.text = drug.strength ?? '';
        _formController.text = drug.doseForm ?? '';
        _source = MedicationSource.search;
      });
    }
  }

  // ============================================================
  // SCAN (for changing drug via label scan)
  // ============================================================

  Future<void> _scanLabel() async {
    final result = await Navigator.push<MedicationScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScanScreen()),
    );

    if (result != null) {
      setState(() {
        _nameController.text = result.drugName;
        _strengthController.text = result.strength;
        _formController.text = result.doseForm;
        _instructionsController.text = result.directions;
        _source = MedicationSource.scan;
      });
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveMedication() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      _showError('Drug name is required');
      return;
    }

    if (_schedule == null) {
      _showError('Please set a schedule before saving');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthRepository.instance.currentUser;
      final userId = user?.uid ?? 'unknown';
      final now = DateTime.now();

      // Parse doseAmount (nullable)
      final doseAmountStr = _doseAmountController.text.trim();
      final doseAmount = double.tryParse(doseAmountStr);

      // Get rxcui from preselected drug (if any)
      String? rxcui;
      if (widget.preselectedDrug != null) {
        rxcui = widget.preselectedDrug!.rxcui;
      } else if (widget.scanResult?.matchedDrug != null) {
        rxcui = widget.scanResult!.matchedDrug!.rxcui;
      }

      final medication = Medication(
        id: '',
        profileId: widget.profileId,
        name: _nameController.text.trim(),
        strength: _strengthController.text.trim().isEmpty
            ? null
            : _strengthController.text.trim(),
        form: _formController.text.trim().isEmpty
            ? null
            : _formController.text.trim(),
        doseAmount: doseAmount,
        doseUnit: _doseUnitController.text.trim().isEmpty
            ? null
            : _doseUnitController.text.trim(),
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        rxcui: rxcui,
        status: MedicationStatus.active,
        lowStockDays: 7,
        source: _source,
        schedule: _schedule!,
        createdAt: now,
        createdBy: userId,
        updatedAt: now,
        updatedBy: userId,
      );

      final medId = await MedicationRepository.instance.createMedication(
        profileId: widget.profileId,
        medication: medication,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication saved successfully!')),
        );
        Navigator.of(context).pop(medId);
      }
    } on AppException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save medication: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveMedication,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSourceBadge(),
            const SizedBox(height: 16),
            _buildDrugSection(),
            const SizedBox(height: 20),
            _buildDoseSection(),
            const SizedBox(height: 20),
            _buildInstructionsSection(),
            const SizedBox(height: 20),
            _buildScheduleSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SOURCE BADGE
  // ============================================================

  Widget _buildSourceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.formAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_source.icon, size: 16, color: AppColors.formAccent),
          const SizedBox(width: 8),
          Text(
            _source.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.formAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRUG SECTION
  // ============================================================

  Widget _buildDrugSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Drug',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _searchDrug,
                  icon: const Icon(Icons.search, size: 20),
                  color: AppColors.formAccent,
                  tooltip: 'Search drug catalog',
                ),
                IconButton(
                  onPressed: _scanLabel,
                  icon: const Icon(Icons.document_scanner, size: 20),
                  color: AppColors.formAccent,
                  tooltip: 'Scan label',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _nameController,
          label: 'Drug Name *',
          hint: 'e.g., Metformin 500 MG',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _strengthController,
                label: 'Strength',
                hint: 'e.g., 500 MG',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _formController,
                label: 'Form',
                hint: 'e.g., Tablet',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DOSE SECTION
  // ============================================================

  Widget _buildDoseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dose',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _doseAmountController,
                label: 'Amount',
                hint: 'e.g., 1',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _doseUnitController,
                label: 'Unit',
                hint: 'e.g., tablet',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // INSTRUCTIONS SECTION
  // ============================================================

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instructions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _instructionsController,
          label: 'Directions',
          hint: 'e.g., Take with food, twice daily',
          maxLines: 3,
        ),
      ],
    );
  }

  // ============================================================
  // SCHEDULE SECTION
  // ============================================================

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickSchedule,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _schedule != null
                    ? AppColors.formAccent
                    : AppColors.outline,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _schedule != null ? Icons.event_available : Icons.schedule,
                  color: _schedule != null
                      ? AppColors.formAccent
                      : AppColors.fieldHint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_schedule != null) ...[
                        Text(
                          _schedule!.type.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _schedule!.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else
                        const Text(
                          'Tap to set schedule',
                          style: TextStyle(color: AppColors.fieldHint),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.fieldHint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REUSABLE TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.fieldHint),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.formAccent,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EXTENSION: MedicationSource icon
// ============================================================

extension MedicationSourceIcon on MedicationSource {
  IconData get icon {
    switch (this) {
      case MedicationSource.search:
        return Icons.search;
      case MedicationSource.scan:
        return Icons.document_scanner;
      case MedicationSource.manual:
        return Icons.edit;
    }
  }
}
