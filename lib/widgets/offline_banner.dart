import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/connectivity_service.dart';
import '../l10n/app_localizations.dart';

/// Puts a thin "Offline" bar above the whole app while the phone has no
/// connection, and a short "Back online" bar when it returns. The screens
/// below are not blocked: they keep working (Firestore saves offline and
/// sends later). M20 step 2.
///
/// Place it once, in `MaterialApp.builder`. The widget tree around [child]
/// never changes shape, so the navigator below keeps its pages when the bar
/// appears or goes away.
class OfflineBannerHost extends StatefulWidget {
  const OfflineBannerHost({
    super.key,
    required this.child,
    this.service,
    this.backOnlineFor = const Duration(seconds: 2),
  });

  final Widget child;

  /// For tests: a service with a fake connection source.
  final ConnectivityService? service;

  /// How long "Back online" stays.
  final Duration backOnlineFor;

  @override
  State<OfflineBannerHost> createState() => _OfflineBannerHostState();
}

class _OfflineBannerHostState extends State<OfflineBannerHost> {
  late ConnectivityService _service;
  ConnectionStatus _last = ConnectionStatus.unknown;
  bool _backOnline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ConnectivityService.instance;
    _last = _service.status.value;
    _service.status.addListener(_changed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _service.status.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final now = _service.status.value;
    final wasOffline = _last == ConnectionStatus.offline;
    _last = now;
    if (!mounted) return;
    _timer?.cancel();
    if (wasOffline && now == ConnectionStatus.online) {
      setState(() => _backOnline = true);
      _timer = Timer(widget.backOnlineFor, () {
        if (mounted) setState(() => _backOnline = false);
      });
    } else {
      setState(() => _backOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offline = _service.status.value == ConnectionStatus.offline;
    final visible = offline || _backOnline;

    final Widget bar = !visible
        ? const SizedBox.shrink()
        : Material(
            // Colour the status bar area too, so the bar looks like one piece.
            color: offline ? const Color(0xFFFFF3CD) : const Color(0xFFD7F0E3),
            child: SafeArea(
              bottom: false,
              child: _Bar(
                key: Key(offline ? 'offline-banner' : 'back-online-banner'),
                icon: offline
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_rounded,
                text: offline ? l10n.offlineBannerText : l10n.offlineBackOnline,
                background: offline
                    ? const Color(0xFFFFF3CD)
                    : const Color(0xFFD7F0E3),
                foreground: offline
                    ? const Color(0xFF6B4E00)
                    : const Color(0xFF0B5B3A),
              ),
            ),
          );

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: SizedBox(width: double.infinity, child: bar),
        ),
        Expanded(
          // The bar already sits under the status bar, so the screens below
          // must not add the status bar space a second time.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: visible,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
