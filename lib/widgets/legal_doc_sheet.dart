import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../l10n/app_localizations.dart';

/// ============================================================
/// LEGAL DOCUMENT BOTTOM SHEET
///
/// Shared by About, Sign Up and the legal re-consent screen.
/// `id` is one of `terms`, `privacy`, `licenses`.
/// ============================================================
class LegalDocSheet extends StatelessWidget {

  const LegalDocSheet({super.key, required this.id});

  /// Opens the sheet for `terms`, `privacy` or `licenses`.
  static Future<void> show(BuildContext context, String id) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => LegalDocSheet(id: id),
    );
  }



  final String id;



  @override

  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context);



    final title = switch (id) {

      'terms' => l10n.aboutTerms,

      'privacy' => l10n.aboutPrivacy,

      _ => l10n.aboutLicenses,

    };



    return SafeArea(

      top: false,

      child: Align(

        alignment: Alignment.bottomCenter,

        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 420),

          child: Container(

            decoration: const BoxDecoration(

              color: AppColors.surface,

              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),

            ),

            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                Center(

                  child: Container(

                    width: 48,

                    height: 4,

                    decoration: BoxDecoration(

                      color: AppColors.reportChipHigh,

                      borderRadius: BorderRadius.circular(999),

                    ),

                  ),

                ),

                const SizedBox(height: 14),

                Row(

                  children: [

                    Expanded(

                      child: Text(

                        title,

                        style: const TextStyle(

                          color: AppColors.permissionsHeader,

                          fontSize: 18,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                    ),

                    GestureDetector(

                      onTap: () => Navigator.of(context).pop(),

                      child: Container(

                        width: 36,

                        height: 36,

                        decoration: const BoxDecoration(

                          color: AppColors.permissionsChipFill,

                          shape: BoxShape.circle,

                        ),

                        child: const Icon(

                          Icons.close_rounded,

                          size: 20,

                          color: AppColors.permissionsSecondary,

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 14),

                Flexible(

                  child: SingleChildScrollView(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [

                        Text(

                          l10n.aboutLegalBody1,

                          style: const TextStyle(

                            color: AppColors.assistantNoteText,

                            fontSize: 13,

                            height: 1.45,

                          ),

                        ),

                        const SizedBox(height: 14),

                        Text(

                          l10n.aboutLegalBody2,

                          style: const TextStyle(

                            color: AppColors.assistantNoteText,

                            fontSize: 13,

                            height: 1.45,

                          ),

                        ),

                        const SizedBox(height: 14),

                        Container(

                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(

                            color: AppColors.permissionsChipFill,

                            borderRadius: BorderRadius.circular(12),

                          ),

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                l10n.aboutLegalComplianceTitle,

                                style: const TextStyle(

                                  color: AppColors.permissionsHeader,

                                  fontSize: 13,

                                  fontWeight: FontWeight.w600,

                                ),

                              ),

                              const SizedBox(height: 4),

                              Text(

                                l10n.aboutLegalComplianceValue,

                                style: const TextStyle(

                                  color: AppColors.permissionsSecondary,

                                  fontSize: 12,

                                ),

                              ),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ),

                ),

                const SizedBox(height: 16),

                GestureDetector(

                  onTap: () => Navigator.of(context).pop(),

                  child: Container(

                    height: 52,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(

                      color: AppColors.formAccent,

                      borderRadius: BorderRadius.circular(12),

                    ),

                    child: Text(

                      l10n.aboutDone,

                      style: const TextStyle(

                        color: AppColors.surface,

                        fontSize: 15,

                        fontWeight: FontWeight.w700,

                      ),

                    ),

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}
