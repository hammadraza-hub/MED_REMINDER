import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/app_exception.dart';
import '../../models/medication.dart';
import '../../models/schedule.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/medication_repository.dart';
import 'schedule_picker_screen.dart';

/// Edit Medication Screen (M5)
///
/// Edits an existing medication. Pre-populates fields from the medication
/// document and calls MedicationRepository.updateMedication() on save.
///
/// Per M5 rules, these fields are IMMUTABLE (cannot be changed via update):
///   • rxcui (switch drug = archive old + create new)
///   • source (set at creation)
///   • profileId, createdBy, createdAt
///   • status, archivedReason (use archive flow instead)
///   • quantityOnHand, daysOfSupply, flags (server-maintained)
///
/// Editable fields:
///   • name, strength, form, doseAmount, doseUnit, instructions
///   • schedule (type, times, weekdays, cyclical, taper, meal relation, dates)
class EditMedicationScreen extends StatefulWidget {
  final String profileId;
  final String medicationId;

  /// Optional: pass the already-loaded Medication to skip a Firestore read.
  final Medication? medication;

  const EditMedicationScreen({
    super.key,
    required this.profileId,
    required this.medicationId,
    this.medication,
  });

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _formController = TextEditingController();
  final _doseAmountController = TextEditingController();
  final _doseUnitController = TextEditingController();
  final _instructionsController = TextEditingController();

  Schedule? _schedule;
  bool _isLoading = false;
  bool _isSaving = false;
  Medication? _medication;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _medication = widget.medication;
      _initializeFields();
    } else {
      _loadMedication();
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
  // LOAD MEDICATION (if not passed)
  // ============================================================

  Future<void> _loadMedication() async {
    setState(() => _isLoading = true);

    try {
      final med = await MedicationRepository.instance.getMedication(
        profileId: widget.profileId,
        medicationId: widget.medicationId,
      );

      if (med == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication not found.'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _medication = med;
        _isLoading = false;
      });
      _initializeFields();
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _initializeFields() {
    final med = _medication;
    if (med == null) return;

    _nameController.text = med.name;
    _strengthController.text = med.strength ?? '';
    _formController.text = med.form ?? '';
    _doseAmountController.text = med.doseAmount != null
        ? med.doseAmount.toString()
        : '';
    _doseUnitController.text = med.doseUnit ?? '';
    _instructionsController.text = med.instructions ?? '';
    _schedule = med.schedule;
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
  // SAVE CHANGES
  // ============================================================

  Future<void> _saveChanges() async {
    if (_medication == null) return;

    // Validate
    if (_nameController.text.trim().isEmpty) {
      _showError('Drug name is required');
      return;
    }

    if (_schedule == null) {
      _showError('Schedule is required');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = AuthRepository.instance.currentUid ?? 'unknown';
      final now = DateTime.now();

      // Parse doseAmount
      final doseAmountStr = _doseAmountController.text.trim();
      final doseAmount = double.tryParse(doseAmountStr);

      // Create updated medication (keeping immutable fields from original)
      final updated = _medication!.copyWith(
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
        schedule: _schedule!,
        updatedAt: now,
        updatedBy: userId,
      );

      // updateMedication uses toJsonForUpdate() which:
      //   - Removes server-maintained fields (quantityOnHand, daysOfSupply, flags)
      //   - Removes lifecycle fields (status, archivedReason)
      //   - Removes immutable fields (profileId, createdBy, createdAt, source, rxcui)
      await MedicationRepository.instance.updateMedication(
        profileId: widget.profileId,
        medication: updated,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Medication'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Medication'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isSaving)
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
              onPressed: _saveChanges,
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
            _buildImmutableWarning(),
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
  // IMMUTABLE WARNING
  // ============================================================

  Widget _buildImmutableWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'To change the drug (RxNorm ID), archive this medication and add a new one.',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
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
        const Text(
          'Drug',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
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
