import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Turns Firestore-specific values into plain Dart types so ExportBuilder can
/// serialise them (M14 step 2).
///
/// Timestamp -> UTC DateTime, GeoPoint -> {latitude, longitude},
/// DocumentReference -> its path, Blob -> base64 string, collections are
/// converted recursively. Anything else is returned unchanged.
class FirestoreValueConverter {
  FirestoreValueConverter._();

  static Map<String, dynamic> convertMap(Map<String, dynamic> data) => {
    for (final e in data.entries) e.key: convert(e.value),
  };

  static Object? convert(Object? v) {
    if (v is Timestamp) return v.toDate().toUtc();
    if (v is GeoPoint) {
      return {'latitude': v.latitude, 'longitude': v.longitude};
    }
    if (v is DocumentReference) return v.path;
    if (v is Blob) return base64Encode(v.bytes);
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): convert(e.value)};
    }
    if (v is Iterable) return [for (final e in v) convert(e)];
    return v;
  }
}
