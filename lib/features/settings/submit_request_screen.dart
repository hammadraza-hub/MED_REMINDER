import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/app_info_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/support_ticket.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/support_repository.dart';

/// Short description of this device for support (platform + OS version).
String describeDevice() {
  if (kIsWeb) return 'web';
  return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
}

/// ============================================================
/// SUBMIT REQUEST SCREEN (M13 step 5)
///
/// Subject + details form that writes `supportTickets/{id}` with the
/// app version, device and language attached. Spark plan: the ticket is
/// stored only; support reads it in the Firebase console (emailing the
/// inbox needs a Cloud Function — Blaze).
///
/// Offline: if the server does not answer in time the request stays in
/// Firestore's queue and is sent automatically later; the user is told so
/// and must not send it again.
/// ============================================================
class SubmitRequestScreen extends StatefulWidget {
  const SubmitRequestScreen({super.key});

  @override
  State<SubmitRequestScreen> createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();

  TicketValidation _error = TicketValidation.ok;
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);

    final v = SupportTicket.validate(_subject.text, _body.text);
    setState(() => _error = v);
    if (v != TicketValidation.ok) return;

    final uid = AuthRepository.instance.currentUid;
    if (uid == null || uid.isEmpty) {
      _toast(l10n.supportRequestSignIn);
      return;
    }

    setState(() => _busy = true);
    final info = AppInfoService.instance;
    final ticket = SupportTicket.fromForm(
      uid: uid,
      subject: _subject.text,
      body: _body.text,
      appVersion: '${info.version}+${info.buildNumber}',
      device: describeDevice(),
      locale: Localizations.localeOf(context).languageCode,
    );

    try {
      final result = await SupportRepository.instance.submit(ticket);
      if (!mounted) return;
      _toast(
        result == TicketSendResult.sent
            ? l10n.supportRequestSent
            : l10n.supportRequestQueued,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(l10n.supportRequestError);
    }
  }

  String? _subjectError(AppLocalizations l10n) =>
      (_error == TicketValidation.subjectEmpty ||
              _error == TicketValidation.subjectTooLong)
          ? l10n.supportRequestSubjectRequired
          : null;

  String? _bodyError(AppLocalizations l10n) =>
      (_error == TicketValidation.bodyEmpty ||
              _error == TicketValidation.bodyTooLong)
          ? l10n.supportRequestBodyRequired
          : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: AppColors.surface,
        title: Text(
          l10n.supportRequestTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.supportRequestIntro,
                    style: const TextStyle(
                      color: AppColors.shareSecondaryText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _subject,
                    enabled: !_busy,
                    maxLength: SupportTicket.maxSubject,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.supportRequestSubjectLabel,
                      hintText: l10n.supportRequestSubjectHint,
                      errorText: _subjectError(l10n),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (_error != TicketValidation.ok) {
                        setState(() => _error = TicketValidation.ok);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    enabled: !_busy,
                    maxLength: SupportTicket.maxBody,
                    minLines: 6,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: l10n.supportRequestBodyLabel,
                      hintText: l10n.supportRequestBodyHint,
                      alignLabelWithHint: true,
                      errorText: _bodyError(l10n),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (_error != TicketValidation.ok) {
                        setState(() => _error = TicketValidation.ok);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _send,
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
                              l10n.supportRequestSend,
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
    );
  }
}
