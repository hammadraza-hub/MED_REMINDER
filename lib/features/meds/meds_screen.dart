import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/profile/profile_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medication.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/medication_repository.dart';
import '../../widgets/app_avatar.dart';
import 'add_medication_screen.dart';
import 'allergies_screen.dart';
import 'edit_medication_screen.dart';
import 'inventory_screen.dart';
import 'medication_detail_screen.dart';
import 'pharmacy_info_screen.dart';
import 'side_effects_screen.dart';

/// ============================================================
/// MEDS — saari medications
///
/// ARCHITECTURE (M7):
/// UI → MedicationRepository (Firestore) → Firestore
///
/// UI design: original dark-header layout preserved
/// (header, search, manage tiles, active/archived tabs,
///  swipe-to-discontinue cards with progress bars).
///
/// Data: Firestore real-time streams.
/// Profile ID: fetched from users/{uid}.selectedMemberId.
///
/// NOTE:
/// Manage tiles (Inventory / Allergies / Side Effects / Pharmacy)
/// abhi "coming soon" dikhate hain — unke dedicated screens
/// M5 migration ke baad re-wire karne hain.
/// ============================================================

enum MedicineType { tablet, capsule, liquid, drops, injection }

String medicineTypeLabel(AppLocalizations l10n, MedicineType type) {
  switch (type) {
    case MedicineType.capsule:
      return 'Capsule';
    case MedicineType.liquid:
      return 'Liquid';
    case MedicineType.drops:
      return 'Drops';
    case MedicineType.injection:
      return 'Injection';
    case MedicineType.tablet:
      return 'Tablet';
  }
}

IconData medicineTypeIcon(MedicineType type) {
  switch (type) {
    case MedicineType.capsule:
      return Icons.medication_outlined;
    case MedicineType.liquid:
      return Icons.water_drop_outlined;
    case MedicineType.drops:
      return Icons.water_drop_outlined;
    case MedicineType.injection:
      return Icons.vaccines_outlined;
    case MedicineType.tablet:
      return Icons.medication_rounded;
  }
}

MedicineType medicineTypeFromForm(String? form) {
  switch (form?.trim().toLowerCase()) {
    case 'capsule':
      return MedicineType.capsule;
    case 'liquid':
      return MedicineType.liquid;
    case 'drops':
      return MedicineType.drops;
    case 'injection':
      return MedicineType.injection;
    case 'tablet':
    default:
      return MedicineType.tablet;
  }
}

