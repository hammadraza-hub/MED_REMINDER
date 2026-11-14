import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_value_converter.dart';

/// One raw document read from the data source (values already plain types).
class RawDoc {
  const RawDoc({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
}

/// Result of reading a collection. [truncated] is true when the cap was hit.
class ReadResult {
  const ReadResult(this.docs, {this.truncated = false});
  final List<RawDoc> docs;
  final bool truncated;
}

/// Where the export reads from. Abstract so tests can use a fake.
abstract class ExportDataSource {
  /// The `users/{uid}` document data (empty map if missing).
  Future<Map<String, dynamic>> getUser(String uid);

  /// Profiles whose `ownerUid` is [uid].
  Future<List<RawDoc>> listOwnedProfiles(String uid);

  /// All documents of the collection at [path] (e.g. `profiles/p1/doses`),
  /// at most [maxDocs].
  Future<ReadResult> readCollection(String path, {int maxDocs});
}

class FirestoreExportSource implements ExportDataSource {
  FirestoreExportSource({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const int pageSize = 500;

  @override
  Future<Map<String, dynamic>> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return FirestoreValueConverter.convertMap(snap.data() ?? const {});
  }

  @override
  Future<List<RawDoc>> listOwnedProfiles(String uid) async {
    // Rules only allow queries proven readable, so query by membership and
    // keep the profiles this user owns.
    final snap = await _db
        .collection('profiles')
        .where('memberUids', arrayContains: uid)
        .get();
    return [
      for (final d in snap.docs)
        if (d.data()['ownerUid'] == uid)
          RawDoc(id: d.id, data: FirestoreValueConverter.convertMap(d.data())),
    ];
  }

  @override
  Future<ReadResult> readCollection(String path, {int maxDocs = 20000}) async {
    final out = <RawDoc>[];
    DocumentSnapshot? last;
    while (true) {
      final remaining = maxDocs - out.length;
      if (remaining <= 0) return ReadResult(out, truncated: true);
      final limit = remaining < pageSize ? remaining : pageSize;
      var q = _db.collection(path).orderBy(FieldPath.documentId).limit(limit);
      if (last != null) q = q.startAfterDocument(last);
      final snap = await q.get();
      for (final d in snap.docs) {
        out.add(
          RawDoc(id: d.id, data: FirestoreValueConverter.convertMap(d.data())),
        );
      }
      if (snap.docs.length < limit) return ReadResult(out);
      last = snap.docs.last;
    }
  }
}
