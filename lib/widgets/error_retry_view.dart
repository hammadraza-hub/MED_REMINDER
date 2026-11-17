import 'package:flutter/material.dart';

import '../core/app_error_text.dart';
import '../core/constants/app_colors.dart';
import '../l10n/app_localizations.dart';

/// A calm error message with "Try again" (only when trying again can help).
/// M20 step 4.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    this.error,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.retryKey,
    this.onSignInAgain,
    this.signInAgainLabel,
  });

  /// What went wrong. Null when the caller only has a [message] (a controller
  /// that kept just a "failed" flag): the message is shown and Try again is
  /// always offered.
  final Object? error;

  /// Text to show instead of the one derived from [error].
  final String? message;

  /// Button text (default: "Try again").
  final String? retryLabel;

  /// Null: no button.
  final VoidCallback? onRetry;
  final Key? retryKey;

  /// Shown instead of "Try again" when the session ran out.
  /// (Real routing back to sign-in is M20 step 7.)
  final VoidCallback? onSignInAgain;
  final String? signInAgainLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final err = error;
    final session = err != null && AppErrorText.isSessionProblem(err);
    final showRetry =
        onRetry != null && (err == null || AppErrorText.canRetry(err));
    final showSignIn = session && onSignInAgain != null;
    // Scrolls when there is not enough room (large text, small boxes) instead
    // of overflowing; centred when there is.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.maxHeight.isFinite ? box.maxHeight : 0,
            minWidth: box.maxWidth.isFinite ? box.maxWidth : 0,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    session ? Icons.lock_outline : Icons.cloud_off_outlined,
                    size: 40,
                    color: AppColors.permissionsSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message ?? AppErrorText.of(l10n, err ?? 'unknown'),
                    key: const Key('error-text'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.permissionsSecondary,
                      fontSize: 15,
                    ),
                  ),
                  if (showRetry)
                    TextButton(
                      key: retryKey ?? const Key('error-retry'),
                      onPressed: onRetry,
                      child: Text(retryLabel ?? l10n.appErrorRetry),
                    ),
                  if (showSignIn)
                    TextButton(
                      key: const Key('error-sign-in'),
                      onPressed: onSignInAgain,
                      child: Text(signInAgainLabel ?? l10n.appErrorRetry),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
