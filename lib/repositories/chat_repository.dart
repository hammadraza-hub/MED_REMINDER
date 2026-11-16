import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/ai/chat_controller.dart';
import '../core/ai/chat_models.dart';
import '../core/ai/chat_title.dart';
import '../core/app_exception.dart';

/// ============================================================
/// CHAT REPOSITORY — M18 step 4
///
/// Path: users/{uid}/chatThreads/{threadId}            profileId, title,
///                                                      createdAt, updatedAt
///       users/{uid}/chatThreads/{threadId}/messages/{id}  role, text, createdAt
///
/// Everything under the user's own document, so the security rules, the
/// account purge and the data export need no special cases. Writing a thread
/// needs the user's AI consent (checked by the rules). Messages are never
/// edited. All methods throw [AppException].
/// ============================================================
class ChatRepository implements ChatStore {
  static final ChatRepository instance = ChatRepository._();
  ChatRepository._() : _dbOverride = null, _uidOverride = null;

  /// For tests.
  ChatRepository.withDb(FirebaseFirestore db, {String? Function()? uid})
    : _dbOverride = db,
      _uidOverride = uid;

  final FirebaseFirestore? _dbOverride;
  final String? Function()? _uidOverride;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  String _uid() {
    final override = _uidOverride;
    final uid = override != null
        ? override()
        : FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw AppException.permission('Not signed in');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _threads(String uid) =>
      _db.collection('users').doc(uid).collection('chatThreads');

  /// Starts a thread titled from [firstQuestion]; returns its id.
  @override
  Future<String> createThread({
    required String profileId,
    required String firstQuestion,
  }) async {
    final uid = _uid();
    if (profileId.isEmpty) {
      throw AppException.validation('No profile selected');
    }
    try {
      final ref = _threads(uid).doc();
      await ref.set({
        'profileId': profileId,
        'title': ChatTitle.fromQuestion(firstQuestion),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Adds a message and moves the thread to the top of the history, in one
  /// batch. Text longer than the limit is cut.
  @override
  Future<void> addMessage({
    required String threadId,
    required ChatRole role,
    required String text,
  }) async {
    final uid = _uid();
    var body = text.trim();
    if (body.isEmpty) {
      throw AppException.validation('Message is empty');
    }
    if (body.length > ChatLimits.maxTextLength) {
      body = body.substring(0, ChatLimits.maxTextLength);
    }

    try {
      final threadRef = _threads(uid).doc(threadId);
      final batch = _db.batch();
      batch.set(threadRef.collection('messages').doc(), {
        'role': role.name,
        'text': body,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(threadRef, {'updatedAt': FieldValue.serverTimestamp()});
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// The threads of one profile, newest activity first (at most
  /// [ChatLimits.maxThreads]).
  @override
  Future<List<ChatThread>> listThreads(String profileId) async {
    final uid = _uid();
    try {
      final snap = await _threads(uid)
          .where('profileId', isEqualTo: profileId)
          .orderBy('updatedAt', descending: true)
          .limit(ChatLimits.maxThreads)
          .get();
      return [for (final d in snap.docs) ChatThread.fromMap(d.id, d.data())];
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// The messages of a thread, oldest first (at most
  /// [ChatLimits.maxMessagesPerThread]).
  @override
  Future<List<ChatMessage>> loadMessages(String threadId) async {
    final uid = _uid();
    try {
      final snap = await _threads(uid)
          .doc(threadId)
          .collection('messages')
          .orderBy('createdAt')
          .limit(ChatLimits.maxMessagesPerThread)
          .get();
      return [for (final d in snap.docs) ChatMessage.fromMap(d.id, d.data())];
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }

  /// Deletes a thread with all its messages (messages first, in pages).
  @override
  Future<void> deleteThread(String threadId) async {
    final uid = _uid();
    try {
      final threadRef = _threads(uid).doc(threadId);
      while (true) {
        final page = await threadRef.collection('messages').limit(100).get();
        if (page.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in page.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
      await threadRef.delete();
    } on FirebaseException catch (e) {
      throw AppException.fromFirebaseException(e);
    }
  }
}
