import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_exception.dart';
import '../../core/constants/app_colors.dart';

import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'allergies_data.dart';
import '../../repositories/auth_repository.dart';

import 'dart:async';

import '../../repositories/drug_repository.dart';

/// ============================================================
/// ADD ALLERGY — record a new allergy
///
/// PURPOSE:
/// Naya allergy record banana:
/// • Allergen name (search + autocomplete suggestions)
/// • Reaction details (optional note, 250 char)
/// • Severity level (High / Moderate / Mild)
///
/// NAVIGATION:
/// Allergies list → Add → Add Allergy
/// Save → pop(true) → Allergies list refresh
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
/// Action buttons standard green (formAccent) rakhe gaye hain
/// (design ke dark green ke bajaye — app convention).
///
/// BOTTOM BAR:
/// Shared AppBottomNavigation (baaki add screens jaisi).
///
/// TODO Backend:
/// Firestore allergies/{id} create:
/// { memberId, name, category, severity, symptoms, addedAt }
/// ============================================================
class AddAllergyScreen extends StatefulWidget {
  const AddAllergyScreen({super.key});

  @override
  State<AddAllergyScreen> createState() => _AddAllergyScreenState();
}

class _AddAllergyScreenState extends State<AddAllergyScreen> {
  // M4: Dynamic suggestions — fetched from DrugRepository (drugs.json)
  List<_AllergySuggestion> _suggestions = [];
  Timer? _suggestionDebounce;
  bool _isLoadingSuggestions = false;

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  // Design default: High selected.
  AllergySeverity _severity = AllergySeverity.high;

  int _notesLength = 0;

  // M3: Loading state for async save
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // AUTOCOMPLETE HELPERS
  // ============================================================

  /// M4: _suggestions already filtered by DrugRepository in _loadSuggestions().
  /// Sort: class-level matches (related: false) first as "Primary Match",
  /// then specific drugs (related: true).
  List<_AllergySuggestion> get _visibleSuggestions {
    final classMatches = _suggestions.where((item) => !item.related).toList();
    final drugMatches = _suggestions.where((item) => item.related).toList();
    return [...classMatches, ...drugMatches];
  }

  /// "Primary Match" badge wala suggestion index.
  int _primaryIndexFor(List<_AllergySuggestion> items) {
    final query = _nameController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return 0;
    }

    final index = items.indexWhere(
      (item) => item.name.toLowerCase().contains(query),
    );

