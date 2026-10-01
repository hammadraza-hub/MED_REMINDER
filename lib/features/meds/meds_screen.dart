import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'meds_data.dart';
import 'add_medication_screen.dart';
import 'edit_medication_screen.dart';
import 'discontinue_medication_screen.dart';
import 'inventory_screen.dart';

/// ============================================================
/// MEDS — saari medications
///
/// Dark header (Home jaisa) + search + MANAGE tools +
/// Active/Archived tabs + progress-bar cards.
///
/// Active medicine:
/// Left swipe → Discontinue → confirmation → Archived
///
/// Backend: MedsData se — UI zero change! 🎯
/// ============================================================
class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  final _searchController = TextEditingController();
  bool _showArchived = false;

  // ============ STATE — MedsData se ============
  // Backend: Firebase Stream se update hongi
  final List<Medicine> _medicines = MedsData.medicines();
  final List<Medicine> _archived = MedsData.archived();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============ FILTERED — search + tab combo ============
  List<Medicine> get _filteredMeds {
    final source = _showArchived ? _archived : _medicines;

    return MedsData.search(source, _searchController.text);
  }

  // ============ COMPUTED (data se! — hardcoded nahi) ============
  int get _lowStockCount => Medicine.lowStockCount(_medicines);

  // ============================================================
  // ACTIONS
  // ============================================================

  void _addMedicine() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddMedicationScreen()));
  }

  // ================= INVENTORY =================

  void _openInventory() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const InventoryScreen()));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// ============================================================
  /// DISCONTINUE MEDICINE
  ///
  /// Confirmation modal open hoti hai.
  ///
  /// null   → Keep Active / Back / outside tap
  /// String → Archive confirm (reason empty bhi ho sakta hai)
  /// ============================================================
  Future<void> _discontinueMedicine(Medicine medicine) async {
    final reason = await showGeneralDialog<String?>(
      context: context,

      // Background Meds screen visible + dim rahegi
      barrierDismissible: true,
      barrierLabel: 'Close discontinue medication',
      barrierColor: AppColors.headerDark.withValues(alpha: 0.55),

      transitionDuration: const Duration(milliseconds: 220),

      pageBuilder: (context, animation, secondaryAnimation) {
        return DiscontinueMedicationScreen(medicine: medicine);
      },

      // Soft fade + scale — modal feel
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    // User ne Keep Active, outside tap ya back use kiya
    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      _medicines.remove(medicine);
      _archived.add(medicine);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${medicine.name} moved to Archived')),
    );

    // TODO Backend:
    // Firestore / medication repository mein medicine.id
    // ka existing document update karna hai:
    //
    // isArchived = true
    // discontinueReason = reason
    // discontinuedAt = serverTimestamp
    //
    // Previous medication/dose history delete NAHI karni.
    // Reports / adherence future mein preserved history use karegi.
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
          // ================= DARK HEADER =================
          _buildHeader(),

          // ================= MAIN CONTENT =================
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

      // ================= ADD MEDICINE =================
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          right: MediaQuery.sizeOf(context).width > 480
              ? (MediaQuery.sizeOf(context).width - 480) / 2 + 16
              : 0,
        ),
        child: FloatingActionButton(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Search ----
          _buildSearch(),

          const SizedBox(height: 12),

          // ---- MANAGE header ----
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MANAGE',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Quick Tools',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          // ==================================================
          // QUICK TOOLS
          // ==================================================
          Row(
            children: [
              // ================= INVENTORY =================

              Expanded(
                child: _ManageTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  badge: '$_lowStockCount LOW',
                  onTap: _openInventory,
                ),
              ),

              const SizedBox(width: 7),

              // ================= ALLERGIES =================
              Expanded(
                child: _ManageTile(
                  icon: Icons.shield_outlined,
                  label: 'Allergies',
                  count: '${MedsData.allergiesCount()}',
                  onTap: () => _showMessage('Allergies — coming soon'),
                ),
              ),

              const SizedBox(width: 7),

              // ================= SIDE EFFECTS =================
              Expanded(
                child: _ManageTile(
                  icon: Icons.assignment_outlined,
                  label: 'Side Effects',
                  onTap: () => _showMessage('Side Effects — coming soon'),
                ),
              ),

              const SizedBox(width: 7),

              // ================= PHARMACY =================
              Expanded(
                child: _ManageTile(
                  icon: Icons.local_pharmacy_outlined,
                  label: 'Pharmacy',
                  onTap: () => _showMessage('Pharmacy — coming soon'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ---- Active / Archived tabs ----
          _buildTabs(),

          const SizedBox(height: 16),

          // ---- Medicine list ----
          if (_filteredMeds.isEmpty)
            _buildEmptyState()
          else
            ..._filteredMeds.map(
              (medicine) => Padding(
                padding: const EdgeInsets.only(bottom: 12),

                // Archived list mein swipe nahi hoga
                child: _showArchived
                    ? _MedicineCard(
                        medicine: medicine,
                        onTap: () => _openMedicine(medicine),
                      )
                    : _SwipeMedicineCard(
                        medicine: medicine,
                        onTap: () => _openMedicine(medicine),
                        onDiscontinue: () => _discontinueMedicine(medicine),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // OPEN MEDICINE
  // ============================================================

  void _openMedicine(Medicine medicine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditMedicationScreen(
          medicineName: medicine.name,
          medicineStrength: medicine.dose,
          medicineForm: medicine.typeLabel,
          dosesPerDay: medicine.frequency.contains('2x')
              ? 2
              : medicine.frequency.contains('3x')
              ? 3
              : 1,
          pillsRemaining: medicine.supplyDaysLeft,
          isLowStock: medicine.isLowStock,
        ),
      ),
    );
  }

  // ============================================================
  // DARK HEADER
  // ============================================================

  Widget _buildHeader() {
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
              // ============ ROW 1 ============
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Medications',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Bell + red dot
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

              // ============ ROW 2 ============
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Medications',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${_medicines.length} active medications',
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
              decoration: const InputDecoration(
                hintText: 'Search medications...',
                hintStyle: TextStyle(color: AppColors.searchHint, fontSize: 13),
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
    return Row(
      children: [
        _TabButton(
          label: 'Active (${_medicines.length})',
          selected: !_showArchived,
          onTap: () {
            setState(() {
              _showArchived = false;
            });
          },
        ),

        const SizedBox(width: 8),

        _TabButton(
          label: 'Archived (${_archived.length})',
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
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
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
            _showArchived ? 'No archived medicines' : 'No medicines found',
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
// HEADER AVATAR
// ============================================================

class AppAvatarPlaceholder extends StatelessWidget {
  const AppAvatarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO Backend:
    // Same current-user profile image source
    // Home aur Meds dono par use karna hai.

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: const Icon(Icons.person, color: AppColors.fieldHint, size: 24),
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
    this.count,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final String? count;

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

          // ============ LOW badge ============
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

          // ============ Count badge ============
          if (count != null)
            Positioned(
              top: -6,
              right: 5,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.formAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count!,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
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
//
// Active medication:
// Left swipe → Discontinue action reveal
//
// IMPORTANT:
// Swipe medicine ko archive NAHI karta.
// Discontinue button confirmation modal open karta hai.
// ============================================================

class _SwipeMedicineCard extends StatefulWidget {
  const _SwipeMedicineCard({
    required this.medicine,
    required this.onTap,
    required this.onDiscontinue,
  });

  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onDiscontinue;

  @override
  State<_SwipeMedicineCard> createState() => _SwipeMedicineCardState();
}

class _SwipeMedicineCardState extends State<_SwipeMedicineCard> {
  static const double _actionWidth = 100;

  double _dragOffset = 0;

  // ================= DRAG UPDATE =================

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;

      _dragOffset = _dragOffset.clamp(-_actionWidth, 0.0);
    });
  }

  // ================= DRAG END =================

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

  // ================= CLOSE =================

  void _closeAction() {
    if (_dragOffset == 0) {
      return;
    }

    setState(() {
      _dragOffset = 0;
    });
  }

  // ================= DISCONTINUE =================

  void _handleDiscontinueTap() {
    _closeAction();

    widget.onDiscontinue();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        children: [
          // ==================================================
          // RED ACTION
          // ==================================================

          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Material(
                  color: AppColors.error,
                  child: InkWell(
                    onTap: _handleDiscontinueTap,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          color: AppColors.surface,
                          size: 23,
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Discontinue',
                          style: TextStyle(
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

          // ==================================================
          // MOVING MEDICINE CARD
          // ==================================================
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
// MEDICINE CARD
// ============================================================

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine, required this.onTap});

  final Medicine medicine;
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

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final isLow =
        medicine.isLowStock ||
        (medicine.isCourse && medicine.supplyDaysLeft <= 5);

    final isCourse = medicine.isCourse;

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
          // ============ IMAGE ============

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
            child: ClipOval(
              child: medicine.typeImageAsset != null
                  ? Image.asset(
                      medicine.typeImageAsset!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            medicine.typeIcon,
                            color: isLow
                                ? AppColors.lowBadgeText
                                : AppColors.formAccent,
                            size: 25,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        medicine.typeIcon,
                        color: isLow
                            ? AppColors.lowBadgeText
                            : AppColors.formAccent,
                        size: 25,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 13),

          // ============ INFO ============
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Title + badge =====

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${medicine.name} ${medicine.dose}',
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
                        text: 'LOW STOCK',
                        background: AppColors.lowBadgeBackground,
                        foreground: AppColors.lowBadgeText,
                      )
                    else if (isCourse)
                      const _MedicineBadge(
                        text: 'ACTIVE',
                        background: AppColors.successBackground,
                        foreground: AppColors.success,
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${medicine.typeLabel} · ${medicine.frequency}',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 5),

                // ===== Next / Ends =====
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

                    Text(
                      isCourse
                          ? 'Ends ${medicine.endsOnLabel}'
                          : 'Next: ${medicine.nextDose}',
                      style: TextStyle(
                        color: isCourse
                            ? AppColors.lowBadgeText
                            : AppColors.formSubtitle,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                // ===== Progress =====
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
                            medicine.supplyLabel,
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
