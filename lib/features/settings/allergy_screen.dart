import 'package:flutter/material.dart';

import '../../models/allergy.dart';
import '../../repositories/allergy_repository.dart';

/// ============================================================
/// ALLERGY SCREEN — M10 Safety Checks
/// ============================================================

class AllergyScreen extends StatefulWidget {
  final String profileId;

  const AllergyScreen({required this.profileId, super.key});

  @override
  State<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  final AllergyRepository _repo = AllergyRepository.instance;

  late Stream<List<Allergy>> _allergiesStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _allergiesStream = _repo.watchAllergies(widget.profileId);
  }

  @override
  void didUpdateWidget(covariant AllergyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profileId != widget.profileId) {
      _initializeStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Allergies',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: StreamBuilder<List<Allergy>>(
        stream: _allergiesStream,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Firestore error state
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final allergies = snapshot.data ?? [];

          // Empty state
          if (allergies.isEmpty) {
            return _buildEmptyState();
          }

          // Allergy list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allergies.length,
            itemBuilder: (context, index) {
              final allergy = allergies[index];

              final severityColor = _severityColor(allergy.severity);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),

                  leading: CircleAvatar(
                    backgroundColor: severityColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: severityColor,
                    ),
                  ),

                  title: Text(
                    allergy.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Severity: ${_severityLabel(allergy.severity)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: severityColor,
                          ),
                        ),

                        if (allergy.description != null &&
                            allergy.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Notes: ${allergy.description}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  trailing: IconButton(
                    tooltip: 'Delete allergy',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      _deleteAllergy(allergy.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAllergyDialog,
        tooltip: 'Add Allergy',
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 75,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),

            const Text(
              'No allergies added',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            const Text(
              'Keep your health profile updated by adding your allergies.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _showAddAllergyDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Allergy'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 55, color: Colors.redAccent),

            const SizedBox(height: 16),

            const Text(
              'Unable to load allergies',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: () {
                setState(_initializeStream);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEVERITY HELPERS
  // ============================================================

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange.shade800;
      case 'mild':
      default:
        return Colors.amber.shade800;
    }
  }

  String _severityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return 'Severe';
      case 'moderate':
        return 'Moderate';
      case 'mild':
      default:
        return 'Mild';
    }
  }

  // ============================================================
  // ADD ALLERGY DIALOG
  // ============================================================

  Future<void> _showAddAllergyDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    String selectedSeverity = 'mild';
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !isSaving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                title: const Text(
                  'Add Allergy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Allergy Name',
                            hintText: 'e.g. Penicillin',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter allergy name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedSeverity,
                          decoration: const InputDecoration(
                            labelText: 'Severity',
                            prefixIcon: Icon(Icons.warning_amber_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'mild',
                              child: Text('Mild'),
                            ),
                            DropdownMenuItem(
                              value: 'moderate',
                              child: Text('Moderate'),
                            ),
                            DropdownMenuItem(
                              value: 'severe',
                              child: Text('Severe'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              selectedSeverity = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Description / Notes',
                            hintText: 'Rash, swelling, reaction details',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            final name = nameController.text.trim();

                            final description = descriptionController.text
                                .trim();

                            final newAllergy = Allergy(
                              id: '',
                              memberId: widget.profileId,
                              name: name,
                              severity: selectedSeverity,
                              description: description.isEmpty
                                  ? null
                                  : description,
                              createdAt: DateTime.now(),
                            );

                            try {
                              await _repo.createAllergy(
                                widget.profileId,
                                newAllergy,
                              );

                              if (!dialogContext.mounted) return;

                              Navigator.of(dialogContext).pop();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Allergy added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() {
                                isSaving = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add allergy: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  // ============================================================
  // DELETE ALLERGY
  // ============================================================

  Future<void> _deleteAllergy(String allergyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Allergy'),

          content: const Text(
            'Are you sure you want to delete this allergy permanently?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repo.deleteAllergy(widget.profileId, allergyId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allergy deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete allergy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
