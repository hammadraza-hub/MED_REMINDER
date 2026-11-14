import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../models/support_ticket.dart';

/// How a submitted ticket ended up.
enum TicketSendResult {
  /// The server confirmed the write.
  sent,

  /// No server answer in time (offline / slow). Firestore keeps the write
  /// queued and sends it automatically when the connection is back, so the
  /// user must NOT submit it again.
  queued,
}

/// Writes support requests to `supportTickets` (M13 step 5).
///
/// Spark plan: the ticket is only stored. Emailing the support inbox needs a
/// Cloud Function / Trigger Email extension (Blaze) — until then support
/// reads tickets in the Firebase console.
class SupportRepository {
  SupportRepository._();
  static final SupportRepository instance = SupportRepository._();

  static const Duration _confirmTimeout = Duration(seconds: 8);

  /// Saves [ticket]. Throws [AppException] if the server rejects it
  /// (permission / validation); returns [TicketSendResult.queued] if there is
  /// simply no answer in time.
  Future<TicketSendResult> submit(SupportTicket ticket) async {
    final write = FirebaseFirestore.instance.collection('supportTickets').add({
      ...ticket.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await write.timeout(_confirmTimeout);
      return TicketSendResult.sent;
    } on TimeoutException {
      // The write stays pending in the Firestore queue. Swallow its eventual
      // outcome so an error later does not surface as an unhandled one.
      unawaited(write.then<void>((_) {}, onError: (Object _) {}));
      return TicketSendResult.queued;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
