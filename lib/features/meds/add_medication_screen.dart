import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../models/drug.dart';
import '../../repositories/drug_repository.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_avatar.dart';
import 'add_medication_manual_screen.dart';
import 'add_medication_scan_screen.dart';
import 'interaction_warning_data.dart';
import 'interaction_warning_screen.dart';
import 'interaction_checker.dart';

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
  final String profileId;

  const AddMedicationScreen({super.key, required this.profileId});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _searchController = TextEditingController();

  List<Drug> _results = [];
  bool _hasSearched = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= SEARCH — live (DrugRepository) =================
  Future<void> _onSearchChanged(String query) async {
    final trimmed = query.trim();
    setState(() {
      _hasSearched = trimmed.isNotEmpty;
      _isSearching = trimmed.isNotEmpty;
    });

    final results = trimmed.isEmpty
        ? <Drug>[]
        : await DrugRepository.instance.searchDrugs(trimmed);

    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
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
      _isSearching = false;
    });
  }

  // ================= ACTIONS =================
  Future<void> _selectMedicine(Drug drug) async {
    // Step 3: Check for interactions with existing medications
    // Get existing medications from Firestore
    List<String> existingMeds = [];
    try {
      final medSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.profileId)
          .collection('medications')
          .get();
      existingMeds = medSnapshot.docs
          .map((doc) => (doc.data()['name'] as String?) ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      // If we can't fetch, skip interaction check
      existingMeds = [];
    }

    // Step 2: Check for duplicate medication
    if (!mounted) return;
    if (InteractionChecker.checkDuplicate(drug.name, existingMeds)) {
      final action = await Navigator.of(context).push<InteractionWarningAction>(
        MaterialPageRoute(
          builder: (_) => InteractionWarningScreen(
            data: InteractionWarningData.duplicateWarning,
          ),
        ),
      );

      if (!mounted || action == null) return;

      if (action != InteractionWarningAction.proceed) {
        return;
      }
    }

    if (!mounted) return;

    // Step 3: Check for interactions with existing medications
    final interactions = InteractionChecker.checkInteractions(drug.name, existingMeds);

    if (interactions.isNotEmpty) {
      // Show interaction warning with real data
      final warningData = InteractionChecker.buildWarningData(drug.name, interactions);
      if (warningData != null) {
        final action = await Navigator.of(context).push<InteractionWarningAction>(
          MaterialPageRoute(
            builder: (_) => InteractionWarningScreen(
              data: warningData,
            ),
          ),
        );

        if (!mounted || action == null) return;

        if (action == InteractionWarningAction.proceed) {
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddMedicationManualScreen(
                profileId: widget.profileId,
                preselectedDrug: drug,
              ),
            ),
          );
        }
        return;
      }
    }

    // No interactions found — proceed directly
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMedicationManualScreen(
          profileId: widget.profileId,
          preselectedDrug: drug,
        ),
      ),
    );
  }

  Future<void> _scanLabel() async {
    final result = await Navigator.of(context).push<MedicationScanResult>(
      MaterialPageRoute(builder: (_) => const AddMedicationScanScreen()),
    );
    if (!mounted || result == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMedicationManualScreen(
          profileId: widget.profileId,
          scanResult: result,
        ),
      ),
    );
  }

  void _addManually() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMedicationManualScreen(profileId: widget.profileId),
      ),
    );
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
    final l10n = AppLocalizations.of(context);
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

                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 38),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_results.isEmpty)
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

                    if (!_isSearching && _results.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      // ---- Tip card ----
                      _buildTipCard(),
                      const SizedBox(height: 24),

                      // ---- Manual link ----
                      _buildManualLink(),
                      const SizedBox(height: 16),

                      // ---- Privacy line ----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            size: 15,
                            color: AppColors.formAccent,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              l10n.addMedPrivateNote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
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

                Expanded(
                  child: Text(
                    l10n.addMedTitle,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // TODO Backend / Firebase Storage:
                // Central selected user/member profile se profileImageUrl lena hai.
                // AppAvatar local asset aur Firebase/network URL dono support karta hai.
                const AppAvatar(
                  size: 38,
                  ringColor: AppColors.surface,
                  ringWidth: 2,
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
    final l10n = AppLocalizations.of(context);
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
              decoration: InputDecoration(
                hintText: l10n.medsSearchHint,
                hintStyle: const TextStyle(
                  color: AppColors.searchHint,
                  fontSize: 14,
                ),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    color: AppColors.surface,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.addMedScanLabel,
                    style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _TopActionButton(
            label: l10n.addMedSearch,
            icon: Icons.search_rounded,
            selected: true,
            onTap: _search,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TopActionButton(
            label: l10n.addMedScanLabel,
            icon: Icons.document_scanner_outlined,
            onTap: _scanLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TopActionButton(
            label: l10n.addMedManualEntry,
            icon: Icons.edit_note_rounded,
            onTap: _addManually,
          ),
        ),
      ],
    );
  }

  // ================= RESULTS HEADER =================
  Widget _buildResultsHeader() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.addMedMatchingCount(_results.length),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.success,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                l10n.addMedFdaApproved,
                style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.textPrimary,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.addMedTipTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addMedTipBody,
            style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          Text(
            '${l10n.addMedCantFind} ',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          GestureDetector(
            onTap: _addManually,
            child: Text(
              l10n.addMedAddManually,
              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
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
        Text(
          l10n.addMedEmptyTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.addMedEmptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
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
          Text(
            l10n.addMedNoResultsTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addMedNoResultsFor(_searchController.text),
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

  final Drug result;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = [
      if (result.hasStrength) result.strength!,
      if (result.hasDoseForm) result.doseForm!,
    ].join(' · ');
    final badgeText = result.classIds.isNotEmpty
        ? result.classIds.first
        : null;
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
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: const TextStyle(
                      color: AppColors.formSubtitle,
                      fontSize: 12,
                    ),
                  ),
                if (badgeText != null) ...[
                  const SizedBox(height: 7),
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
                      badgeText,
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
              child: Text(
                l10n.addMedSelectAction,
                style: const TextStyle(
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
