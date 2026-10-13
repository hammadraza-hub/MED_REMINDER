import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/locale/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/language_flag.dart';
import 'language_data.dart';

/// ============================================================
/// LANGUAGE SETTINGS SCREEN
///
/// PURPOSE:
/// App display language select karna.
///
/// NAVIGATION:
/// Settings → Language row se khulti hai. Detail screen hone ki
/// wajah se shared AppBottomNavigation reuse hoti hai (Settings tab).
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
///
/// TODO Backend:
/// Selected language ko app-wide (per account) persist karna aur
/// localization resources load karna.
/// ============================================================
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // ============================================================
  // STATE
  // ============================================================

  String _selectedCode = LanguageData.defaultCode;

  @override
  void initState() {
    super.initState();

    _selectedCode = LocaleController.instance.localeCode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final current = LocaleController.instance.localeCode;
    if (current != _selectedCode) {
      setState(() {
        _selectedCode = current;
      });
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _selectLanguage(String code) {
    if (code == _selectedCode) return;

    setState(() {
      _selectedCode = code;
    });

    // Poore app ka display language + RTL update karo (persisted).
    LocaleController.instance.setLocaleCode(code);
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
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
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLanguageCard(),
                        const SizedBox(height: 16),
                        _buildNoteStrip(),
                        const SizedBox(height: 24),
                        _buildDeviceDefault(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 4,
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  l10n.languageTitle,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppAvatar(
                size: 36,
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
  // LANGUAGE CARD
  // ============================================================

  Widget _buildLanguageCard() {
    final languages = LanguageData.languages;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.shareBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < languages.length; i++) ...[
            if (i > 0)
              Container(height: 1, color: AppColors.shareDivider),
            _buildLanguageRow(languages[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageRow(LanguageOption language) {
    final isSelected = language.code == _selectedCode;

    return InkWell(
      onTap: () => _selectLanguage(language.code),
      child: Container(
        color: isSelected ? AppColors.formAccentSoft : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            LanguageFlag(code: language.code),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language.label,
                style: TextStyle(
                  color: AppColors.formAccent,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.formAccent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTE STRIP
  // ============================================================

  Widget _buildNoteStrip() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.shareBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.permissionsCardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.public_rounded,
              size: 16,
              color: AppColors.formAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.languageNote,
              style: const TextStyle(
                color: AppColors.permissionsSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEVICE DEFAULT
  // ============================================================

  Widget _buildDeviceDefault() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Text(
        l10n.languageDeviceDefault,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.permissionsSecondary.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
