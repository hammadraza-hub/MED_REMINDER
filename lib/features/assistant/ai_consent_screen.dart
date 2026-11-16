import 'package:flutter/material.dart';

import '../../core/ai/ai_consent.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ai_consent_service.dart';
import '../../l10n/app_localizations.dart';

/// Asks the user to allow the AI assistant (M18 step 1).
///
/// Pops `true` when the user agrees (consent is saved first), `false`/null
/// otherwise.
class AiConsentScreen extends StatefulWidget {
  const AiConsentScreen({super.key, this.controller});

  /// For tests: a controller with a fake store.
  @visibleForTesting
  final AiConsentController? controller;

  @override
  State<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends State<AiConsentScreen> {
  bool _saving = false;

  AiConsentController get _consent =>
      widget.controller ?? AiConsentService.instance;

  Future<void> _agree() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await _consent.grant();
      if (mounted) navigator.pop(true);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.aiConsentSaveFailed)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.permissionsHeader,
        foregroundColor: AppColors.surface,
        title: Text(
          l10n.aiSettingTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiConsentTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.permissionsHeader,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _body(l10n.aiConsentIntro),
                        const SizedBox(height: 18),
                        _block(
                          icon: Icons.share_outlined,
                          color: AppColors.permissionsGreen,
                          title: l10n.aiConsentSentTitle,
                          body: l10n.aiConsentSentBody,
                        ),
                        const SizedBox(height: 12),
                        _block(
                          icon: Icons.shield_outlined,
                          color: AppColors.permissionsHeader,
                          title: l10n.aiConsentNeverTitle,
                          body: l10n.aiConsentNeverBody,
                        ),
                        const SizedBox(height: 18),
                        _body(l10n.aiConsentFdaNote),
                        const SizedBox(height: 12),
                        _body(l10n.aiConsentLimits),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        key: const Key('ai-consent-agree'),
                        onPressed: _saving ? null : _agree,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.permissionsGreen,
                          foregroundColor: AppColors.surface,
                          minimumSize: const Size.fromHeight(52),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                            : Text(
                                l10n.aiConsentAgree,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const Key('ai-consent-not-now'),
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.aiConsentNotNow),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      height: 1.4,
      color: AppColors.permissionsSecondary,
    ),
  );

  Widget _block({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.permissionsHeader,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.permissionsSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
