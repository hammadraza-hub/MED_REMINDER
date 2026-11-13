import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/remote_config_service.dart';
import '../../core/app_gate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_info_service.dart';
import '../../l10n/app_localizations.dart';
import 'splash_screen.dart';

/// ============================================================
/// APP BLOCKED SCREEN (M13)
///
/// Full-screen, non-dismissible screen shown from the splash when
/// Remote Config says the app must not be used:
///   - [AppGateStatus.updateRequired] -> installed version is older
///     than `min_app_version`; button opens the store listing.
///   - [AppGateStatus.maintenance]    -> `maintenance_mode` is on;
///     "Try again" re-fetches config and returns to the splash if
///     the gate is open again.
///
/// Reminders already scheduled on the device keep ringing — this
/// screen only blocks the UI.
/// ============================================================
class AppBlockedScreen extends StatefulWidget {
  const AppBlockedScreen({super.key, required this.status})
      : assert(status != AppGateStatus.ok);

  final AppGateStatus status;

  @override
  State<AppBlockedScreen> createState() => _AppBlockedScreenState();
}

class _AppBlockedScreenState extends State<AppBlockedScreen> {
  bool _busy = false;

  bool get _isUpdate => widget.status == AppGateStatus.updateRequired;

  Uri _storeUri() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // No App Store id yet — generic listing search fallback.
      return Uri.parse('https://apps.apple.com/');
    }
    final pkg = AppInfoService.instance.packageName;
    return Uri.parse(
      pkg.isEmpty
          ? 'https://play.google.com/store'
          : 'https://play.google.com/store/apps/details?id=$pkg',
    );
  }

  Future<void> _openStore() async {
    try {
      await launchUrl(_storeUri(), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AppBlockedScreen: could not open store — $e');
    }
  }

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    await RemoteConfigService.instance.refresh();
    if (!mounted) return;
    if (RemoteConfigService.instance.gateStatus == AppGateStatus.ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else {
      setState(() => _busy = false);
    }
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isUpdate
                          ? Icons.system_update_rounded
                          : Icons.construction_rounded,
                      size: 72,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isUpdate
                          ? l10n.appBlockedUpdateTitle
                          : l10n.appBlockedMaintenanceTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.permissionsHeader,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isUpdate
                          ? l10n.appBlockedUpdateBody
                          : l10n.appBlockedMaintenanceBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.shareSecondaryText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isUpdate ? _openStore : _retry,
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
                                _isUpdate
                                    ? l10n.appBlockedUpdateButton
                                    : l10n.appBlockedRetryButton,
                                style: const TextStyle(
                                  fontSize: 16,
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
        ),
      ),
    );
  }
}
