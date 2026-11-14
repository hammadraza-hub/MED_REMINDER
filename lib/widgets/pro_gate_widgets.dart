import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/constants/app_colors.dart';
import '../core/services/pro_access.dart';
import '../features/settings/subscription_screen.dart';
import '../l10n/app_localizations.dart';

/// "This is a Solo Pro feature" dialog with a shortcut to the plans.
Future<void> showProRequiredDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.proGateTitle),
      content: Text(l10n.proGateBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          },
          child: Text(l10n.proGateSeePlans),
        ),
      ],
    ),
  );
}

/// Call before a write. Returns true when the user may go ahead; otherwise
/// the upgrade dialog has been shown.
Future<bool> ensureProForWrite(BuildContext context, String profileId) async {
  final ok = await ProAccess.gate.canWrite(profileId);
  if (ok || !context.mounted) return ok;
  await showProRequiredDialog(context);
  return false;
}

/// True when a failed write was refused by the server's Pro gate (rules), so
/// the screen should show the upgrade dialog instead of "could not save".
bool isProDenied(Object error) =>
    error is AppException && error.type == AppExceptionType.permission;

/// Small banner shown above the lists when the profile is read-only.
class ProReadOnlyBanner extends StatelessWidget {
  const ProReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => showProRequiredDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.upcomingBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.textTeal.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.textTeal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.proReadOnlyBanner,
                style: const TextStyle(
                  color: AppColors.textTeal,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
