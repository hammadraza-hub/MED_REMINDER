import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'member_repository.dart';

/// ============================================================
/// LOCAL MEMBER REPOSITORY
///
/// Current persistence implementation:
/// Drift + SQLite.
///
/// UI/controllers [MemberRepository] contract use karte hain,
/// isliye future mein is implementation ko Firebase/Firestore
/// repository se replace kiya ja sakta hai without rewriting UI.
///
/// TODO Backend:
/// Future FirebaseMemberRepository isi MemberRepository contract
/// ko implement karega aur Firestore member document IDs ko
/// stable member IDs ke taur par use karega.
/// ============================================================
class LocalMemberRepository implements MemberRepository {
  LocalMemberRepository({AppDatabase? database})
    : _database = database ?? DatabaseProvider.instance;

  final AppDatabase _database;

  @override
  Stream<List<MemberProfile>> watchActiveMembers() {
    final query = _database.select(_database.members)
      ..where((table) => table.isActive.equals(true))
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);

    return query.watch().map((rows) => rows.map(_mapMember).toList());
  }

  @override
  Future<List<MemberProfile>> getActiveMembers() async {
    final query = _database.select(_database.members)
      ..where((table) => table.isActive.equals(true))
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);

    final rows = await query.get();

    return rows.map(_mapMember).toList();
  }

  @override
  Future<MemberProfile?> getMemberById(String memberId) async {
    final query = _database.select(_database.members)
      ..where((table) => table.id.equals(memberId));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _mapMember(row);
  }

  @override
  Future<void> saveMember(MemberProfile member) async {
    await _database
        .into(_database.members)
        .insertOnConflictUpdate(
          MembersCompanion(
            id: Value(member.id),
            accountId: Value(member.accountId),
            displayName: Value(member.displayName),
            relationship: Value(member.relationship),
            profileImagePath: Value(member.profileImagePath),
            isActive: Value(member.isActive),
            createdAt: Value(member.createdAt),
            updatedAt: Value(member.updatedAt),
          ),
        );
  }

  @override
  Future<void> setMemberActive({
    required String memberId,
    required bool isActive,
  }) async {
    await (_database.update(
      _database.members,
    )..where((table) => table.id.equals(memberId))).write(
      MembersCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> seedInitialMembersIfNeeded() async {
    // Each stable seed ID is checked independently.
    //
    // Isse agar Sarah pehle se DB mein ho lekin Mom/Jake missing
    // hon, to missing members phir bhi create ho jayenge.
    await _seedMemberIfMissing(
      id: 'local_sarah',
      displayName: 'Sarah',
      relationship: 'Self',
    );

    await _seedMemberIfMissing(
      id: 'local_mom',
      displayName: 'Mom',
      relationship: 'Family',
    );

    await _seedMemberIfMissing(
      id: 'local_jake',
      displayName: 'Jake',
      relationship: 'Family',
    );
  }

  Future<void> _seedMemberIfMissing({
    required String id,
    required String displayName,
    required String relationship,
  }) async {
    final existingMember = await getMemberById(id);

    if (existingMember != null) {
      return;
    }

    final now = DateTime.now();

    await saveMember(
      MemberProfile(
        id: id,
        displayName: displayName,
        relationship: relationship,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  MemberProfile _mapMember(Member row) {
    return MemberProfile(
      id: row.id,
      accountId: row.accountId,
      displayName: row.displayName,
      relationship: row.relationship,
      profileImagePath: row.profileImagePath,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
