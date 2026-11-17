import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Community data model. M19 step 1.
///
/// Identity: every user has ONE random [CommunityIds.newProfileId] stored in
/// their own private `users/{uid}.communityProfileId`. Posts, comments, votes,
/// reports and blocks carry only that id, never the uid, so nothing public
/// ties a post to an account or to health data.

/// Limits; they are the same numbers as in `firestore.rules`.
class CommunityLimits {
  CommunityLimits._();

  static const int pseudonymMin = 3;
  static const int pseudonymMax = 24;
  static const int avatarMax = 40;
  static const int bioMax = 160;
  static const int postBodyMax = 2000;
  static const int commentBodyMax = 800;
  static const int idLength = 20;

  /// Posts read per page in a feed.
  static const int feedPageSize = 20;
}

/// The random community id.
class CommunityIds {
  CommunityIds._();

  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// 20 random letters / digits from a secure generator.
  static String newProfileId([Random? random]) {
    final r = random ?? Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < CommunityLimits.idLength; i++)
        _alphabet.codeUnitAt(r.nextInt(_alphabet.length)),
    ]);
  }

  static final RegExp _shape = RegExp(r'^[A-Za-z0-9]{20}$');

  static bool isValid(String? id) => id != null && _shape.hasMatch(id);
}

enum CommunityReportReason {
  spam,
  abuse,
  medical,
  other;

  static CommunityReportReason? byName(String? name) {
    for (final r in values) {
      if (r.name == name) return r;
    }
    return null;
  }
}

enum CommunityReportTarget { post, comment }

DateTime _date(Object? raw, {DateTime? fallback}) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return fallback ?? DateTime.now();
}

DateTime? _dateOrNull(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return null;
}

/// communityProfiles/{id}
class CommunityProfile {
  const CommunityProfile({
    required this.id,
    required this.pseudonym,
    required this.avatar,
    required this.bio,
    required this.createdAt,
  });

  final String id;
  final String pseudonym;

  /// A preset avatar key (no uploaded image).
  final String avatar;
  final String bio;
  final DateTime createdAt;

  factory CommunityProfile.fromMap(String id, Map<String, dynamic> map) {
    return CommunityProfile(
      id: id,
      pseudonym: (map['pseudonym'] as String?) ?? '',
      avatar: (map['avatar'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      createdAt: _date(map['createdAt']),
    );
  }

  /// Fields to write on create (server time is added by the repository).
  static Map<String, dynamic> createMap({
    required String pseudonym,
    required String avatar,
    required String bio,
  }) => {
    'pseudonym': pseudonym,
    'avatar': avatar,
    'bio': bio,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// groups/{id}  (created from a PC with the Admin SDK)
class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
  });

  final String id;
  final String name;
  final String description;
  final int order;

  factory CommunityGroup.fromMap(String id, Map<String, dynamic> map) {
    return CommunityGroup(
      id: id,
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// groups/{groupId}/posts/{id}
class CommunityFeedPost {
  const CommunityFeedPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.editedAt,
    required this.voteCount,
    required this.hidden,
  });

  final String id;
  final String groupId;
  final String authorId;
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int voteCount;
  final bool hidden;

  bool get isEdited => editedAt != null;

  factory CommunityFeedPost.fromMap(
    String groupId,
    String id,
    Map<String, dynamic> map,
  ) {
    return CommunityFeedPost(
      id: id,
      groupId: groupId,
      authorId: (map['authorId'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      createdAt: _date(map['createdAt']),
      editedAt: _dateOrNull(map['editedAt']),
      voteCount: (map['voteCount'] as num?)?.toInt() ?? 0,
      hidden: map['hidden'] == true,
    );
  }

  static Map<String, dynamic> createMap({
    required String authorId,
    required String body,
  }) => {
    'authorId': authorId,
    'body': body,
    'createdAt': FieldValue.serverTimestamp(),
    'editedAt': null,
    'voteCount': 0,
    'hidden': false,
  };
}

/// groups/{groupId}/posts/{postId}/comments/{id}
class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.editedAt,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;

  factory CommunityComment.fromMap(String id, Map<String, dynamic> map) {
    return CommunityComment(
      id: id,
      authorId: (map['authorId'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      createdAt: _date(map['createdAt']),
      editedAt: _dateOrNull(map['editedAt']),
    );
  }

  static Map<String, dynamic> createMap({
    required String authorId,
    required String body,
  }) => {
    'authorId': authorId,
    'body': body,
    'createdAt': FieldValue.serverTimestamp(),
    'editedAt': null,
  };
}

/// reports/{id}
class CommunityReport {
  const CommunityReport({
    required this.id,
    required this.reporterId,
    required this.target,
    required this.groupId,
    required this.postId,
    this.commentId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final CommunityReportTarget target;
  final String groupId;
  final String postId;
  final String? commentId;
  final CommunityReportReason reason;
  final DateTime createdAt;

  factory CommunityReport.fromMap(String id, Map<String, dynamic> map) {
    return CommunityReport(
      id: id,
      reporterId: (map['reporterId'] as String?) ?? '',
      target: map['targetType'] == 'comment'
          ? CommunityReportTarget.comment
          : CommunityReportTarget.post,
      groupId: (map['groupId'] as String?) ?? '',
      postId: (map['postId'] as String?) ?? '',
      commentId: map['commentId'] as String?,
      reason:
          CommunityReportReason.byName(map['reason'] as String?) ??
          CommunityReportReason.other,
      createdAt: _date(map['createdAt']),
    );
  }

  static Map<String, dynamic> createMap({
    required String reporterId,
    required CommunityReportTarget target,
    required String groupId,
    required String postId,
    String? commentId,
    required CommunityReportReason reason,
  }) => {
    'reporterId': reporterId,
    'targetType': target.name,
    'groupId': groupId,
    'postId': postId,
    'commentId': ?commentId,
    'reason': reason.name,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