    return index == -1 ? 0 : index;
  }

  void _selectSuggestion(String name) {
    setState(() {
      _nameController.text = name;
      _nameController.selection = TextSelection.collapsed(offset: name.length);
    });
  }

  // ============================================================
  // M4: LOAD SUGGESTIONS FROM DRUG REPOSITORY
  // ============================================================
  /// Searches both drug names AND drug classes (e.g., "Penicillins").
  /// Debounced — 300ms wait after user stops typing.
  Future<void> _loadSuggestions(String query) async {
    final trimmed = query.trim().toLowerCase();

    // Cancel any pending debounce timer
    _suggestionDebounce?.cancel();

    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
      return;
    }

    // Debounce — wait 300ms after user stops typing
    _suggestionDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (mounted) setState(() => _isLoadingSuggestions = true);

      try {
        final results = <_AllergySuggestion>[];

        // 1. Search drugs by prefix (matches name + synonyms)
        final drugs = await DrugRepository.instance.searchDrugs(
          trimmed,
          limit: 8,
        );
        for (final drug in drugs) {
          final isIngredientLevel = drug.termType == 'IN';
          String subtitle;

          if (drug.isPakistani) {
            // Pakistani brand → show generic name as subtitle
            final generic = drug.synonyms.isNotEmpty
                ? drug.synonyms.first
                : drug.name;
            subtitle = 'Brand • Generic: $generic';
          } else if (isIngredientLevel) {
            // Active ingredient → show first class
            subtitle = drug.classIds.isNotEmpty
                ? 'Active ingredient • ${drug.classIds.first}'
                : 'Active ingredient';
          } else {
            // Specific drug (SCD) → show strength + dose form
            final parts = <String>[
              if (drug.hasStrength) drug.strength!,
              if (drug.hasDoseForm) drug.doseForm!,
            ];
            subtitle = parts.isNotEmpty ? parts.join(' • ') : 'Medication';
          }

          results.add(
            _AllergySuggestion(
              name: drug.name,
              subtitle: subtitle,
              related: true,
            ),
          );
        }

        // 2. Search by drug class (e.g., "penicil" → "Penicillins")
        final allDrugs = await DrugRepository.instance.getAllDrugs();
        final matchingClasses = <String>{};
        for (final drug in allDrugs) {
          for (final classId in drug.classIds) {
            if (classId.toLowerCase().contains(trimmed)) {
              matchingClasses.add(classId);
            }
          }
        }

        // Add class suggestions (skip if already in results by name)
        for (final className in matchingClasses.take(5)) {
          if (results.any(
            (r) => r.name.toLowerCase() == className.toLowerCase(),
          )) {
            continue;
          }
          results.add(
            _AllergySuggestion(
              name: className,
              subtitle: 'Drug class — flags all related medications',
              related: false,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _suggestions = results.take(8).toList();
            _isLoadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingSuggestions = false;
            _suggestions = [];
          });
        }
      }
    });
  }

  // ============================================================
  // BOTTOM NAVIGATION — shared shell pattern
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// M3: Save allergy to Firestore
  /// Queries Firestore for real profile ID (bypasses ProfileController mock data)
  Future<void> _save() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter an allergen name.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = AuthRepository.instance.currentUid;

      if (uid == null || uid.isEmpty) {
        _showMessage('Not signed in.');
        return;
      }

      // M3: Query Firestore for the user's real profile ID
      // (ProfileController may have old mock data like "local_sarah")
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('memberUids', arrayContains: uid)
          .limit(1)
          .get();

      if (profileSnapshot.docs.isEmpty) {
        _showMessage('No profile found. Please create a profile first.');
        return;
      }

      final profileId = profileSnapshot.docs.first.id;

      // M3: Create allergy in Firestore
      // Path: profiles/{profileId}/allergies/{allergyId}
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .collection('allergies')
          .add({
            'name': name,
            'category': AllergyCategory.medication.name,
            'severity': _severity.name,
            'symptoms': _notesController.text.trim(),
            'addedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _showMessage('$name saved to your allergy list');
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage('Failed to save allergy: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        currentIndex: 1,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ============================================================
  // DARK HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.permissionsHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
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

              const Expanded(
                child: Text(
                  'Add Allergy',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppAvatar(
                size: 33,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIntroRow(),

          const SizedBox(height: 16),

          _buildAllergenSection(),

          const SizedBox(height: 16),

          _buildReactionSection(),

          const SizedBox(height: 16),

          _buildSeveritySection(),

          const SizedBox(height: 16),

          _buildGuardBanner(),

          const SizedBox(height: 20),

          _buildActionStack(),

          const SizedBox(height: 18),

          _buildFooter(),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO ROW — critical pill + step
  // ============================================================

  Widget _buildIntroRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.permissionsInactiveFill,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.permissionsErrorIcon,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 6),

              const Text(
                'CRITICAL SAFETY RECORD',
                style: TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        const Text(
          'Step 1 of 1',
          style: TextStyle(
            color: AppColors.permissionsSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 1 — ALLERGEN NAME
  // ============================================================

  Widget _buildAllergenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ALLERGEN NAME',
                style: TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),

            Text(
              'Required *',
              style: const TextStyle(
                color: AppColors.permissionsErrorIcon,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        _buildNameField(),

        const SizedBox(height: 10),

        ..._buildSuggestionTiles(),
      ],
    );
  }

  Widget _buildNameField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.reportConfigShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        onChanged: (value) {
          setState(() {});
          _loadSuggestions(value); // M4: Fetch from DrugRepository
        },
        style: const TextStyle(
          color: AppColors.reportPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Search drug, class, or ingredient...',
          hintStyle: TextStyle(
            color: AppColors.fieldHint,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          suffixIcon: Icon(
            Icons.search_rounded,
            size: 22,
            color: AppColors.permissionsSecondary,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  List<Widget> _buildSuggestionTiles() {
    // M4: Show loading indicator while fetching from DrugRepository
    if (_isLoadingSuggestions) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }
    final items = _visibleSuggestions;
    final primaryIndex = _primaryIndexFor(items);

    final tiles = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isPrimary = i == primaryIndex;

      if (i > 0) {
        tiles.add(const SizedBox(height: 8));
      }

      tiles.add(_buildSuggestionTile(item, isPrimary: isPrimary));
    }

    return tiles;
  }

  Widget _buildSuggestionTile(
    _AllergySuggestion item, {
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: () {
        _selectSuggestion(item.name);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isPrimary ? AppColors.formAccent : AppColors.transparent,
              width: 4,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.permissionsCardShadow,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.permissionsChipFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.related
                    ? Icons.medication_rounded
                    : Icons.medication_liquid_rounded,
                size: 20,
                color: AppColors.reportPrimary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.reportPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      if (isPrimary) ...[
                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.permissionsBadgeBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Primary Match',
                            style: TextStyle(
                              color: AppColors.reportTargetText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 2),

                  Text(
                    item.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.permissionsSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            if (isPrimary)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.formAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.surface,
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.permissionsSecondary,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 2 — REACTION DETAILS
  // ============================================================

  Widget _buildReactionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'REACTION DETAILS',
                style: TextStyle(
                  color: AppColors.permissionsHeader,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),

            const Text(
              'Optional observation',
              style: TextStyle(
                color: AppColors.permissionsSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.reportConfigShadow,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            children: [
              TextField(
                controller: _notesController,
                maxLines: null,
                minLines: 3,
                maxLength: 250,
                onChanged: (value) {
                  setState(() => _notesLength = value.length);
                },
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Describe symptoms, past occurrences, or onset time...',
                  hintStyle: TextStyle(
                    color: AppColors.fieldHint,
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  counterText: '',
                  isDense: true,
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_notesLength / 250',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 3 — SEVERITY LEVEL
  // ============================================================

  Widget _buildSeveritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEVERITY LEVEL',
          style: TextStyle(
            color: AppColors.permissionsHeader,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(child: _buildSeverityChip(AllergySeverity.high, 'High')),

            const SizedBox(width: 8),

            Expanded(
              child: _buildSeverityChip(AllergySeverity.moderate, 'Moderate'),
            ),

            const SizedBox(width: 8),

            Expanded(child: _buildSeverityChip(AllergySeverity.mild, 'Mild')),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityChip(AllergySeverity severity, String label) {
    final selected = _severity == severity;

    // Unselected indicator severity color (display only).
    final indicatorColor = selected
        ? AppColors.surface
        : _severityIndicatorColor(severity);

    return GestureDetector(
      onTap: () {
        setState(() => _severity = severity);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.reportConfigShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (severity == AllergySeverity.high)
              Icon(Icons.warning_amber_rounded, size: 16, color: indicatorColor)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),

            const SizedBox(width: 6),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.surface
                    : AppColors.permissionsSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityIndicatorColor(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.high:
        return AppColors.permissionsErrorIcon;
      case AllergySeverity.moderate:
        return AppColors.interactionWarningAmber;
      case AllergySeverity.mild:
        return AppColors.symptomMildDot;
    }
  }

  // ============================================================
  // GUARD BANNER — automated interaction guard
  // ============================================================

  Widget _buildGuardBanner() {
    final typedName = _nameController.text.trim();
    final allergen = typedName.isEmpty ? 'this allergen' : typedName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.permissionsSecondary, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.reportConfigShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.reportVitalsTile,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 18,
              color: AppColors.permissionsGreenDark,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automated Interaction Guard',
                  style: TextStyle(
                    color: AppColors.reportPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'MedRemind screens future prescription additions, scans, '
                  'and scheduled dosages against $allergen.',
                  style: const TextStyle(
                    color: AppColors.permissionsSecondary,
                    fontSize: 12,
                    height: 1.35,
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
  // ACTION STACK — save + cancel
  // ============================================================

  Widget _buildActionStack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _save,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.formAccent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shareButtonShadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  size: 20,
                  color: AppColors.surface,
                ),
                SizedBox(width: 8),
                Text(
                  'Save Allergy to Health Profile',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).maybePop();
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Cancel & Return',
                style: TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOOTER — encrypted vault note + home indicator
  // ============================================================

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: AppColors.fieldHint,
            ),

            const SizedBox(width: 5),

            Text(
              'HIPAA-Compliant Encrypted Vault',
              style: TextStyle(color: AppColors.fieldHint, fontSize: 10.5),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          width: 128,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.permissionsInactiveFill,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

/// Autocomplete suggestion item (design mock data).
class _AllergySuggestion {
  const _AllergySuggestion({
    required this.name,
    required this.subtitle,
    this.related = false,
  });

  final String name;
  final String subtitle;
  final bool related;
}