class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  final _searchController = TextEditingController();

  String? _firestoreProfileId;
  bool _profileLoading = true;

  List<Medication> _activeMedications = [];
  List<Medication> _archivedMedications = [];
  bool _medicationsLoading = true;

  StreamSubscription<List<Medication>>? _activeSubscription;
  StreamSubscription<List<Medication>>? _archivedSubscription;

  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    ProfileController.instance.addListener(_handleProfileChanged);
    _fetchFirestoreProfileId();
  }

  @override
  void dispose() {
    ProfileController.instance.removeListener(_handleProfileChanged);
    _activeSubscription?.cancel();
    _archivedSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleProfileChanged() {
    _fetchFirestoreProfileId();
  }

  // ============================================================
  // FIRESTORE PROFILE ID
  // ============================================================

  Future<void> _fetchFirestoreProfileId() async {
    try {
      final uid = AuthRepository.instance.currentUid;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _firestoreProfileId = null;
          _profileLoading = false;
          _medicationsLoading = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      String? profileId;
      if (userDoc.exists) {
        profileId = userDoc.data()!['selectedMemberId'] as String?;
      }

      if (profileId == null || profileId.isEmpty) {
        final q = await FirebaseFirestore.instance
            .collection('profiles')
            .where('ownerUid', isEqualTo: uid)
            .where('kind', isEqualTo: 'self')
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          profileId = q.docs.first.id;
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'selectedMemberId': profileId,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _firestoreProfileId = profileId;
        _profileLoading = false;
      });
      _subscribeMedications();
    } catch (e) {
      debugPrint('Failed to fetch profile ID: $e');
      if (!mounted) return;
      setState(() {
        _profileLoading = false;
        _medicationsLoading = false;
      });
    }
  }

  // ============================================================
  // MEDICATION STREAMS (Firestore)
  // ============================================================

  void _subscribeMedications() {
    _activeSubscription?.cancel();
    _archivedSubscription?.cancel();

    final memberId = _firestoreProfileId;
    if (memberId == null || memberId.isEmpty) {
      setState(() {
        _activeMedications = [];
        _archivedMedications = [];
        _medicationsLoading = false;
      });
      return;
    }

    setState(() {
      _medicationsLoading = true;
    });

    _activeSubscription = MedicationRepository.instance
        .watchActiveMedications(memberId)
        .listen(
          (medications) {
            if (!mounted) return;
            setState(() {
              _activeMedications = medications;
              _medicationsLoading = false;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Active medications stream failed: $error');
            if (!mounted) return;
            setState(() {
              _medicationsLoading = false;
            });
          },
        );

    _archivedSubscription = MedicationRepository.instance
        .watchArchivedMedications(memberId)
        .listen(
          (medications) {
            if (!mounted) return;
            setState(() {
              _archivedMedications = medications;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Archived medications stream failed: $error');
          },
        );
  }

  // ============================================================
  // PRESENTATION MAPPING
  // ============================================================

  _MedicinePresentation _toPresentation(Medication medication) {
    return _MedicinePresentation(
      id: medication.id,
      name: medication.name,
      dose: medication.strength ?? '',
      type: medicineTypeFromForm(medication.form),
      frequency: medication.schedule.description,
      nextDose: '—',
      isLowStock: medication.hasLowStockFlag,
      hasInteraction: medication.hasInteractionFlag,
      isCourse: false,
      supplyDaysLeft: 0,
      courseDay: 0,
      courseTotalDays: 0,
      imagePath: null,
      isArchived: _showArchived,
    );
  }

  List<_MedicinePresentation> get _filteredMeds {
    final source = _showArchived ? _archivedMedications : _activeMedications;
    final presentations = source.map(_toPresentation).toList();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return presentations;
    return presentations
        .where(
          (m) =>
              m.name.toLowerCase().contains(query) ||
              m.dose.toLowerCase().contains(query),
        )
        .toList();
  }

  int get _lowStockCount =>
      _activeMedications.where((m) => m.hasLowStockFlag).length;

  // ============================================================
  // ACTIONS
  // ============================================================

  void _addMedicine() {
    final memberId = _firestoreProfileId;
    if (memberId == null || memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Firestore profile found. Please login again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(profileId: memberId),
      ),
    );
  }

  Future<void> _openMedicine(_MedicinePresentation med) async {
    final memberId = _firestoreProfileId;
    if (memberId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MedicationDetailScreen(profileId: memberId, medicationId: med.id),
      ),
    );
  }

  Future<void> _editMedicine(_MedicinePresentation med) async {
    final memberId = _firestoreProfileId;
    if (memberId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EditMedicationScreen(profileId: memberId, medicationId: med.id),
      ),
    );
  }

  Future<void> _discontinueMedicine(_MedicinePresentation med) async {
    // Discontinue flow opens the detail screen where archive/edit is available.
    await _openMedicine(med);
  }

  void _openInventory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryScreen()),
    );
  }

  void _openAllergies() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllergiesScreen()),
    );
  }

  void _openSideEffects() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SideEffectsScreen()),
    );
  }

  void _openPharmacy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PharmacyInfoScreen()),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_profileLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          right: MediaQuery.sizeOf(context).width > 480
              ? (MediaQuery.sizeOf(context).width - 480) / 2 + 16
              : 0,
        ),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: _addMedicine,
          backgroundColor: AppColors.formAccent,
          foregroundColor: AppColors.surface,
          elevation: 7,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    final items = _filteredMeds;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearch(),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.medsManageHeader,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.medsQuickTools,
                style: const TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _ManageTile(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.medsInventory,
                  badge: _lowStockCount > 0
                      ? l10n.medsLowBadge(_lowStockCount)
                      : null,
                  onTap: _openInventory,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ManageTile(
                  icon: Icons.shield_outlined,
                  label: l10n.medsAllergies,
                  onTap: _openAllergies,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ManageTile(
                  icon: Icons.assignment_outlined,
                  label: l10n.medsSideEffects,
                  onTap: _openSideEffects,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ManageTile(
                  icon: Icons.local_pharmacy_outlined,
                  label: l10n.medsPharmacy,
                  onTap: _openPharmacy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildTabs(),

          const SizedBox(height: 16),

          if (_medicationsLoading)
            _buildLoadingState()
          else if (items.isEmpty)
            _buildEmptyState()
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _showArchived
                    ? _MedicineCard(
                        medicine: item,
                        onTap: () => _editMedicine(item),
                      )
                    : _SwipeMedicineCard(
                        medicine: item,
                        onTap: () => _editMedicine(item),
                        onDiscontinue: () => _discontinueMedicine(item),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DARK HEADER
  // ============================================================

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.medsTitle,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.surface,
                        size: 24,
                      ),
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.notificationDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  const AppAvatarPlaceholder(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.medsMemberMedications(
                            ProfileController.instance.displayName,
                          ),
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.medsActiveCount(_activeMedications.length),
                          style: const TextStyle(
                            color: AppColors.headerSubtext,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _addMedicine,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.formAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.surface,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.formAccent),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(
            Icons.search_rounded,
            color: AppColors.formAccent,
            size: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: l10n.medsSearchHint,
                hintStyle: const TextStyle(
                  color: AppColors.searchHint,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.formAccent,
              ),
            )
          else
            const Icon(
              Icons.tune_rounded,
              color: AppColors.formAccent,
              size: 23,
            ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _TabButton(
          label: l10n.medsTabActive(_activeMedications.length),
          selected: !_showArchived,
          onTap: () {
            setState(() {
              _showArchived = false;
            });
          },
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: l10n.medsTabArchived(_archivedMedications.length),
          selected: _showArchived,
          onTap: () {
            setState(() {
              _showArchived = true;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.formAccent),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medication_outlined,
            color: AppColors.fieldHint,
            size: 45,
          ),
          const SizedBox(height: 10),
          Text(
            _showArchived ? l10n.medsEmptyArchived : l10n.medsEmpty,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICINE PRESENTATION
//
// Firestore Medication model ko UI-friendly presentation mein
// map karta hai. Original Medicine class (meds_data.dart) ki
// jagah ye self-contained class use hoti hai.
// ============================================================

class _MedicinePresentation {
  const _MedicinePresentation({
    required this.id,
    required this.name,
    required this.dose,
    required this.type,
    required this.frequency,
    required this.nextDose,
    required this.isLowStock,
    required this.hasInteraction,
    required this.isCourse,
    required this.supplyDaysLeft,
    required this.courseDay,
    required this.courseTotalDays,
    required this.imagePath,
    required this.isArchived,
  });

  final String id;
  final String name;
  final String dose;
  final MedicineType type;
  final String frequency;
  final String nextDose;
  final bool isLowStock;
  final bool hasInteraction;
  final bool isCourse;
  final int supplyDaysLeft;
  final int courseDay;
  final int courseTotalDays;
  final String? imagePath;
  final bool isArchived;

  IconData get typeIcon => medicineTypeIcon(type);

  String? get typeImageAsset => null;

  double get progressValue {
    if (isCourse && courseTotalDays > 0) {
      return (courseDay / courseTotalDays).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String get endsOnLabel => '';

  String supplyLabel(AppLocalizations l10n) {
    if (supplyDaysLeft > 0) {
      return '$supplyDaysLeft days left';
    }
    return '';
  }

  bool get hasSupplyInfo => isCourse || supplyDaysLeft > 0;
}

// ============================================================
// HEADER AVATAR
// ============================================================

class AppAvatarPlaceholder extends StatelessWidget {
  const AppAvatarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppAvatar(
      size: 35,
      ringColor: AppColors.surface,
      ringWidth: 2,
    );
  }
}

// ============================================================
// TAB BUTTON
// ============================================================

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.surface : AppColors.formAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MANAGE TILE
// ============================================================

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.035),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.manageIconFill,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.formAccent),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lowBadgeBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.lowBadgeBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.lowBadgeText,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SWIPE MEDICINE CARD
// ============================================================

class _SwipeMedicineCard extends StatefulWidget {
  const _SwipeMedicineCard({
    required this.medicine,
    required this.onTap,
    required this.onDiscontinue,
  });

  final _MedicinePresentation medicine;
  final VoidCallback onTap;
  final VoidCallback onDiscontinue;

  @override
  State<_SwipeMedicineCard> createState() => _SwipeMedicineCardState();
}

class _SwipeMedicineCardState extends State<_SwipeMedicineCard> {
  static const double _actionWidth = 100;
  double _dragOffset = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-_actionWidth, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    setState(() {
      if (velocity < -300 || _dragOffset < -(_actionWidth / 2)) {
        _dragOffset = -_actionWidth;
      } else {
        _dragOffset = 0;
      }
    });
  }

  void _closeAction() {
    if (_dragOffset == 0) return;
    setState(() {
      _dragOffset = 0;
    });
  }

  void _handleDiscontinueTap() {
    _closeAction();
    widget.onDiscontinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Material(
                  color: AppColors.error,
                  child: InkWell(
                    onTap: _handleDiscontinueTap,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.archive_outlined,
                          color: AppColors.surface,
                          size: 23,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.medsDiscontinue,
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              onTap: () {
                if (_dragOffset != 0) {
                  _closeAction();
                  return;
                }
                widget.onTap();
              },
              child: _MedicineCardContent(medicine: widget.medicine),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICINE CARD (archived — no swipe)
// ============================================================

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine, required this.onTap});

  final _MedicinePresentation medicine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _MedicineCardContent(medicine: medicine),
    );
  }
}

// ============================================================
// MEDICINE CARD CONTENT
// ============================================================

class _MedicineCardContent extends StatelessWidget {
  const _MedicineCardContent({required this.medicine});

  final _MedicinePresentation medicine;

  @override
  Widget build(BuildContext context) {
    final isLow =
        medicine.isLowStock ||
        (medicine.isCourse && medicine.supplyDaysLeft <= 5);
    final isCourse = medicine.isCourse;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardFill,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                medicine.typeIcon,
                color: isLow ? AppColors.lowBadgeText : AppColors.formAccent,
                size: 25,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        medicine.dose.isEmpty
                            ? medicine.name
                            : '${medicine.name} ${medicine.dose}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isLow)
                      _MedicineBadge(
                        text: l10n.medsLowStock,
                        background: AppColors.lowBadgeBackground,
                        foreground: AppColors.lowBadgeText,
                      )
                    else if (isCourse)
                      _MedicineBadge(
                        text: l10n.medsBadgeActive,
                        background: AppColors.successBackground,
                        foreground: AppColors.success,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${medicineTypeLabel(l10n, medicine.type)} · ${medicine.frequency}',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      isCourse
                          ? Icons.error_outline_rounded
                          : Icons.access_time_rounded,
                      size: 12,
                      color: isCourse
                          ? AppColors.lowBadgeText
                          : AppColors.formSubtitle,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isCourse
                            ? l10n.medsEnds(medicine.endsOnLabel)
                            : l10n.medsNext(medicine.nextDose),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCourse
                              ? AppColors.lowBadgeText
                              : AppColors.formSubtitle,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                if (medicine.hasSupplyInfo) ...[
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: medicine.progressValue,
                                minHeight: 6,
                                backgroundColor: AppColors.progressTrackLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLow
                                      ? AppColors.lowBadgeText
                                      : AppColors.formAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medicine.supplyLabel(l10n),
                              style: TextStyle(
                                color: isLow
                                    ? AppColors.lowBadgeText
                                    : AppColors.formSubtitle,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Padding(
                        padding: EdgeInsets.only(top: 0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.formSubtitle,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEDICINE BADGE
// ============================================================

class _MedicineBadge extends StatelessWidget {
  const _MedicineBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
