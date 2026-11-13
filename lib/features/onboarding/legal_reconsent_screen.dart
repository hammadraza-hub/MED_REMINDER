import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/legal_service.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/legal_doc_sheet.dart';
import 'onboarding_screen.dart';

/// ============================================================
/// LEGAL RE-CONSENT SCREEN (M13 step 2)
///
/// Shown after sign-in when Remote Config `terms_version` or
/// `privacy_version` is newer than what the user accepted.
/// Non-dismissible: the user must accept (then [next] opens) or
/// sign out. Scheduled reminders keep ringing meanwhile — this
/// only blocks the UI.
/// ============================================================
class LegalReconsentScreen extends StatefulWidget {
  const LegalReconsentScreen({
    super.key,
    required this.uid,
    required this.next,
  });

  final String uid;

  /// Screen to open after the user accepts (the dashboard).
  final WidgetBuilder next;

  @override
  State<LegalReconsentScreen> createState() => _LegalReconsentScreenState();
}

class _LegalReconsentScreenState extends State<LegalReconsentScreen> {
  bool _agreed = false;
  bool _busy = false;

  Future<void> _accept() async {
    if (!_agreed || _busy) return;
    setState(() => _busy = true);
    try {
      await LegalService.instance.accept(widget.uid);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: widget.next),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).legalReconsentError),
          ),
        );
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.instance.signOut();
    } catch (_) {
      // Fall through: still leave this screen.
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      size: 64,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.legalReconsentTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.permissionsHeader,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.legalReconsentBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.shareSecondaryText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _LinkTile(
                      label: l10n.aboutTerms,
                      onTap: () => LegalDocSheet.show(context, 'terms'),
                    ),
                    const SizedBox(height: 8),
                    _LinkTile(
                      label: l10n.aboutPrivacy,
                      onTap: () => LegalDocSheet.show(context, 'privacy'),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _busy
                          ? null
                          : () => setState(() => _agreed = !_agreed),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            activeColor: AppColors.brandTeal,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _agreed = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                l10n.legalReconsentAgree,
                                style: const TextStyle(
                                  color: AppColors.permissionsHeader,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_agreed && !_busy) ? _accept : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandTeal,
                          foregroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.surface,
                                ),
                              )
                            : Text(
                                l10n.legalReconsentAccept,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _signOut,
                      child: Text(
                        l10n.legalReconsentSignOut,
                        style: const TextStyle(
                          color: AppColors.shareSecondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.permissionsHeader,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.shareSecondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
