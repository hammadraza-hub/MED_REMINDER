import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'add_medication_data.dart';
import 'scan_label_screen.dart';
import 'add_manual_screen.dart';

/// ============================================================
/// ADD MEDICATION — search → FDA results → Select
///
/// 3 raste: Search | Scan Label | Manual Entry
/// Shared bottom bar — escape route (MedRemindShell wapas)!
///
/// TODO Backend:
/// - FDA medication search API integration
/// - User-specific medication selection
/// - Firebase medication persistence later
/// ============================================================
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _searchController = TextEditingController();

  List<MedSearchResult> _results = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= SEARCH — live! =================
  void _onSearchChanged(String query) {
    setState(() {
      // TODO Backend:
      // Replace local search with async FDA/backend medication search.
      _results = AddMedicationData.search(query);
      _hasSearched = query.trim().isNotEmpty;
    });
  }

  void _search() {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    _onSearchChanged(query);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _results = [];
      _hasSearched = false;
    });
  }

  // ================= ACTIONS =================
  void _selectMedicine(MedSearchResult med) {
    // TODO Backend:
    // Selected FDA medication should later be passed into the
    // medication setup flow and saved for the current user/family member.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med.name} ${med.strength} selected — details next!'),
      ),
    );
  }

  void _scanLabel() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ScanLabelScreen()));
  }

  void _addManually() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddManualScreen()));
  }

  // ================= SHARED BOTTOM NAVIGATION =================
  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dark header → light status bar icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,

      // ================= BODY =================
      body: Column(
        children: [
          // ---- DARK HEADER ----
          _buildHeader(),

          // ---- CONTENT ----
          Expanded(
            child: Center(
              // Tablet cap
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),

      // ================= SHARED BOTTOM BAR =================
      // Add Medication belongs to the Meds section.
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ================= BODY =================
  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: ConstrainedBox(
            // Minimum height = poori available space
            // (content kam ho to bhi center ho sake!)
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Search (hamesha top) ----
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  // ---- 3 Action Buttons ----
                  _buildActionButtons(),
                  const SizedBox(height: 20),

                  // ---- Content: state ke hisaab se ----
                  if (_hasSearched) ...[
                    _buildResultsHeader(),
                    const SizedBox(height: 14),

                    if (_results.isEmpty)
                      _buildNoResults()
                    else
                      ..._results.map(
                        (result) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ResultCard(
                            result: result,
                            onSelect: () => _selectMedicine(result),
                          ),
                        ),
                      ),

                    if (_results.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      // ---- Tip card ----
                      _buildTipCard(),
                      const SizedBox(height: 24),

                      // ---- Manual link ----
                      _buildManualLink(),
                      const SizedBox(height: 16),

                      // ---- Privacy line ----
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 15,
                            color: AppColors.formAccent,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Private and encrypted on this device',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.formAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else
                    // ============ INITIAL STATE — CENTER MEIN! ============
                    Expanded(child: Center(child: _buildInitialState())),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= DARK HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.surface,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                const Expanded(
                  child: Text(
                    'Add Medication',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // User avatar
                //
                // TODO Backend:
                // Replace placeholder with authenticated user's AppAvatar.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 26,
                    color: AppColors.fieldHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= SEARCH BAR (+ Scan inside) =================
  Widget _buildSearchBar() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.formIcon, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),

          const Icon(Icons.search_rounded, color: AppColors.formIcon, size: 23),

          const SizedBox(width: 10),

          // Live search field
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search medications...',
                hintStyle: TextStyle(color: AppColors.searchHint, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Clear / Options icon
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.fieldHint,
                  size: 20,
                ),
              ),
            )
          else
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.formSubtitle,
                size: 17,
              ),
            ),

          // ---- Scan Label (design: search ke andar!) ----
          GestureDetector(
            onTap: _scanLabel,
            child: Container(
              height: 38,
              margin: const EdgeInsets.only(right: 8, left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: AppColors.formAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    color: AppColors.surface,
                    size: 17,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Scan Label',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3 ACTION BUTTONS =================
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _TopActionButton(
            label: 'Search',
            icon: Icons.search_rounded,
            selected: true,
            onTap: _search,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TopActionButton(
            label: 'Scan Label',
            icon: Icons.document_scanner_outlined,
            onTap: _scanLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TopActionButton(
            label: 'Manual Entry',
            icon: Icons.edit_note_rounded,
            onTap: _addManually,
          ),
        ),
      ],
    );
  }

  // ================= RESULTS HEADER =================
  Widget _buildResultsHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Matching Medications (${_results.length})',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // FDA badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.successBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: AppColors.success,
                size: 15,
              ),
              SizedBox(width: 5),
              Text(
                'FDA Approved',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TIP CARD =================
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border(left: BorderSide(color: AppColors.formIcon, width: 3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.textPrimary,
                size: 19,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: Look for the imprint',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Most Metformin tablets have numbers like '500' or 'M' "
            'pressed on the front to guarantee the exact dosage match.',
            style: TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MANUAL LINK =================
  Widget _buildManualLink() {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          const Text(
            "Can't find your medication? ",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          GestureDetector(
            onTap: _addManually,
            child: const Text(
              'Add Manually',
              style: TextStyle(
                color: AppColors.formAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.formAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= INITIAL STATE =================
  Widget _buildInitialState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: const BoxDecoration(
            color: AppColors.successBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_rounded,
            size: 38,
            color: AppColors.formAccent,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Search for a medication',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Enter a medicine name above or scan its label',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.formSubtitle,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ================= NO RESULTS =================
  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.fieldHint,
          ),
          const SizedBox(height: 14),
          const Text(
            'No medications found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No results for "${_searchController.text}"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.formSubtitle, fontSize: 13),
          ),
          const SizedBox(height: 22),
          _buildManualLink(),
        ],
      ),
    );
  }
}

// ============================================================
// TOP ACTION BUTTON
// ============================================================
class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.formAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.formAccent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.surface : AppColors.formAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.surface : AppColors.formAccent,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RESULT CARD — Select › outlined (design style!)
// ============================================================
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onSelect});

  final MedSearchResult result;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ===== Medicine icon =====
          Container(
            width: 52,
            height: 52,
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
            child: const Icon(
              Icons.medication_outlined,
              size: 27,
              color: AppColors.fieldHint,
            ),
          ),

          const SizedBox(width: 13),

          // ===== Info =====
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${result.strength} · ${result.form} · ${result.route}',
                  style: const TextStyle(
                    color: AppColors.formSubtitle,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),

                // "Common for: X" badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBackground,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    AddMedicationData.badgeFor(result),
                    style: const TextStyle(
                      color: AppColors.formAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ===== Select › =====
          GestureDetector(
            onTap: onSelect,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.formAccent),
              ),
              child: const Text(
                'Select ›',
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 12,
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
