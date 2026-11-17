/// ============================================================
/// RECEIVED INVITES SCREEN — M11 Caregiver & Family Sharing
/// ============================================================
///
/// Screen jo current user ke received invitations dikhata ha.
/// Spark-compatible: client-side Firestore queries only.
/// ============================================================

library;

import 'package:flutter/material.dart';

import '../../core/app_error_text.dart';
import '../../core/app_exception.dart';
import '../../core/caregiver/caregiver_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/error_retry_view.dart';
import '../../widgets/skeleton.dart';
import '../../core/caregiver/firebase_caregiver_repository.dart';
import '../../repositories/auth_repository.dart';

/// Received Invites Screen — current user ke pending invites.
class ReceivedInvitesScreen extends StatefulWidget {
  const ReceivedInvitesScreen({super.key});

  @override
  State<ReceivedInvitesScreen> createState() => _ReceivedInvitesScreenState();
}

class _ReceivedInvitesScreenState extends State<ReceivedInvitesScreen> {
  final FirebaseCaregiverRepository _repo =
      FirebaseCaregiverRepository.instance;

  late Stream<List<CaregiverInvite>> _invitesStream;

  @override
  void initState() {
    super.initState();
    _openStream();
  }

  void _openStream() {
    final email = AuthRepository.instance.currentEmail;
    if (email != null) {
      _invitesStream = _repo.watchReceivedInvites(userEmail: email);
    } else {
      _invitesStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Received Invites')),
      body: StreamBuilder<List<CaregiverInvite>>(
        stream: _invitesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: SkeletonList(count: 3),
            );
          }

          if (snapshot.hasError) {
            return ErrorRetryView(
              error: AppException.fromAny(snapshot.error!),
              retryKey: const Key('invites-retry'),
              onRetry: () => setState(_openStream),
            );
          }

          final invites = snapshot.data ?? [];

          if (invites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending invites',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'When someone invites you, it will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    'From: ${invite.ownerUid}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${invite.role.name}'),
                      Text('Email: ${invite.inviteeEmail}'),
                      Text('Status: ${invite.status.name}'),
                      if (invite.expiresAt != null)
                        Text('Expires: ${invite.expiresAt}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptInvite(invite.id),
                        tooltip: 'Accept',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _declineInvite(invite.id),
                        tooltip: 'Decline',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _acceptInvite(String inviteId) async {
    try {
      await FirebaseCaregiverRepository.instance.acceptInvite(
        inviteId: inviteId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite accepted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorText.of(AppLocalizations.of(context), e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineInvite(String inviteId) async {
    try {
      await FirebaseCaregiverRepository.instance.declineInvite(
        inviteId: inviteId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite declined'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorText.of(AppLocalizations.of(context), e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
