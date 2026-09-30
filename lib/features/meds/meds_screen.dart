import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'meds_data.dart';
import 'add_medication_screen.dart';
import 'edit_medication_screen.dart';

/// ============================================================
/// MEDS — saari medications
///
/// Dark header (Home jaisa) + search + MANAGE tools +
/// Active/Archived tabs + progress-bar cards.
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

  // ============ ACTIONS ============
  void _addMedicine() {
    // Add Medication — search se!
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddMedicationScreen()));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Column(
        children: [
          // ================= DARK HEADER (Home jaisa) =================
          _buildHeader(),

          // ================= MAIN CONTENT =================
          Expanded(
            child: Center(
              // Tablet cap — baqi screens jaisa
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
          foregroundColor: Colors.white,
          elevation: 7,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  // ================= CONTENT =================
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

          // ---- Quick Tools (4 tiles) ----
          Row(
            children: [
              Expanded(
                child: _ManageTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  badge: '$_lowStockCount LOW', // COMPUTED! data se
                  onTap: () => _showMessage('Inventory — coming soon'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ManageTile(
                  icon: Icons.shield_outlined,
                  label: 'Allergies',
                  count: '${MedsData.allergiesCount()}', // data se — hardcoded nahi!
                  onTap: () => _showMessage('Allergies — coming soon'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ManageTile(
                  icon: Icons.assignment_outlined,
                  label: 'Side Effects',
                  onTap: () => _showMessage('Side Effects — coming soon'),
                ),
              ),
              const SizedBox(width: 7),
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
                child: _MedicineCard(
                  medicine: medicine,
                  onTap: () {
                    // Medicine card → EDIT screen! Data ke sath!
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
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= DARK HEADER =================
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
              // ============ ROW 1: Title + Bell + Avatar ============
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Medications',
                      style: TextStyle(
                        color: Colors.white,
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
                        color: Colors.white,
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

                  // User avatar (system widget!)
                  const AppAvatarPlaceholder(),
                ],
              ),
              const SizedBox(height: 12),

              // ============ ROW 2: My Medications + Add ============
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Medications',
                          style: TextStyle(
                            color: Colors.white,
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

                  // Add button (circle)
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
                        color: Colors.white,
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

  // ================= SEARCH =================
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
              onChanged: (_) => setState(() {}), // live search!
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

  // ================= TABS =================
  Widget _buildTabs() {
    return Row(
      children: [
        _TabButton(
          label: 'Active (${_medicines.length})',
          selected: !_showArchived,
          onTap: () => setState(() => _showArchived = false),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: 'Archived (${_archived.length})',
          selected: _showArchived,
          onTap: () => setState(() => _showArchived = true),
        ),
      ],
    );
  }

  // ================= EMPTY =================
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
// HEADER AVATAR — system AppAvatar use karo!
// ============================================================
class AppAvatarPlaceholder extends StatelessWidget {
  const AppAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    // HomeData.userProfileImage — abhi null → icon
    // TODO Backend: same source as Home!
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.formAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MANAGE TILE — icon + label + badge (data se!)
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
  final String? badge; // "1 LOW"
  final String? count; // "2"

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ============ Main tile ============
          Container(
            width: double.infinity,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
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

          // ============ LOW badge (red) ============
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

          // ============ Count badge (green) ============
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
                    color: Colors.white,
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
// MEDICINE CARD — design layout + progress bar (data se!)
// ============================================================
class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine, required this.onTap});

  final Medicine medicine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLow =
        medicine.isLowStock ||
        (medicine.isCourse && medicine.supplyDaysLeft <= 5);
    final isCourse = medicine.isCourse;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ Icon circle ============
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardFill,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                medicine.typeIcon,
                color: isLow ? AppColors.lowBadgeText : AppColors.formAccent,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),

            // ============ Info ============
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + badge
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
                        _badge(
                          text: 'LOW STOCK',
                          background: AppColors.lowBadgeBackground,
                          foreground: AppColors.lowBadgeText,
                        )
                      else if (isCourse)
                        _badge(
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

                  // Next / Ends
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

                  // ============ Progress + Arrow ============
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Progress bar — DATA se value!
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
                              medicine
                                  .supplyLabel, // "Day 4 of 10" / "5 days left"
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
      ),
    );
  }

  Widget _badge({
    required String text,
    required Color background,
    required Color foreground,
  }) {
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
