// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileImagePathMeta = const VerificationMeta(
    'profileImagePath',
  );
  @override
  late final GeneratedColumn<String> profileImagePath = GeneratedColumn<String>(
    'profile_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    displayName,
    relationship,
    profileImagePath,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<Member> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    }
    if (data.containsKey('profile_image_path')) {
      context.handle(
        _profileImagePathMeta,
        profileImagePath.isAcceptableOrUnknown(
          data['profile_image_path']!,
          _profileImagePathMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      ),
      profileImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_image_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final String id;
  final String? accountId;
  final String displayName;
  final String? relationship;
  final String? profileImagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Member({
    required this.id,
    this.accountId,
    required this.displayName,
    this.relationship,
    this.profileImagePath,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || relationship != null) {
      map['relationship'] = Variable<String>(relationship);
    }
    if (!nullToAbsent || profileImagePath != null) {
      map['profile_image_path'] = Variable<String>(profileImagePath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      displayName: Value(displayName),
      relationship: relationship == null && nullToAbsent
          ? const Value.absent()
          : Value(relationship),
      profileImagePath: profileImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(profileImagePath),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Member.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      relationship: serializer.fromJson<String?>(json['relationship']),
      profileImagePath: serializer.fromJson<String?>(json['profileImagePath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String?>(accountId),
      'displayName': serializer.toJson<String>(displayName),
      'relationship': serializer.toJson<String?>(relationship),
      'profileImagePath': serializer.toJson<String?>(profileImagePath),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Member copyWith({
    String? id,
    Value<String?> accountId = const Value.absent(),
    String? displayName,
    Value<String?> relationship = const Value.absent(),
    Value<String?> profileImagePath = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Member(
    id: id ?? this.id,
    accountId: accountId.present ? accountId.value : this.accountId,
    displayName: displayName ?? this.displayName,
    relationship: relationship.present ? relationship.value : this.relationship,
    profileImagePath: profileImagePath.present
        ? profileImagePath.value
        : this.profileImagePath,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      profileImagePath: data.profileImagePath.present
          ? data.profileImagePath.value
          : this.profileImagePath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('displayName: $displayName, ')
          ..write('relationship: $relationship, ')
          ..write('profileImagePath: $profileImagePath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    displayName,
    relationship,
    profileImagePath,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.displayName == this.displayName &&
          other.relationship == this.relationship &&
          other.profileImagePath == this.profileImagePath &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<String> id;
  final Value<String?> accountId;
  final Value<String> displayName;
  final Value<String?> relationship;
  final Value<String?> profileImagePath;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.relationship = const Value.absent(),
    this.profileImagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    this.accountId = const Value.absent(),
    required String displayName,
    this.relationship = const Value.absent(),
    this.profileImagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Member> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? displayName,
    Expression<String>? relationship,
    Expression<String>? profileImagePath,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (displayName != null) 'display_name': displayName,
      if (relationship != null) 'relationship': relationship,
      if (profileImagePath != null) 'profile_image_path': profileImagePath,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String?>? accountId,
    Value<String>? displayName,
    Value<String?>? relationship,
    Value<String?>? profileImagePath,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (profileImagePath.present) {
      map['profile_image_path'] = Variable<String>(profileImagePath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('displayName: $displayName, ')
          ..write('relationship: $relationship, ')
          ..write('profileImagePath: $profileImagePath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  @override
  late final GeneratedColumn<String> strength = GeneratedColumn<String>(
    'strength',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthUnitMeta = const VerificationMeta(
    'strengthUnit',
  );
  @override
  late final GeneratedColumn<String> strengthUnit = GeneratedColumn<String>(
    'strength_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicineFormMeta = const VerificationMeta(
    'medicineForm',
  );
  @override
  late final GeneratedColumn<String> medicineForm = GeneratedColumn<String>(
    'medicine_form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorNameMeta = const VerificationMeta(
    'colorName',
  );
  @override
  late final GeneratedColumn<String> colorName = GeneratedColumn<String>(
    'color_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedPharmacyIdMeta = const VerificationMeta(
    'linkedPharmacyId',
  );
  @override
  late final GeneratedColumn<String> linkedPharmacyId = GeneratedColumn<String>(
    'linked_pharmacy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _discontinuedAtMeta = const VerificationMeta(
    'discontinuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> discontinuedAt =
      GeneratedColumn<DateTime>(
        'discontinued_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _discontinuedReasonMeta =
      const VerificationMeta('discontinuedReason');
  @override
  late final GeneratedColumn<String> discontinuedReason =
      GeneratedColumn<String>(
        'discontinued_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _courseDayMeta = const VerificationMeta(
    'courseDay',
  );
  @override
  late final GeneratedColumn<int> courseDay = GeneratedColumn<int>(
    'course_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseTotalDaysMeta = const VerificationMeta(
    'courseTotalDays',
  );
  @override
  late final GeneratedColumn<int> courseTotalDays = GeneratedColumn<int>(
    'course_total_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    strength,
    strengthUnit,
    medicineForm,
    colorName,
    instructions,
    imagePath,
    linkedPharmacyId,
    isActive,
    discontinuedAt,
    discontinuedReason,
    courseDay,
    courseTotalDays,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    } else if (isInserting) {
      context.missing(_strengthMeta);
    }
    if (data.containsKey('strength_unit')) {
      context.handle(
        _strengthUnitMeta,
        strengthUnit.isAcceptableOrUnknown(
          data['strength_unit']!,
          _strengthUnitMeta,
        ),
      );
    }
    if (data.containsKey('medicine_form')) {
      context.handle(
        _medicineFormMeta,
        medicineForm.isAcceptableOrUnknown(
          data['medicine_form']!,
          _medicineFormMeta,
        ),
      );
    }
    if (data.containsKey('color_name')) {
      context.handle(
        _colorNameMeta,
        colorName.isAcceptableOrUnknown(data['color_name']!, _colorNameMeta),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('linked_pharmacy_id')) {
      context.handle(
        _linkedPharmacyIdMeta,
        linkedPharmacyId.isAcceptableOrUnknown(
          data['linked_pharmacy_id']!,
          _linkedPharmacyIdMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('discontinued_at')) {
      context.handle(
        _discontinuedAtMeta,
        discontinuedAt.isAcceptableOrUnknown(
          data['discontinued_at']!,
          _discontinuedAtMeta,
        ),
      );
    }
    if (data.containsKey('discontinued_reason')) {
      context.handle(
        _discontinuedReasonMeta,
        discontinuedReason.isAcceptableOrUnknown(
          data['discontinued_reason']!,
          _discontinuedReasonMeta,
        ),
      );
    }
    if (data.containsKey('course_day')) {
      context.handle(
        _courseDayMeta,
        courseDay.isAcceptableOrUnknown(data['course_day']!, _courseDayMeta),
      );
    }
    if (data.containsKey('course_total_days')) {
      context.handle(
        _courseTotalDaysMeta,
        courseTotalDays.isAcceptableOrUnknown(
          data['course_total_days']!,
          _courseTotalDaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength'],
      )!,
      strengthUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength_unit'],
      ),
      medicineForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicine_form'],
      ),
      colorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_name'],
      ),
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      linkedPharmacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_pharmacy_id'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      discontinuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}discontinued_at'],
      ),
      discontinuedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discontinued_reason'],
      ),
      courseDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_day'],
      ),
      courseTotalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_total_days'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  final String id;
  final String memberId;
  final String name;
  final String strength;
  final String? strengthUnit;
  final String? medicineForm;
  final String? colorName;
  final String? instructions;
  final String? imagePath;
  final String? linkedPharmacyId;
  final bool isActive;
  final DateTime? discontinuedAt;
  final String? discontinuedReason;
  final int? courseDay;
  final int? courseTotalDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Medication({
    required this.id,
    required this.memberId,
    required this.name,
    required this.strength,
    this.strengthUnit,
    this.medicineForm,
    this.colorName,
    this.instructions,
    this.imagePath,
    this.linkedPharmacyId,
    required this.isActive,
    this.discontinuedAt,
    this.discontinuedReason,
    this.courseDay,
    this.courseTotalDays,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['name'] = Variable<String>(name);
    map['strength'] = Variable<String>(strength);
    if (!nullToAbsent || strengthUnit != null) {
      map['strength_unit'] = Variable<String>(strengthUnit);
    }
    if (!nullToAbsent || medicineForm != null) {
      map['medicine_form'] = Variable<String>(medicineForm);
    }
    if (!nullToAbsent || colorName != null) {
      map['color_name'] = Variable<String>(colorName);
    }
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || linkedPharmacyId != null) {
      map['linked_pharmacy_id'] = Variable<String>(linkedPharmacyId);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || discontinuedAt != null) {
      map['discontinued_at'] = Variable<DateTime>(discontinuedAt);
    }
    if (!nullToAbsent || discontinuedReason != null) {
      map['discontinued_reason'] = Variable<String>(discontinuedReason);
    }
    if (!nullToAbsent || courseDay != null) {
      map['course_day'] = Variable<int>(courseDay);
    }
    if (!nullToAbsent || courseTotalDays != null) {
      map['course_total_days'] = Variable<int>(courseTotalDays);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      strength: Value(strength),
      strengthUnit: strengthUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(strengthUnit),
      medicineForm: medicineForm == null && nullToAbsent
          ? const Value.absent()
          : Value(medicineForm),
      colorName: colorName == null && nullToAbsent
          ? const Value.absent()
          : Value(colorName),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      linkedPharmacyId: linkedPharmacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedPharmacyId),
      isActive: Value(isActive),
      discontinuedAt: discontinuedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(discontinuedAt),
      discontinuedReason: discontinuedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(discontinuedReason),
      courseDay: courseDay == null && nullToAbsent
          ? const Value.absent()
          : Value(courseDay),
      courseTotalDays: courseTotalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(courseTotalDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      name: serializer.fromJson<String>(json['name']),
      strength: serializer.fromJson<String>(json['strength']),
      strengthUnit: serializer.fromJson<String?>(json['strengthUnit']),
      medicineForm: serializer.fromJson<String?>(json['medicineForm']),
      colorName: serializer.fromJson<String?>(json['colorName']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      linkedPharmacyId: serializer.fromJson<String?>(json['linkedPharmacyId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      discontinuedAt: serializer.fromJson<DateTime?>(json['discontinuedAt']),
      discontinuedReason: serializer.fromJson<String?>(
        json['discontinuedReason'],
      ),
      courseDay: serializer.fromJson<int?>(json['courseDay']),
      courseTotalDays: serializer.fromJson<int?>(json['courseTotalDays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'name': serializer.toJson<String>(name),
      'strength': serializer.toJson<String>(strength),
      'strengthUnit': serializer.toJson<String?>(strengthUnit),
      'medicineForm': serializer.toJson<String?>(medicineForm),
      'colorName': serializer.toJson<String?>(colorName),
      'instructions': serializer.toJson<String?>(instructions),
      'imagePath': serializer.toJson<String?>(imagePath),
      'linkedPharmacyId': serializer.toJson<String?>(linkedPharmacyId),
      'isActive': serializer.toJson<bool>(isActive),
      'discontinuedAt': serializer.toJson<DateTime?>(discontinuedAt),
      'discontinuedReason': serializer.toJson<String?>(discontinuedReason),
      'courseDay': serializer.toJson<int?>(courseDay),
      'courseTotalDays': serializer.toJson<int?>(courseTotalDays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Medication copyWith({
    String? id,
    String? memberId,
    String? name,
    String? strength,
    Value<String?> strengthUnit = const Value.absent(),
    Value<String?> medicineForm = const Value.absent(),
    Value<String?> colorName = const Value.absent(),
    Value<String?> instructions = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    Value<String?> linkedPharmacyId = const Value.absent(),
    bool? isActive,
    Value<DateTime?> discontinuedAt = const Value.absent(),
    Value<String?> discontinuedReason = const Value.absent(),
    Value<int?> courseDay = const Value.absent(),
    Value<int?> courseTotalDays = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Medication(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    strength: strength ?? this.strength,
    strengthUnit: strengthUnit.present ? strengthUnit.value : this.strengthUnit,
    medicineForm: medicineForm.present ? medicineForm.value : this.medicineForm,
    colorName: colorName.present ? colorName.value : this.colorName,
    instructions: instructions.present ? instructions.value : this.instructions,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    linkedPharmacyId: linkedPharmacyId.present
        ? linkedPharmacyId.value
        : this.linkedPharmacyId,
    isActive: isActive ?? this.isActive,
    discontinuedAt: discontinuedAt.present
        ? discontinuedAt.value
        : this.discontinuedAt,
    discontinuedReason: discontinuedReason.present
        ? discontinuedReason.value
        : this.discontinuedReason,
    courseDay: courseDay.present ? courseDay.value : this.courseDay,
    courseTotalDays: courseTotalDays.present
        ? courseTotalDays.value
        : this.courseTotalDays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      strength: data.strength.present ? data.strength.value : this.strength,
      strengthUnit: data.strengthUnit.present
          ? data.strengthUnit.value
          : this.strengthUnit,
      medicineForm: data.medicineForm.present
          ? data.medicineForm.value
          : this.medicineForm,
      colorName: data.colorName.present ? data.colorName.value : this.colorName,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      linkedPharmacyId: data.linkedPharmacyId.present
          ? data.linkedPharmacyId.value
          : this.linkedPharmacyId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      discontinuedAt: data.discontinuedAt.present
          ? data.discontinuedAt.value
          : this.discontinuedAt,
      discontinuedReason: data.discontinuedReason.present
          ? data.discontinuedReason.value
          : this.discontinuedReason,
      courseDay: data.courseDay.present ? data.courseDay.value : this.courseDay,
      courseTotalDays: data.courseTotalDays.present
          ? data.courseTotalDays.value
          : this.courseTotalDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('strengthUnit: $strengthUnit, ')
          ..write('medicineForm: $medicineForm, ')
          ..write('colorName: $colorName, ')
          ..write('instructions: $instructions, ')
          ..write('imagePath: $imagePath, ')
          ..write('linkedPharmacyId: $linkedPharmacyId, ')
          ..write('isActive: $isActive, ')
          ..write('discontinuedAt: $discontinuedAt, ')
          ..write('discontinuedReason: $discontinuedReason, ')
          ..write('courseDay: $courseDay, ')
          ..write('courseTotalDays: $courseTotalDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    strength,
    strengthUnit,
    medicineForm,
    colorName,
    instructions,
    imagePath,
    linkedPharmacyId,
    isActive,
    discontinuedAt,
    discontinuedReason,
    courseDay,
    courseTotalDays,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.strength == this.strength &&
          other.strengthUnit == this.strengthUnit &&
          other.medicineForm == this.medicineForm &&
          other.colorName == this.colorName &&
          other.instructions == this.instructions &&
          other.imagePath == this.imagePath &&
          other.linkedPharmacyId == this.linkedPharmacyId &&
          other.isActive == this.isActive &&
          other.discontinuedAt == this.discontinuedAt &&
          other.discontinuedReason == this.discontinuedReason &&
          other.courseDay == this.courseDay &&
          other.courseTotalDays == this.courseTotalDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> name;
  final Value<String> strength;
  final Value<String?> strengthUnit;
  final Value<String?> medicineForm;
  final Value<String?> colorName;
  final Value<String?> instructions;
  final Value<String?> imagePath;
  final Value<String?> linkedPharmacyId;
  final Value<bool> isActive;
  final Value<DateTime?> discontinuedAt;
  final Value<String?> discontinuedReason;
  final Value<int?> courseDay;
  final Value<int?> courseTotalDays;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.strength = const Value.absent(),
    this.strengthUnit = const Value.absent(),
    this.medicineForm = const Value.absent(),
    this.colorName = const Value.absent(),
    this.instructions = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.linkedPharmacyId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.discontinuedAt = const Value.absent(),
    this.discontinuedReason = const Value.absent(),
    this.courseDay = const Value.absent(),
    this.courseTotalDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String memberId,
    required String name,
    required String strength,
    this.strengthUnit = const Value.absent(),
    this.medicineForm = const Value.absent(),
    this.colorName = const Value.absent(),
    this.instructions = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.linkedPharmacyId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.discontinuedAt = const Value.absent(),
    this.discontinuedReason = const Value.absent(),
    this.courseDay = const Value.absent(),
    this.courseTotalDays = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       name = Value(name),
       strength = Value(strength),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Medication> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? name,
    Expression<String>? strength,
    Expression<String>? strengthUnit,
    Expression<String>? medicineForm,
    Expression<String>? colorName,
    Expression<String>? instructions,
    Expression<String>? imagePath,
    Expression<String>? linkedPharmacyId,
    Expression<bool>? isActive,
    Expression<DateTime>? discontinuedAt,
    Expression<String>? discontinuedReason,
    Expression<int>? courseDay,
    Expression<int>? courseTotalDays,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (strength != null) 'strength': strength,
      if (strengthUnit != null) 'strength_unit': strengthUnit,
      if (medicineForm != null) 'medicine_form': medicineForm,
      if (colorName != null) 'color_name': colorName,
      if (instructions != null) 'instructions': instructions,
      if (imagePath != null) 'image_path': imagePath,
      if (linkedPharmacyId != null) 'linked_pharmacy_id': linkedPharmacyId,
      if (isActive != null) 'is_active': isActive,
      if (discontinuedAt != null) 'discontinued_at': discontinuedAt,
      if (discontinuedReason != null) 'discontinued_reason': discontinuedReason,
      if (courseDay != null) 'course_day': courseDay,
      if (courseTotalDays != null) 'course_total_days': courseTotalDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? name,
    Value<String>? strength,
    Value<String?>? strengthUnit,
    Value<String?>? medicineForm,
    Value<String?>? colorName,
    Value<String?>? instructions,
    Value<String?>? imagePath,
    Value<String?>? linkedPharmacyId,
    Value<bool>? isActive,
    Value<DateTime?>? discontinuedAt,
    Value<String?>? discontinuedReason,
    Value<int?>? courseDay,
    Value<int?>? courseTotalDays,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      medicineForm: medicineForm ?? this.medicineForm,
      colorName: colorName ?? this.colorName,
      instructions: instructions ?? this.instructions,
      imagePath: imagePath ?? this.imagePath,
      linkedPharmacyId: linkedPharmacyId ?? this.linkedPharmacyId,
      isActive: isActive ?? this.isActive,
      discontinuedAt: discontinuedAt ?? this.discontinuedAt,
      discontinuedReason: discontinuedReason ?? this.discontinuedReason,
      courseDay: courseDay ?? this.courseDay,
      courseTotalDays: courseTotalDays ?? this.courseTotalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (strength.present) {
      map['strength'] = Variable<String>(strength.value);
    }
    if (strengthUnit.present) {
      map['strength_unit'] = Variable<String>(strengthUnit.value);
    }
    if (medicineForm.present) {
      map['medicine_form'] = Variable<String>(medicineForm.value);
    }
    if (colorName.present) {
      map['color_name'] = Variable<String>(colorName.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (linkedPharmacyId.present) {
      map['linked_pharmacy_id'] = Variable<String>(linkedPharmacyId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (discontinuedAt.present) {
      map['discontinued_at'] = Variable<DateTime>(discontinuedAt.value);
    }
    if (discontinuedReason.present) {
      map['discontinued_reason'] = Variable<String>(discontinuedReason.value);
    }
    if (courseDay.present) {
      map['course_day'] = Variable<int>(courseDay.value);
    }
    if (courseTotalDays.present) {
      map['course_total_days'] = Variable<int>(courseTotalDays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('strengthUnit: $strengthUnit, ')
          ..write('medicineForm: $medicineForm, ')
          ..write('colorName: $colorName, ')
          ..write('instructions: $instructions, ')
          ..write('imagePath: $imagePath, ')
          ..write('linkedPharmacyId: $linkedPharmacyId, ')
          ..write('isActive: $isActive, ')
          ..write('discontinuedAt: $discontinuedAt, ')
          ..write('discontinuedReason: $discontinuedReason, ')
          ..write('courseDay: $courseDay, ')
          ..write('courseTotalDays: $courseTotalDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationSchedulesTable extends MedicationSchedules
    with TableInfo<$MedicationSchedulesTable, MedicationSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _scheduleTypeMeta = const VerificationMeta(
    'scheduleType',
  );
  @override
  late final GeneratedColumn<String> scheduleType = GeneratedColumn<String>(
    'schedule_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  @override
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
    'days_of_week',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseAmountMeta = const VerificationMeta(
    'doseAmount',
  );
  @override
  late final GeneratedColumn<double> doseAmount = GeneratedColumn<double>(
    'dose_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _doseUnitMeta = const VerificationMeta(
    'doseUnit',
  );
  @override
  late final GeneratedColumn<String> doseUnit = GeneratedColumn<String>(
    'dose_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    memberId,
    scheduleType,
    timeOfDay,
    daysOfWeek,
    doseAmount,
    doseUnit,
    startDate,
    endDate,
    isEnabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('schedule_type')) {
      context.handle(
        _scheduleTypeMeta,
        scheduleType.isAcceptableOrUnknown(
          data['schedule_type']!,
          _scheduleTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleTypeMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('dose_amount')) {
      context.handle(
        _doseAmountMeta,
        doseAmount.isAcceptableOrUnknown(data['dose_amount']!, _doseAmountMeta),
      );
    }
    if (data.containsKey('dose_unit')) {
      context.handle(
        _doseUnitMeta,
        doseUnit.isAcceptableOrUnknown(data['dose_unit']!, _doseUnitMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      scheduleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_type'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_of_week'],
      ),
      doseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_amount'],
      )!,
      doseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_unit'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MedicationSchedulesTable createAlias(String alias) {
    return $MedicationSchedulesTable(attachedDatabase, alias);
  }
}

class MedicationSchedule extends DataClass
    implements Insertable<MedicationSchedule> {
  final String id;
  final String medicationId;
  final String memberId;

  /// daily / specificDays / interval etc.
  final String scheduleType;

  /// HH:mm local wall-clock time.
  final String timeOfDay;

  /// JSON/string representation initially.
  /// Example: Mon,Tue,Wed
  final String? daysOfWeek;
  final double doseAmount;
  final String? doseUnit;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MedicationSchedule({
    required this.id,
    required this.medicationId,
    required this.memberId,
    required this.scheduleType,
    required this.timeOfDay,
    this.daysOfWeek,
    required this.doseAmount,
    this.doseUnit,
    required this.startDate,
    this.endDate,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['member_id'] = Variable<String>(memberId);
    map['schedule_type'] = Variable<String>(scheduleType);
    map['time_of_day'] = Variable<String>(timeOfDay);
    if (!nullToAbsent || daysOfWeek != null) {
      map['days_of_week'] = Variable<String>(daysOfWeek);
    }
    map['dose_amount'] = Variable<double>(doseAmount);
    if (!nullToAbsent || doseUnit != null) {
      map['dose_unit'] = Variable<String>(doseUnit);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationSchedulesCompanion toCompanion(bool nullToAbsent) {
    return MedicationSchedulesCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      memberId: Value(memberId),
      scheduleType: Value(scheduleType),
      timeOfDay: Value(timeOfDay),
      daysOfWeek: daysOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysOfWeek),
      doseAmount: Value(doseAmount),
      doseUnit: doseUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(doseUnit),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      isEnabled: Value(isEnabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MedicationSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationSchedule(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      scheduleType: serializer.fromJson<String>(json['scheduleType']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      daysOfWeek: serializer.fromJson<String?>(json['daysOfWeek']),
      doseAmount: serializer.fromJson<double>(json['doseAmount']),
      doseUnit: serializer.fromJson<String?>(json['doseUnit']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'memberId': serializer.toJson<String>(memberId),
      'scheduleType': serializer.toJson<String>(scheduleType),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'daysOfWeek': serializer.toJson<String?>(daysOfWeek),
      'doseAmount': serializer.toJson<double>(doseAmount),
      'doseUnit': serializer.toJson<String?>(doseUnit),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MedicationSchedule copyWith({
    String? id,
    String? medicationId,
    String? memberId,
    String? scheduleType,
    String? timeOfDay,
    Value<String?> daysOfWeek = const Value.absent(),
    double? doseAmount,
    Value<String?> doseUnit = const Value.absent(),
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MedicationSchedule(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    memberId: memberId ?? this.memberId,
    scheduleType: scheduleType ?? this.scheduleType,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    daysOfWeek: daysOfWeek.present ? daysOfWeek.value : this.daysOfWeek,
    doseAmount: doseAmount ?? this.doseAmount,
    doseUnit: doseUnit.present ? doseUnit.value : this.doseUnit,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MedicationSchedule copyWithCompanion(MedicationSchedulesCompanion data) {
    return MedicationSchedule(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      scheduleType: data.scheduleType.present
          ? data.scheduleType.value
          : this.scheduleType,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
      doseAmount: data.doseAmount.present
          ? data.doseAmount.value
          : this.doseAmount,
      doseUnit: data.doseUnit.present ? data.doseUnit.value : this.doseUnit,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationSchedule(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('memberId: $memberId, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    memberId,
    scheduleType,
    timeOfDay,
    daysOfWeek,
    doseAmount,
    doseUnit,
    startDate,
    endDate,
    isEnabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationSchedule &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.memberId == this.memberId &&
          other.scheduleType == this.scheduleType &&
          other.timeOfDay == this.timeOfDay &&
          other.daysOfWeek == this.daysOfWeek &&
          other.doseAmount == this.doseAmount &&
          other.doseUnit == this.doseUnit &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.isEnabled == this.isEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationSchedulesCompanion extends UpdateCompanion<MedicationSchedule> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<String> memberId;
  final Value<String> scheduleType;
  final Value<String> timeOfDay;
  final Value<String?> daysOfWeek;
  final Value<double> doseAmount;
  final Value<String?> doseUnit;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<bool> isEnabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MedicationSchedulesCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.scheduleType = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationSchedulesCompanion.insert({
    required String id,
    required String medicationId,
    required String memberId,
    required String scheduleType,
    required String timeOfDay,
    this.daysOfWeek = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.isEnabled = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       memberId = Value(memberId),
       scheduleType = Value(scheduleType),
       timeOfDay = Value(timeOfDay),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MedicationSchedule> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<String>? memberId,
    Expression<String>? scheduleType,
    Expression<String>? timeOfDay,
    Expression<String>? daysOfWeek,
    Expression<double>? doseAmount,
    Expression<String>? doseUnit,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? isEnabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (memberId != null) 'member_id': memberId,
      if (scheduleType != null) 'schedule_type': scheduleType,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (doseAmount != null) 'dose_amount': doseAmount,
      if (doseUnit != null) 'dose_unit': doseUnit,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationSchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<String>? memberId,
    Value<String>? scheduleType,
    Value<String>? timeOfDay,
    Value<String?>? daysOfWeek,
    Value<double>? doseAmount,
    Value<String?>? doseUnit,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<bool>? isEnabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MedicationSchedulesCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      memberId: memberId ?? this.memberId,
      scheduleType: scheduleType ?? this.scheduleType,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (scheduleType.present) {
      map['schedule_type'] = Variable<String>(scheduleType.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<String>(daysOfWeek.value);
    }
    if (doseAmount.present) {
      map['dose_amount'] = Variable<double>(doseAmount.value);
    }
    if (doseUnit.present) {
      map['dose_unit'] = Variable<String>(doseUnit.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('memberId: $memberId, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DoseEventsTable extends DoseEvents
    with TableInfo<$DoseEventsTable, DoseEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoseEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id)',
    ),
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medication_schedules (id)',
    ),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missedReasonTypeMeta = const VerificationMeta(
    'missedReasonType',
  );
  @override
  late final GeneratedColumn<String> missedReasonType = GeneratedColumn<String>(
    'missed_reason_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missedReasonTextMeta = const VerificationMeta(
    'missedReasonText',
  );
  @override
  late final GeneratedColumn<String> missedReasonText = GeneratedColumn<String>(
    'missed_reason_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    medicationId,
    scheduleId,
    scheduledAt,
    status,
    completedAt,
    missedReasonType,
    missedReasonText,
    note,
    snoozedUntil,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoseEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('missed_reason_type')) {
      context.handle(
        _missedReasonTypeMeta,
        missedReasonType.isAcceptableOrUnknown(
          data['missed_reason_type']!,
          _missedReasonTypeMeta,
        ),
      );
    }
    if (data.containsKey('missed_reason_text')) {
      context.handle(
        _missedReasonTextMeta,
        missedReasonText.isAcceptableOrUnknown(
          data['missed_reason_text']!,
          _missedReasonTextMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoseEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      missedReasonType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missed_reason_type'],
      ),
      missedReasonText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missed_reason_text'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DoseEventsTable createAlias(String alias) {
    return $DoseEventsTable(attachedDatabase, alias);
  }
}

class DoseEvent extends DataClass implements Insertable<DoseEvent> {
  final String id;
  final String memberId;
  final String medicationId;
  final String? scheduleId;
  final DateTime scheduledAt;

  /// pending / taken / missed / skipped
  final String status;
  final DateTime? completedAt;
  final String? missedReasonType;
  final String? missedReasonText;
  final String? note;
  final DateTime? snoozedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DoseEvent({
    required this.id,
    required this.memberId,
    required this.medicationId,
    this.scheduleId,
    required this.scheduledAt,
    required this.status,
    this.completedAt,
    this.missedReasonType,
    this.missedReasonText,
    this.note,
    this.snoozedUntil,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['medication_id'] = Variable<String>(medicationId);
    if (!nullToAbsent || scheduleId != null) {
      map['schedule_id'] = Variable<String>(scheduleId);
    }
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || missedReasonType != null) {
      map['missed_reason_type'] = Variable<String>(missedReasonType);
    }
    if (!nullToAbsent || missedReasonText != null) {
      map['missed_reason_text'] = Variable<String>(missedReasonText);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DoseEventsCompanion toCompanion(bool nullToAbsent) {
    return DoseEventsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      medicationId: Value(medicationId),
      scheduleId: scheduleId == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleId),
      scheduledAt: Value(scheduledAt),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      missedReasonType: missedReasonType == null && nullToAbsent
          ? const Value.absent()
          : Value(missedReasonType),
      missedReasonText: missedReasonText == null && nullToAbsent
          ? const Value.absent()
          : Value(missedReasonText),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DoseEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseEvent(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      scheduleId: serializer.fromJson<String?>(json['scheduleId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      missedReasonType: serializer.fromJson<String?>(json['missedReasonType']),
      missedReasonText: serializer.fromJson<String?>(json['missedReasonText']),
      note: serializer.fromJson<String?>(json['note']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'medicationId': serializer.toJson<String>(medicationId),
      'scheduleId': serializer.toJson<String?>(scheduleId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'missedReasonType': serializer.toJson<String?>(missedReasonType),
      'missedReasonText': serializer.toJson<String?>(missedReasonText),
      'note': serializer.toJson<String?>(note),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DoseEvent copyWith({
    String? id,
    String? memberId,
    String? medicationId,
    Value<String?> scheduleId = const Value.absent(),
    DateTime? scheduledAt,
    String? status,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> missedReasonType = const Value.absent(),
    Value<String?> missedReasonText = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<DateTime?> snoozedUntil = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DoseEvent(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    medicationId: medicationId ?? this.medicationId,
    scheduleId: scheduleId.present ? scheduleId.value : this.scheduleId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    missedReasonType: missedReasonType.present
        ? missedReasonType.value
        : this.missedReasonType,
    missedReasonText: missedReasonText.present
        ? missedReasonText.value
        : this.missedReasonText,
    note: note.present ? note.value : this.note,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DoseEvent copyWithCompanion(DoseEventsCompanion data) {
    return DoseEvent(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      missedReasonType: data.missedReasonType.present
          ? data.missedReasonType.value
          : this.missedReasonType,
      missedReasonText: data.missedReasonText.present
          ? data.missedReasonText.value
          : this.missedReasonText,
      note: data.note.present ? data.note.value : this.note,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseEvent(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('missedReasonType: $missedReasonType, ')
          ..write('missedReasonText: $missedReasonText, ')
          ..write('note: $note, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    medicationId,
    scheduleId,
    scheduledAt,
    status,
    completedAt,
    missedReasonType,
    missedReasonText,
    note,
    snoozedUntil,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseEvent &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.medicationId == this.medicationId &&
          other.scheduleId == this.scheduleId &&
          other.scheduledAt == this.scheduledAt &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.missedReasonType == this.missedReasonType &&
          other.missedReasonText == this.missedReasonText &&
          other.note == this.note &&
          other.snoozedUntil == this.snoozedUntil &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DoseEventsCompanion extends UpdateCompanion<DoseEvent> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> medicationId;
  final Value<String?> scheduleId;
  final Value<DateTime> scheduledAt;
  final Value<String> status;
  final Value<DateTime?> completedAt;
  final Value<String?> missedReasonType;
  final Value<String?> missedReasonText;
  final Value<String?> note;
  final Value<DateTime?> snoozedUntil;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DoseEventsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.missedReasonType = const Value.absent(),
    this.missedReasonText = const Value.absent(),
    this.note = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoseEventsCompanion.insert({
    required String id,
    required String memberId,
    required String medicationId,
    this.scheduleId = const Value.absent(),
    required DateTime scheduledAt,
    required String status,
    this.completedAt = const Value.absent(),
    this.missedReasonType = const Value.absent(),
    this.missedReasonText = const Value.absent(),
    this.note = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       medicationId = Value(medicationId),
       scheduledAt = Value(scheduledAt),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DoseEvent> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? medicationId,
    Expression<String>? scheduleId,
    Expression<DateTime>? scheduledAt,
    Expression<String>? status,
    Expression<DateTime>? completedAt,
    Expression<String>? missedReasonType,
    Expression<String>? missedReasonText,
    Expression<String>? note,
    Expression<DateTime>? snoozedUntil,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (missedReasonType != null) 'missed_reason_type': missedReasonType,
      if (missedReasonText != null) 'missed_reason_text': missedReasonText,
      if (note != null) 'note': note,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoseEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? medicationId,
    Value<String?>? scheduleId,
    Value<DateTime>? scheduledAt,
    Value<String>? status,
    Value<DateTime?>? completedAt,
    Value<String?>? missedReasonType,
    Value<String?>? missedReasonText,
    Value<String?>? note,
    Value<DateTime?>? snoozedUntil,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DoseEventsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      medicationId: medicationId ?? this.medicationId,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      missedReasonType: missedReasonType ?? this.missedReasonType,
      missedReasonText: missedReasonText ?? this.missedReasonText,
      note: note ?? this.note,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (missedReasonType.present) {
      map['missed_reason_type'] = Variable<String>(missedReasonType.value);
    }
    if (missedReasonText.present) {
      map['missed_reason_text'] = Variable<String>(missedReasonText.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseEventsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('missedReasonType: $missedReasonType, ')
          ..write('missedReasonText: $missedReasonText, ')
          ..write('note: $note, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PharmaciesTable extends Pharmacies
    with TableInfo<$PharmaciesTable, Pharmacy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PharmaciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _websiteMeta = const VerificationMeta(
    'website',
  );
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
    'website',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hoursTextMeta = const VerificationMeta(
    'hoursText',
  );
  @override
  late final GeneratedColumn<String> hoursText = GeneratedColumn<String>(
    'hours_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPreferredMeta = const VerificationMeta(
    'isPreferred',
  );
  @override
  late final GeneratedColumn<bool> isPreferred = GeneratedColumn<bool>(
    'is_preferred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_preferred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    address,
    phone,
    email,
    website,
    hoursText,
    latitude,
    longitude,
    isPreferred,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pharmacies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pharmacy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('website')) {
      context.handle(
        _websiteMeta,
        website.isAcceptableOrUnknown(data['website']!, _websiteMeta),
      );
    }
    if (data.containsKey('hours_text')) {
      context.handle(
        _hoursTextMeta,
        hoursText.isAcceptableOrUnknown(data['hours_text']!, _hoursTextMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('is_preferred')) {
      context.handle(
        _isPreferredMeta,
        isPreferred.isAcceptableOrUnknown(
          data['is_preferred']!,
          _isPreferredMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pharmacy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pharmacy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      website: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website'],
      ),
      hoursText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hours_text'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      isPreferred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_preferred'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PharmaciesTable createAlias(String alias) {
    return $PharmaciesTable(attachedDatabase, alias);
  }
}

class Pharmacy extends DataClass implements Insertable<Pharmacy> {
  final String id;
  final String memberId;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? hoursText;
  final double? latitude;
  final double? longitude;
  final bool isPreferred;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Pharmacy({
    required this.id,
    required this.memberId,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.hoursText,
    this.latitude,
    this.longitude,
    required this.isPreferred,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || website != null) {
      map['website'] = Variable<String>(website);
    }
    if (!nullToAbsent || hoursText != null) {
      map['hours_text'] = Variable<String>(hoursText);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['is_preferred'] = Variable<bool>(isPreferred);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PharmaciesCompanion toCompanion(bool nullToAbsent) {
    return PharmaciesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      website: website == null && nullToAbsent
          ? const Value.absent()
          : Value(website),
      hoursText: hoursText == null && nullToAbsent
          ? const Value.absent()
          : Value(hoursText),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      isPreferred: Value(isPreferred),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Pharmacy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pharmacy(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      website: serializer.fromJson<String?>(json['website']),
      hoursText: serializer.fromJson<String?>(json['hoursText']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      isPreferred: serializer.fromJson<bool>(json['isPreferred']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'website': serializer.toJson<String?>(website),
      'hoursText': serializer.toJson<String?>(hoursText),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'isPreferred': serializer.toJson<bool>(isPreferred),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Pharmacy copyWith({
    String? id,
    String? memberId,
    String? name,
    Value<String?> address = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> website = const Value.absent(),
    Value<String?> hoursText = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    bool? isPreferred,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Pharmacy(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    website: website.present ? website.value : this.website,
    hoursText: hoursText.present ? hoursText.value : this.hoursText,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    isPreferred: isPreferred ?? this.isPreferred,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Pharmacy copyWithCompanion(PharmaciesCompanion data) {
    return Pharmacy(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      website: data.website.present ? data.website.value : this.website,
      hoursText: data.hoursText.present ? data.hoursText.value : this.hoursText,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isPreferred: data.isPreferred.present
          ? data.isPreferred.value
          : this.isPreferred,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pharmacy(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('hoursText: $hoursText, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isPreferred: $isPreferred, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    address,
    phone,
    email,
    website,
    hoursText,
    latitude,
    longitude,
    isPreferred,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pharmacy &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.website == this.website &&
          other.hoursText == this.hoursText &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isPreferred == this.isPreferred &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PharmaciesCompanion extends UpdateCompanion<Pharmacy> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> name;
  final Value<String?> address;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> website;
  final Value<String?> hoursText;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<bool> isPreferred;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PharmaciesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.hoursText = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isPreferred = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PharmaciesCompanion.insert({
    required String id,
    required String memberId,
    required String name,
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.hoursText = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isPreferred = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Pharmacy> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? website,
    Expression<String>? hoursText,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? isPreferred,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (hoursText != null) 'hours_text': hoursText,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isPreferred != null) 'is_preferred': isPreferred,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PharmaciesCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? name,
    Value<String?>? address,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? website,
    Value<String?>? hoursText,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<bool>? isPreferred,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PharmaciesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      hoursText: hoursText ?? this.hoursText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPreferred: isPreferred ?? this.isPreferred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (hoursText.present) {
      map['hours_text'] = Variable<String>(hoursText.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (isPreferred.present) {
      map['is_preferred'] = Variable<bool>(isPreferred.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PharmaciesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('hoursText: $hoursText, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isPreferred: $isPreferred, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryRecordsTable extends InventoryRecords
    with TableInfo<$InventoryRecordsTable, InventoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id)',
    ),
  );
  static const VerificationMeta _remainingQuantityMeta = const VerificationMeta(
    'remainingQuantity',
  );
  @override
  late final GeneratedColumn<double> remainingQuantity =
      GeneratedColumn<double>(
        'remaining_quantity',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _packageQuantityMeta = const VerificationMeta(
    'packageQuantity',
  );
  @override
  late final GeneratedColumn<double> packageQuantity = GeneratedColumn<double>(
    'package_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitsPerDayMeta = const VerificationMeta(
    'unitsPerDay',
  );
  @override
  late final GeneratedColumn<double> unitsPerDay = GeneratedColumn<double>(
    'units_per_day',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitLabelMeta = const VerificationMeta(
    'unitLabel',
  );
  @override
  late final GeneratedColumn<String> unitLabel = GeneratedColumn<String>(
    'unit_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowStockThresholdDaysMeta =
      const VerificationMeta('lowStockThresholdDays');
  @override
  late final GeneratedColumn<int> lowStockThresholdDays = GeneratedColumn<int>(
    'low_stock_threshold_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _lastRefilledAtMeta = const VerificationMeta(
    'lastRefilledAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRefilledAt =
      GeneratedColumn<DateTime>(
        'last_refilled_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    medicationId,
    remainingQuantity,
    packageQuantity,
    unitsPerDay,
    unitLabel,
    lowStockThresholdDays,
    lastRefilledAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('remaining_quantity')) {
      context.handle(
        _remainingQuantityMeta,
        remainingQuantity.isAcceptableOrUnknown(
          data['remaining_quantity']!,
          _remainingQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remainingQuantityMeta);
    }
    if (data.containsKey('package_quantity')) {
      context.handle(
        _packageQuantityMeta,
        packageQuantity.isAcceptableOrUnknown(
          data['package_quantity']!,
          _packageQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageQuantityMeta);
    }
    if (data.containsKey('units_per_day')) {
      context.handle(
        _unitsPerDayMeta,
        unitsPerDay.isAcceptableOrUnknown(
          data['units_per_day']!,
          _unitsPerDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitsPerDayMeta);
    }
    if (data.containsKey('unit_label')) {
      context.handle(
        _unitLabelMeta,
        unitLabel.isAcceptableOrUnknown(data['unit_label']!, _unitLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_unitLabelMeta);
    }
    if (data.containsKey('low_stock_threshold_days')) {
      context.handle(
        _lowStockThresholdDaysMeta,
        lowStockThresholdDays.isAcceptableOrUnknown(
          data['low_stock_threshold_days']!,
          _lowStockThresholdDaysMeta,
        ),
      );
    }
    if (data.containsKey('last_refilled_at')) {
      context.handle(
        _lastRefilledAtMeta,
        lastRefilledAt.isAcceptableOrUnknown(
          data['last_refilled_at']!,
          _lastRefilledAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {memberId, medicationId},
  ];
  @override
  InventoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      remainingQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_quantity'],
      )!,
      packageQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}package_quantity'],
      )!,
      unitsPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}units_per_day'],
      )!,
      unitLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_label'],
      )!,
      lowStockThresholdDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_threshold_days'],
      )!,
      lastRefilledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_refilled_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InventoryRecordsTable createAlias(String alias) {
    return $InventoryRecordsTable(attachedDatabase, alias);
  }
}

class InventoryRecord extends DataClass implements Insertable<InventoryRecord> {
  final String id;
  final String memberId;
  final String medicationId;
  final double remainingQuantity;
  final double packageQuantity;
  final double unitsPerDay;
  final String unitLabel;
  final int lowStockThresholdDays;
  final DateTime? lastRefilledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InventoryRecord({
    required this.id,
    required this.memberId,
    required this.medicationId,
    required this.remainingQuantity,
    required this.packageQuantity,
    required this.unitsPerDay,
    required this.unitLabel,
    required this.lowStockThresholdDays,
    this.lastRefilledAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['medication_id'] = Variable<String>(medicationId);
    map['remaining_quantity'] = Variable<double>(remainingQuantity);
    map['package_quantity'] = Variable<double>(packageQuantity);
    map['units_per_day'] = Variable<double>(unitsPerDay);
    map['unit_label'] = Variable<String>(unitLabel);
    map['low_stock_threshold_days'] = Variable<int>(lowStockThresholdDays);
    if (!nullToAbsent || lastRefilledAt != null) {
      map['last_refilled_at'] = Variable<DateTime>(lastRefilledAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InventoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return InventoryRecordsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      medicationId: Value(medicationId),
      remainingQuantity: Value(remainingQuantity),
      packageQuantity: Value(packageQuantity),
      unitsPerDay: Value(unitsPerDay),
      unitLabel: Value(unitLabel),
      lowStockThresholdDays: Value(lowStockThresholdDays),
      lastRefilledAt: lastRefilledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefilledAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InventoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryRecord(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      remainingQuantity: serializer.fromJson<double>(json['remainingQuantity']),
      packageQuantity: serializer.fromJson<double>(json['packageQuantity']),
      unitsPerDay: serializer.fromJson<double>(json['unitsPerDay']),
      unitLabel: serializer.fromJson<String>(json['unitLabel']),
      lowStockThresholdDays: serializer.fromJson<int>(
        json['lowStockThresholdDays'],
      ),
      lastRefilledAt: serializer.fromJson<DateTime?>(json['lastRefilledAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'medicationId': serializer.toJson<String>(medicationId),
      'remainingQuantity': serializer.toJson<double>(remainingQuantity),
      'packageQuantity': serializer.toJson<double>(packageQuantity),
      'unitsPerDay': serializer.toJson<double>(unitsPerDay),
      'unitLabel': serializer.toJson<String>(unitLabel),
      'lowStockThresholdDays': serializer.toJson<int>(lowStockThresholdDays),
      'lastRefilledAt': serializer.toJson<DateTime?>(lastRefilledAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InventoryRecord copyWith({
    String? id,
    String? memberId,
    String? medicationId,
    double? remainingQuantity,
    double? packageQuantity,
    double? unitsPerDay,
    String? unitLabel,
    int? lowStockThresholdDays,
    Value<DateTime?> lastRefilledAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InventoryRecord(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    medicationId: medicationId ?? this.medicationId,
    remainingQuantity: remainingQuantity ?? this.remainingQuantity,
    packageQuantity: packageQuantity ?? this.packageQuantity,
    unitsPerDay: unitsPerDay ?? this.unitsPerDay,
    unitLabel: unitLabel ?? this.unitLabel,
    lowStockThresholdDays: lowStockThresholdDays ?? this.lowStockThresholdDays,
    lastRefilledAt: lastRefilledAt.present
        ? lastRefilledAt.value
        : this.lastRefilledAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InventoryRecord copyWithCompanion(InventoryRecordsCompanion data) {
    return InventoryRecord(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      remainingQuantity: data.remainingQuantity.present
          ? data.remainingQuantity.value
          : this.remainingQuantity,
      packageQuantity: data.packageQuantity.present
          ? data.packageQuantity.value
          : this.packageQuantity,
      unitsPerDay: data.unitsPerDay.present
          ? data.unitsPerDay.value
          : this.unitsPerDay,
      unitLabel: data.unitLabel.present ? data.unitLabel.value : this.unitLabel,
      lowStockThresholdDays: data.lowStockThresholdDays.present
          ? data.lowStockThresholdDays.value
          : this.lowStockThresholdDays,
      lastRefilledAt: data.lastRefilledAt.present
          ? data.lastRefilledAt.value
          : this.lastRefilledAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryRecord(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('remainingQuantity: $remainingQuantity, ')
          ..write('packageQuantity: $packageQuantity, ')
          ..write('unitsPerDay: $unitsPerDay, ')
          ..write('unitLabel: $unitLabel, ')
          ..write('lowStockThresholdDays: $lowStockThresholdDays, ')
          ..write('lastRefilledAt: $lastRefilledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    medicationId,
    remainingQuantity,
    packageQuantity,
    unitsPerDay,
    unitLabel,
    lowStockThresholdDays,
    lastRefilledAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryRecord &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.medicationId == this.medicationId &&
          other.remainingQuantity == this.remainingQuantity &&
          other.packageQuantity == this.packageQuantity &&
          other.unitsPerDay == this.unitsPerDay &&
          other.unitLabel == this.unitLabel &&
          other.lowStockThresholdDays == this.lowStockThresholdDays &&
          other.lastRefilledAt == this.lastRefilledAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InventoryRecordsCompanion extends UpdateCompanion<InventoryRecord> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> medicationId;
  final Value<double> remainingQuantity;
  final Value<double> packageQuantity;
  final Value<double> unitsPerDay;
  final Value<String> unitLabel;
  final Value<int> lowStockThresholdDays;
  final Value<DateTime?> lastRefilledAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InventoryRecordsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.remainingQuantity = const Value.absent(),
    this.packageQuantity = const Value.absent(),
    this.unitsPerDay = const Value.absent(),
    this.unitLabel = const Value.absent(),
    this.lowStockThresholdDays = const Value.absent(),
    this.lastRefilledAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryRecordsCompanion.insert({
    required String id,
    required String memberId,
    required String medicationId,
    required double remainingQuantity,
    required double packageQuantity,
    required double unitsPerDay,
    required String unitLabel,
    this.lowStockThresholdDays = const Value.absent(),
    this.lastRefilledAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       medicationId = Value(medicationId),
       remainingQuantity = Value(remainingQuantity),
       packageQuantity = Value(packageQuantity),
       unitsPerDay = Value(unitsPerDay),
       unitLabel = Value(unitLabel),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InventoryRecord> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? medicationId,
    Expression<double>? remainingQuantity,
    Expression<double>? packageQuantity,
    Expression<double>? unitsPerDay,
    Expression<String>? unitLabel,
    Expression<int>? lowStockThresholdDays,
    Expression<DateTime>? lastRefilledAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (medicationId != null) 'medication_id': medicationId,
      if (remainingQuantity != null) 'remaining_quantity': remainingQuantity,
      if (packageQuantity != null) 'package_quantity': packageQuantity,
      if (unitsPerDay != null) 'units_per_day': unitsPerDay,
      if (unitLabel != null) 'unit_label': unitLabel,
      if (lowStockThresholdDays != null)
        'low_stock_threshold_days': lowStockThresholdDays,
      if (lastRefilledAt != null) 'last_refilled_at': lastRefilledAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? medicationId,
    Value<double>? remainingQuantity,
    Value<double>? packageQuantity,
    Value<double>? unitsPerDay,
    Value<String>? unitLabel,
    Value<int>? lowStockThresholdDays,
    Value<DateTime?>? lastRefilledAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InventoryRecordsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      medicationId: medicationId ?? this.medicationId,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      packageQuantity: packageQuantity ?? this.packageQuantity,
      unitsPerDay: unitsPerDay ?? this.unitsPerDay,
      unitLabel: unitLabel ?? this.unitLabel,
      lowStockThresholdDays:
          lowStockThresholdDays ?? this.lowStockThresholdDays,
      lastRefilledAt: lastRefilledAt ?? this.lastRefilledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (remainingQuantity.present) {
      map['remaining_quantity'] = Variable<double>(remainingQuantity.value);
    }
    if (packageQuantity.present) {
      map['package_quantity'] = Variable<double>(packageQuantity.value);
    }
    if (unitsPerDay.present) {
      map['units_per_day'] = Variable<double>(unitsPerDay.value);
    }
    if (unitLabel.present) {
      map['unit_label'] = Variable<String>(unitLabel.value);
    }
    if (lowStockThresholdDays.present) {
      map['low_stock_threshold_days'] = Variable<int>(
        lowStockThresholdDays.value,
      );
    }
    if (lastRefilledAt.present) {
      map['last_refilled_at'] = Variable<DateTime>(lastRefilledAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('remainingQuantity: $remainingQuantity, ')
          ..write('packageQuantity: $packageQuantity, ')
          ..write('unitsPerDay: $unitsPerDay, ')
          ..write('unitLabel: $unitLabel, ')
          ..write('lowStockThresholdDays: $lowStockThresholdDays, ')
          ..write('lastRefilledAt: $lastRefilledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefillEventsTable extends RefillEvents
    with TableInfo<$RefillEventsTable, RefillEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefillEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id)',
    ),
  );
  static const VerificationMeta _pharmacyIdMeta = const VerificationMeta(
    'pharmacyId',
  );
  @override
  late final GeneratedColumn<String> pharmacyId = GeneratedColumn<String>(
    'pharmacy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pharmacies (id)',
    ),
  );
  static const VerificationMeta _quantityAddedMeta = const VerificationMeta(
    'quantityAdded',
  );
  @override
  late final GeneratedColumn<double> quantityAdded = GeneratedColumn<double>(
    'quantity_added',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refilledAtMeta = const VerificationMeta(
    'refilledAt',
  );
  @override
  late final GeneratedColumn<DateTime> refilledAt = GeneratedColumn<DateTime>(
    'refilled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    medicationId,
    pharmacyId,
    quantityAdded,
    refilledAt,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refill_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefillEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('pharmacy_id')) {
      context.handle(
        _pharmacyIdMeta,
        pharmacyId.isAcceptableOrUnknown(data['pharmacy_id']!, _pharmacyIdMeta),
      );
    }
    if (data.containsKey('quantity_added')) {
      context.handle(
        _quantityAddedMeta,
        quantityAdded.isAcceptableOrUnknown(
          data['quantity_added']!,
          _quantityAddedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityAddedMeta);
    }
    if (data.containsKey('refilled_at')) {
      context.handle(
        _refilledAtMeta,
        refilledAt.isAcceptableOrUnknown(data['refilled_at']!, _refilledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_refilledAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefillEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefillEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      pharmacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pharmacy_id'],
      ),
      quantityAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_added'],
      )!,
      refilledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refilled_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RefillEventsTable createAlias(String alias) {
    return $RefillEventsTable(attachedDatabase, alias);
  }
}

class RefillEvent extends DataClass implements Insertable<RefillEvent> {
  final String id;
  final String memberId;
  final String medicationId;
  final String? pharmacyId;
  final double quantityAdded;
  final DateTime refilledAt;
  final String? note;
  final DateTime createdAt;
  const RefillEvent({
    required this.id,
    required this.memberId,
    required this.medicationId,
    this.pharmacyId,
    required this.quantityAdded,
    required this.refilledAt,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['medication_id'] = Variable<String>(medicationId);
    if (!nullToAbsent || pharmacyId != null) {
      map['pharmacy_id'] = Variable<String>(pharmacyId);
    }
    map['quantity_added'] = Variable<double>(quantityAdded);
    map['refilled_at'] = Variable<DateTime>(refilledAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RefillEventsCompanion toCompanion(bool nullToAbsent) {
    return RefillEventsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      medicationId: Value(medicationId),
      pharmacyId: pharmacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pharmacyId),
      quantityAdded: Value(quantityAdded),
      refilledAt: Value(refilledAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory RefillEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefillEvent(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      pharmacyId: serializer.fromJson<String?>(json['pharmacyId']),
      quantityAdded: serializer.fromJson<double>(json['quantityAdded']),
      refilledAt: serializer.fromJson<DateTime>(json['refilledAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'medicationId': serializer.toJson<String>(medicationId),
      'pharmacyId': serializer.toJson<String?>(pharmacyId),
      'quantityAdded': serializer.toJson<double>(quantityAdded),
      'refilledAt': serializer.toJson<DateTime>(refilledAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RefillEvent copyWith({
    String? id,
    String? memberId,
    String? medicationId,
    Value<String?> pharmacyId = const Value.absent(),
    double? quantityAdded,
    DateTime? refilledAt,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => RefillEvent(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    medicationId: medicationId ?? this.medicationId,
    pharmacyId: pharmacyId.present ? pharmacyId.value : this.pharmacyId,
    quantityAdded: quantityAdded ?? this.quantityAdded,
    refilledAt: refilledAt ?? this.refilledAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  RefillEvent copyWithCompanion(RefillEventsCompanion data) {
    return RefillEvent(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      pharmacyId: data.pharmacyId.present
          ? data.pharmacyId.value
          : this.pharmacyId,
      quantityAdded: data.quantityAdded.present
          ? data.quantityAdded.value
          : this.quantityAdded,
      refilledAt: data.refilledAt.present
          ? data.refilledAt.value
          : this.refilledAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefillEvent(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('pharmacyId: $pharmacyId, ')
          ..write('quantityAdded: $quantityAdded, ')
          ..write('refilledAt: $refilledAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    medicationId,
    pharmacyId,
    quantityAdded,
    refilledAt,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefillEvent &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.medicationId == this.medicationId &&
          other.pharmacyId == this.pharmacyId &&
          other.quantityAdded == this.quantityAdded &&
          other.refilledAt == this.refilledAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class RefillEventsCompanion extends UpdateCompanion<RefillEvent> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> medicationId;
  final Value<String?> pharmacyId;
  final Value<double> quantityAdded;
  final Value<DateTime> refilledAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RefillEventsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.pharmacyId = const Value.absent(),
    this.quantityAdded = const Value.absent(),
    this.refilledAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefillEventsCompanion.insert({
    required String id,
    required String memberId,
    required String medicationId,
    this.pharmacyId = const Value.absent(),
    required double quantityAdded,
    required DateTime refilledAt,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       medicationId = Value(medicationId),
       quantityAdded = Value(quantityAdded),
       refilledAt = Value(refilledAt),
       createdAt = Value(createdAt);
  static Insertable<RefillEvent> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? medicationId,
    Expression<String>? pharmacyId,
    Expression<double>? quantityAdded,
    Expression<DateTime>? refilledAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (medicationId != null) 'medication_id': medicationId,
      if (pharmacyId != null) 'pharmacy_id': pharmacyId,
      if (quantityAdded != null) 'quantity_added': quantityAdded,
      if (refilledAt != null) 'refilled_at': refilledAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefillEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? medicationId,
    Value<String?>? pharmacyId,
    Value<double>? quantityAdded,
    Value<DateTime>? refilledAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RefillEventsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      medicationId: medicationId ?? this.medicationId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      quantityAdded: quantityAdded ?? this.quantityAdded,
      refilledAt: refilledAt ?? this.refilledAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (pharmacyId.present) {
      map['pharmacy_id'] = Variable<String>(pharmacyId.value);
    }
    if (quantityAdded.present) {
      map['quantity_added'] = Variable<double>(quantityAdded.value);
    }
    if (refilledAt.present) {
      map['refilled_at'] = Variable<DateTime>(refilledAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefillEventsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('pharmacyId: $pharmacyId, ')
          ..write('quantityAdded: $quantityAdded, ')
          ..write('refilledAt: $refilledAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VitalEntriesTable extends VitalEntries
    with TableInfo<$VitalEntriesTable, VitalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _vitalTypeMeta = const VerificationMeta(
    'vitalType',
  );
  @override
  late final GeneratedColumn<String> vitalType = GeneratedColumn<String>(
    'vital_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryValueMeta = const VerificationMeta(
    'primaryValue',
  );
  @override
  late final GeneratedColumn<double> primaryValue = GeneratedColumn<double>(
    'primary_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondaryValueMeta = const VerificationMeta(
    'secondaryValue',
  );
  @override
  late final GeneratedColumn<double> secondaryValue = GeneratedColumn<double>(
    'secondary_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pulseMeta = const VerificationMeta('pulse');
  @override
  late final GeneratedColumn<double> pulse = GeneratedColumn<double>(
    'pulse',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    vitalType,
    primaryValue,
    secondaryValue,
    pulse,
    unit,
    recordedAt,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vital_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VitalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('vital_type')) {
      context.handle(
        _vitalTypeMeta,
        vitalType.isAcceptableOrUnknown(data['vital_type']!, _vitalTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_vitalTypeMeta);
    }
    if (data.containsKey('primary_value')) {
      context.handle(
        _primaryValueMeta,
        primaryValue.isAcceptableOrUnknown(
          data['primary_value']!,
          _primaryValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryValueMeta);
    }
    if (data.containsKey('secondary_value')) {
      context.handle(
        _secondaryValueMeta,
        secondaryValue.isAcceptableOrUnknown(
          data['secondary_value']!,
          _secondaryValueMeta,
        ),
      );
    }
    if (data.containsKey('pulse')) {
      context.handle(
        _pulseMeta,
        pulse.isAcceptableOrUnknown(data['pulse']!, _pulseMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VitalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VitalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      vitalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vital_type'],
      )!,
      primaryValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}primary_value'],
      )!,
      secondaryValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}secondary_value'],
      ),
      pulse: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pulse'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VitalEntriesTable createAlias(String alias) {
    return $VitalEntriesTable(attachedDatabase, alias);
  }
}

class VitalEntry extends DataClass implements Insertable<VitalEntry> {
  final String id;
  final String memberId;

  /// bloodPressure / bloodGlucose / weight / heartRate
  final String vitalType;
  final double primaryValue;

  /// BP diastolic etc.
  final double? secondaryValue;

  /// BP ke saath optional pulse.
  final double? pulse;
  final String unit;
  final DateTime recordedAt;
  final String? note;
  final DateTime createdAt;
  const VitalEntry({
    required this.id,
    required this.memberId,
    required this.vitalType,
    required this.primaryValue,
    this.secondaryValue,
    this.pulse,
    required this.unit,
    required this.recordedAt,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['vital_type'] = Variable<String>(vitalType);
    map['primary_value'] = Variable<double>(primaryValue);
    if (!nullToAbsent || secondaryValue != null) {
      map['secondary_value'] = Variable<double>(secondaryValue);
    }
    if (!nullToAbsent || pulse != null) {
      map['pulse'] = Variable<double>(pulse);
    }
    map['unit'] = Variable<String>(unit);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VitalEntriesCompanion toCompanion(bool nullToAbsent) {
    return VitalEntriesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      vitalType: Value(vitalType),
      primaryValue: Value(primaryValue),
      secondaryValue: secondaryValue == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryValue),
      pulse: pulse == null && nullToAbsent
          ? const Value.absent()
          : Value(pulse),
      unit: Value(unit),
      recordedAt: Value(recordedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory VitalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VitalEntry(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      vitalType: serializer.fromJson<String>(json['vitalType']),
      primaryValue: serializer.fromJson<double>(json['primaryValue']),
      secondaryValue: serializer.fromJson<double?>(json['secondaryValue']),
      pulse: serializer.fromJson<double?>(json['pulse']),
      unit: serializer.fromJson<String>(json['unit']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'vitalType': serializer.toJson<String>(vitalType),
      'primaryValue': serializer.toJson<double>(primaryValue),
      'secondaryValue': serializer.toJson<double?>(secondaryValue),
      'pulse': serializer.toJson<double?>(pulse),
      'unit': serializer.toJson<String>(unit),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VitalEntry copyWith({
    String? id,
    String? memberId,
    String? vitalType,
    double? primaryValue,
    Value<double?> secondaryValue = const Value.absent(),
    Value<double?> pulse = const Value.absent(),
    String? unit,
    DateTime? recordedAt,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => VitalEntry(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    vitalType: vitalType ?? this.vitalType,
    primaryValue: primaryValue ?? this.primaryValue,
    secondaryValue: secondaryValue.present
        ? secondaryValue.value
        : this.secondaryValue,
    pulse: pulse.present ? pulse.value : this.pulse,
    unit: unit ?? this.unit,
    recordedAt: recordedAt ?? this.recordedAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  VitalEntry copyWithCompanion(VitalEntriesCompanion data) {
    return VitalEntry(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      vitalType: data.vitalType.present ? data.vitalType.value : this.vitalType,
      primaryValue: data.primaryValue.present
          ? data.primaryValue.value
          : this.primaryValue,
      secondaryValue: data.secondaryValue.present
          ? data.secondaryValue.value
          : this.secondaryValue,
      pulse: data.pulse.present ? data.pulse.value : this.pulse,
      unit: data.unit.present ? data.unit.value : this.unit,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VitalEntry(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('vitalType: $vitalType, ')
          ..write('primaryValue: $primaryValue, ')
          ..write('secondaryValue: $secondaryValue, ')
          ..write('pulse: $pulse, ')
          ..write('unit: $unit, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    vitalType,
    primaryValue,
    secondaryValue,
    pulse,
    unit,
    recordedAt,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VitalEntry &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.vitalType == this.vitalType &&
          other.primaryValue == this.primaryValue &&
          other.secondaryValue == this.secondaryValue &&
          other.pulse == this.pulse &&
          other.unit == this.unit &&
          other.recordedAt == this.recordedAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class VitalEntriesCompanion extends UpdateCompanion<VitalEntry> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> vitalType;
  final Value<double> primaryValue;
  final Value<double?> secondaryValue;
  final Value<double?> pulse;
  final Value<String> unit;
  final Value<DateTime> recordedAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VitalEntriesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.vitalType = const Value.absent(),
    this.primaryValue = const Value.absent(),
    this.secondaryValue = const Value.absent(),
    this.pulse = const Value.absent(),
    this.unit = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VitalEntriesCompanion.insert({
    required String id,
    required String memberId,
    required String vitalType,
    required double primaryValue,
    this.secondaryValue = const Value.absent(),
    this.pulse = const Value.absent(),
    required String unit,
    required DateTime recordedAt,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       vitalType = Value(vitalType),
       primaryValue = Value(primaryValue),
       unit = Value(unit),
       recordedAt = Value(recordedAt),
       createdAt = Value(createdAt);
  static Insertable<VitalEntry> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? vitalType,
    Expression<double>? primaryValue,
    Expression<double>? secondaryValue,
    Expression<double>? pulse,
    Expression<String>? unit,
    Expression<DateTime>? recordedAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (vitalType != null) 'vital_type': vitalType,
      if (primaryValue != null) 'primary_value': primaryValue,
      if (secondaryValue != null) 'secondary_value': secondaryValue,
      if (pulse != null) 'pulse': pulse,
      if (unit != null) 'unit': unit,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VitalEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? vitalType,
    Value<double>? primaryValue,
    Value<double?>? secondaryValue,
    Value<double?>? pulse,
    Value<String>? unit,
    Value<DateTime>? recordedAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VitalEntriesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      vitalType: vitalType ?? this.vitalType,
      primaryValue: primaryValue ?? this.primaryValue,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      pulse: pulse ?? this.pulse,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (vitalType.present) {
      map['vital_type'] = Variable<String>(vitalType.value);
    }
    if (primaryValue.present) {
      map['primary_value'] = Variable<double>(primaryValue.value);
    }
    if (secondaryValue.present) {
      map['secondary_value'] = Variable<double>(secondaryValue.value);
    }
    if (pulse.present) {
      map['pulse'] = Variable<double>(pulse.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VitalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('vitalType: $vitalType, ')
          ..write('primaryValue: $primaryValue, ')
          ..write('secondaryValue: $secondaryValue, ')
          ..write('pulse: $pulse, ')
          ..write('unit: $unit, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MembersTable members = $MembersTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $MedicationSchedulesTable medicationSchedules =
      $MedicationSchedulesTable(this);
  late final $DoseEventsTable doseEvents = $DoseEventsTable(this);
  late final $PharmaciesTable pharmacies = $PharmaciesTable(this);
  late final $InventoryRecordsTable inventoryRecords = $InventoryRecordsTable(
    this,
  );
  late final $RefillEventsTable refillEvents = $RefillEventsTable(this);
  late final $VitalEntriesTable vitalEntries = $VitalEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    members,
    medications,
    medicationSchedules,
    doseEvents,
    pharmacies,
    inventoryRecords,
    refillEvents,
    vitalEntries,
  ];
}

typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  Value<String?> accountId,
  required String displayName,
  Value<String?> relationship,
  Value<String?> profileImagePath,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String?> accountId,
  Value<String> displayName,
  Value<String?> relationship,
  Value<String?> profileImagePath,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, Member> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MedicationsTable, List<Medication>>
  _medicationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.medications,
    aliasName: 'members__id__medications__member_id',
  );

  $$MedicationsTableProcessedTableManager get medicationsRefs {
    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_medicationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MedicationSchedulesTable,
    List<MedicationSchedule>
  >
  _medicationSchedulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationSchedules,
        aliasName: 'members__id__medication_schedules__member_id',
      );

  $$MedicationSchedulesTableProcessedTableManager get medicationSchedulesRefs {
    final manager = $$MedicationSchedulesTableTableManager(
      $_db,
      $_db.medicationSchedules,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationSchedulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DoseEventsTable, List<DoseEvent>>
  _doseEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.doseEvents,
    aliasName: 'members__id__dose_events__member_id',
  );

  $$DoseEventsTableProcessedTableManager get doseEventsRefs {
    final manager = $$DoseEventsTableTableManager(
      $_db,
      $_db.doseEvents,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_doseEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PharmaciesTable, List<Pharmacy>>
  _pharmaciesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pharmacies,
    aliasName: 'members__id__pharmacies__member_id',
  );

  $$PharmaciesTableProcessedTableManager get pharmaciesRefs {
    final manager = $$PharmaciesTableTableManager(
      $_db,
      $_db.pharmacies,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pharmaciesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InventoryRecordsTable, List<InventoryRecord>>
  _inventoryRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryRecords,
    aliasName: 'members__id__inventory_records__member_id',
  );

  $$InventoryRecordsTableProcessedTableManager get inventoryRecordsRefs {
    final manager = $$InventoryRecordsTableTableManager(
      $_db,
      $_db.inventoryRecords,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoryRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RefillEventsTable, List<RefillEvent>>
  _refillEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.refillEvents,
    aliasName: 'members__id__refill_events__member_id',
  );

  $$RefillEventsTableProcessedTableManager get refillEventsRefs {
    final manager = $$RefillEventsTableTableManager(
      $_db,
      $_db.refillEvents,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_refillEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VitalEntriesTable, List<VitalEntry>>
  _vitalEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.vitalEntries,
    aliasName: 'members__id__vital_entries__member_id',
  );

  $$VitalEntriesTableProcessedTableManager get vitalEntriesRefs {
    final manager = $$VitalEntriesTableTableManager(
      $_db,
      $_db.vitalEntries,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vitalEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileImagePath => $composableBuilder(
    column: $table.profileImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> medicationsRefs(
    Expression<bool> Function($$MedicationsTableFilterComposer f) f,
  ) {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> medicationSchedulesRefs(
    Expression<bool> Function($$MedicationSchedulesTableFilterComposer f) f,
  ) {
    final $$MedicationSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationSchedules,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.medicationSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> doseEventsRefs(
    Expression<bool> Function($$DoseEventsTableFilterComposer f) f,
  ) {
    final $$DoseEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableFilterComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pharmaciesRefs(
    Expression<bool> Function($$PharmaciesTableFilterComposer f) f,
  ) {
    final $$PharmaciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pharmacies,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PharmaciesTableFilterComposer(
            $db: $db,
            $table: $db.pharmacies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryRecordsRefs(
    Expression<bool> Function($$InventoryRecordsTableFilterComposer f) f,
  ) {
    final $$InventoryRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryRecordsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> refillEventsRefs(
    Expression<bool> Function($$RefillEventsTableFilterComposer f) f,
  ) {
    final $$RefillEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refillEvents,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefillEventsTableFilterComposer(
            $db: $db,
            $table: $db.refillEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> vitalEntriesRefs(
    Expression<bool> Function($$VitalEntriesTableFilterComposer f) f,
  ) {
    final $$VitalEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vitalEntries,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VitalEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vitalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileImagePath => $composableBuilder(
    column: $table.profileImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profileImagePath => $composableBuilder(
    column: $table.profileImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> medicationsRefs<T extends Object>(
    Expression<T> Function($$MedicationsTableAnnotationComposer a) f,
  ) {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> medicationSchedulesRefs<T extends Object>(
    Expression<T> Function($$MedicationSchedulesTableAnnotationComposer a) f,
  ) {
    final $$MedicationSchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationSchedules,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationSchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> doseEventsRefs<T extends Object>(
    Expression<T> Function($$DoseEventsTableAnnotationComposer a) f,
  ) {
    final $$DoseEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pharmaciesRefs<T extends Object>(
    Expression<T> Function($$PharmaciesTableAnnotationComposer a) f,
  ) {
    final $$PharmaciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pharmacies,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PharmaciesTableAnnotationComposer(
            $db: $db,
            $table: $db.pharmacies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inventoryRecordsRefs<T extends Object>(
    Expression<T> Function($$InventoryRecordsTableAnnotationComposer a) f,
  ) {
    final $$InventoryRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> refillEventsRefs<T extends Object>(
    Expression<T> Function($$RefillEventsTableAnnotationComposer a) f,
  ) {
    final $$RefillEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refillEvents,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefillEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.refillEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> vitalEntriesRefs<T extends Object>(
    Expression<T> Function($$VitalEntriesTableAnnotationComposer a) f,
  ) {
    final $$VitalEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vitalEntries,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VitalEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.vitalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          Member,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (Member, $$MembersTableReferences),
          Member,
          PrefetchHooks Function({
            bool medicationsRefs,
            bool medicationSchedulesRefs,
            bool doseEventsRefs,
            bool pharmaciesRefs,
            bool inventoryRecordsRefs,
            bool refillEventsRefs,
            bool vitalEntriesRefs,
          })
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> relationship = const Value.absent(),
                Value<String?> profileImagePath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                accountId: accountId,
                displayName: displayName,
                relationship: relationship,
                profileImagePath: profileImagePath,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> accountId = const Value.absent(),
                required String displayName,
                Value<String?> relationship = const Value.absent(),
                Value<String?> profileImagePath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                accountId: accountId,
                displayName: displayName,
                relationship: relationship,
                profileImagePath: profileImagePath,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembersTable, Member>(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                medicationsRefs = false,
                medicationSchedulesRefs = false,
                doseEventsRefs = false,
                pharmaciesRefs = false,
                inventoryRecordsRefs = false,
                refillEventsRefs = false,
                vitalEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (medicationsRefs) db.medications,
                    if (medicationSchedulesRefs) db.medicationSchedules,
                    if (doseEventsRefs) db.doseEvents,
                    if (pharmaciesRefs) db.pharmacies,
                    if (inventoryRecordsRefs) db.inventoryRecords,
                    if (refillEventsRefs) db.refillEvents,
                    if (vitalEntriesRefs) db.vitalEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (medicationsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          Medication
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._medicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (medicationSchedulesRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          MedicationSchedule
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._medicationSchedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationSchedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (doseEventsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          DoseEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._doseEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).doseEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pharmaciesRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          Pharmacy
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._pharmaciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).pharmaciesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoryRecordsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          InventoryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._inventoryRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (refillEventsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          RefillEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._refillEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).refillEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (vitalEntriesRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          VitalEntry
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._vitalEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).vitalEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      Member,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (Member, $$MembersTableReferences),
      Member,
      PrefetchHooks Function({
        bool medicationsRefs,
        bool medicationSchedulesRefs,
        bool doseEventsRefs,
        bool pharmaciesRefs,
        bool inventoryRecordsRefs,
        bool refillEventsRefs,
        bool vitalEntriesRefs,
      })
    >;
typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      required String id,
      required String memberId,
      required String name,
      required String strength,
      Value<String?> strengthUnit,
      Value<String?> medicineForm,
      Value<String?> colorName,
      Value<String?> instructions,
      Value<String?> imagePath,
      Value<String?> linkedPharmacyId,
      Value<bool> isActive,
      Value<DateTime?> discontinuedAt,
      Value<String?> discontinuedReason,
      Value<int?> courseDay,
      Value<int?> courseTotalDays,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> name,
      Value<String> strength,
      Value<String?> strengthUnit,
      Value<String?> medicineForm,
      Value<String?> colorName,
      Value<String?> instructions,
      Value<String?> imagePath,
      Value<String?> linkedPharmacyId,
      Value<bool> isActive,
      Value<DateTime?> discontinuedAt,
      Value<String?> discontinuedReason,
      Value<int?> courseDay,
      Value<int?> courseTotalDays,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MedicationsTableReferences
    extends BaseReferences<_$AppDatabase, $MedicationsTable, Medication> {
  $$MedicationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('medications__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MedicationSchedulesTable,
    List<MedicationSchedule>
  >
  _medicationSchedulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationSchedules,
        aliasName: 'medications__id__medication_schedules__medication_id',
      );

  $$MedicationSchedulesTableProcessedTableManager get medicationSchedulesRefs {
    final manager = $$MedicationSchedulesTableTableManager(
      $_db,
      $_db.medicationSchedules,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationSchedulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DoseEventsTable, List<DoseEvent>>
  _doseEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.doseEvents,
    aliasName: 'medications__id__dose_events__medication_id',
  );

  $$DoseEventsTableProcessedTableManager get doseEventsRefs {
    final manager = $$DoseEventsTableTableManager(
      $_db,
      $_db.doseEvents,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_doseEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InventoryRecordsTable, List<InventoryRecord>>
  _inventoryRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryRecords,
    aliasName: 'medications__id__inventory_records__medication_id',
  );

  $$InventoryRecordsTableProcessedTableManager get inventoryRecordsRefs {
    final manager = $$InventoryRecordsTableTableManager(
      $_db,
      $_db.inventoryRecords,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoryRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RefillEventsTable, List<RefillEvent>>
  _refillEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.refillEvents,
    aliasName: 'medications__id__refill_events__medication_id',
  );

  $$RefillEventsTableProcessedTableManager get refillEventsRefs {
    final manager = $$RefillEventsTableTableManager(
      $_db,
      $_db.refillEvents,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_refillEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strengthUnit => $composableBuilder(
    column: $table.strengthUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicineForm => $composableBuilder(
    column: $table.medicineForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorName => $composableBuilder(
    column: $table.colorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedPharmacyId => $composableBuilder(
    column: $table.linkedPharmacyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get discontinuedAt => $composableBuilder(
    column: $table.discontinuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discontinuedReason => $composableBuilder(
    column: $table.discontinuedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get courseDay => $composableBuilder(
    column: $table.courseDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get courseTotalDays => $composableBuilder(
    column: $table.courseTotalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> medicationSchedulesRefs(
    Expression<bool> Function($$MedicationSchedulesTableFilterComposer f) f,
  ) {
    final $$MedicationSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationSchedules,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.medicationSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> doseEventsRefs(
    Expression<bool> Function($$DoseEventsTableFilterComposer f) f,
  ) {
    final $$DoseEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableFilterComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryRecordsRefs(
    Expression<bool> Function($$InventoryRecordsTableFilterComposer f) f,
  ) {
    final $$InventoryRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryRecords,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryRecordsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> refillEventsRefs(
    Expression<bool> Function($$RefillEventsTableFilterComposer f) f,
  ) {
    final $$RefillEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refillEvents,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefillEventsTableFilterComposer(
            $db: $db,
            $table: $db.refillEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strengthUnit => $composableBuilder(
    column: $table.strengthUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicineForm => $composableBuilder(
    column: $table.medicineForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorName => $composableBuilder(
    column: $table.colorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedPharmacyId => $composableBuilder(
    column: $table.linkedPharmacyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get discontinuedAt => $composableBuilder(
    column: $table.discontinuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discontinuedReason => $composableBuilder(
    column: $table.discontinuedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get courseDay => $composableBuilder(
    column: $table.courseDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get courseTotalDays => $composableBuilder(
    column: $table.courseTotalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<String> get strengthUnit => $composableBuilder(
    column: $table.strengthUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicineForm => $composableBuilder(
    column: $table.medicineForm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorName =>
      $composableBuilder(column: $table.colorName, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get linkedPharmacyId => $composableBuilder(
    column: $table.linkedPharmacyId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get discontinuedAt => $composableBuilder(
    column: $table.discontinuedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discontinuedReason => $composableBuilder(
    column: $table.discontinuedReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get courseDay =>
      $composableBuilder(column: $table.courseDay, builder: (column) => column);

  GeneratedColumn<int> get courseTotalDays => $composableBuilder(
    column: $table.courseTotalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> medicationSchedulesRefs<T extends Object>(
    Expression<T> Function($$MedicationSchedulesTableAnnotationComposer a) f,
  ) {
    final $$MedicationSchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationSchedules,
          getReferencedColumn: (t) => t.medicationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationSchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> doseEventsRefs<T extends Object>(
    Expression<T> Function($$DoseEventsTableAnnotationComposer a) f,
  ) {
    final $$DoseEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inventoryRecordsRefs<T extends Object>(
    Expression<T> Function($$InventoryRecordsTableAnnotationComposer a) f,
  ) {
    final $$InventoryRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryRecords,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> refillEventsRefs<T extends Object>(
    Expression<T> Function($$RefillEventsTableAnnotationComposer a) f,
  ) {
    final $$RefillEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refillEvents,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefillEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.refillEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          Medication,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (Medication, $$MedicationsTableReferences),
          Medication,
          PrefetchHooks Function({
            bool memberId,
            bool medicationSchedulesRefs,
            bool doseEventsRefs,
            bool inventoryRecordsRefs,
            bool refillEventsRefs,
          })
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> strength = const Value.absent(),
                Value<String?> strengthUnit = const Value.absent(),
                Value<String?> medicineForm = const Value.absent(),
                Value<String?> colorName = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> linkedPharmacyId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> discontinuedAt = const Value.absent(),
                Value<String?> discontinuedReason = const Value.absent(),
                Value<int?> courseDay = const Value.absent(),
                Value<int?> courseTotalDays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                memberId: memberId,
                name: name,
                strength: strength,
                strengthUnit: strengthUnit,
                medicineForm: medicineForm,
                colorName: colorName,
                instructions: instructions,
                imagePath: imagePath,
                linkedPharmacyId: linkedPharmacyId,
                isActive: isActive,
                discontinuedAt: discontinuedAt,
                discontinuedReason: discontinuedReason,
                courseDay: courseDay,
                courseTotalDays: courseTotalDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String name,
                required String strength,
                Value<String?> strengthUnit = const Value.absent(),
                Value<String?> medicineForm = const Value.absent(),
                Value<String?> colorName = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> linkedPharmacyId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> discontinuedAt = const Value.absent(),
                Value<String?> discontinuedReason = const Value.absent(),
                Value<int?> courseDay = const Value.absent(),
                Value<int?> courseTotalDays = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                memberId: memberId,
                name: name,
                strength: strength,
                strengthUnit: strengthUnit,
                medicineForm: medicineForm,
                colorName: colorName,
                instructions: instructions,
                imagePath: imagePath,
                linkedPharmacyId: linkedPharmacyId,
                isActive: isActive,
                discontinuedAt: discontinuedAt,
                discontinuedReason: discontinuedReason,
                courseDay: courseDay,
                courseTotalDays: courseTotalDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MedicationsTable, Medication>(table),
                  $$MedicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                memberId = false,
                medicationSchedulesRefs = false,
                doseEventsRefs = false,
                inventoryRecordsRefs = false,
                refillEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (medicationSchedulesRefs) db.medicationSchedules,
                    if (doseEventsRefs) db.doseEvents,
                    if (inventoryRecordsRefs) db.inventoryRecords,
                    if (refillEventsRefs) db.refillEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (memberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.memberId,
                            referencedTable: $$MedicationsTableReferences
                                ._memberIdTable(db),
                            referencedColumn: $$MedicationsTableReferences
                                ._memberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (medicationSchedulesRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          MedicationSchedule
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._medicationSchedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationSchedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (doseEventsRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          DoseEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._doseEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).doseEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoryRecordsRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          InventoryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._inventoryRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (refillEventsRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          RefillEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._refillEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).refillEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      Medication,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (Medication, $$MedicationsTableReferences),
      Medication,
      PrefetchHooks Function({
        bool memberId,
        bool medicationSchedulesRefs,
        bool doseEventsRefs,
        bool inventoryRecordsRefs,
        bool refillEventsRefs,
      })
    >;
typedef $$MedicationSchedulesTableCreateCompanionBuilder =
    MedicationSchedulesCompanion Function({
      required String id,
      required String medicationId,
      required String memberId,
      required String scheduleType,
      required String timeOfDay,
      Value<String?> daysOfWeek,
      Value<double> doseAmount,
      Value<String?> doseUnit,
      required DateTime startDate,
      Value<DateTime?> endDate,
      Value<bool> isEnabled,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MedicationSchedulesTableUpdateCompanionBuilder =
    MedicationSchedulesCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<String> memberId,
      Value<String> scheduleType,
      Value<String> timeOfDay,
      Value<String?> daysOfWeek,
      Value<double> doseAmount,
      Value<String?> doseUnit,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MedicationSchedulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MedicationSchedulesTable,
          MedicationSchedule
        > {
  $$MedicationSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) => db
      .medications
      .createAlias('medication_schedules__medication_id__medications__id');

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('medication_schedules__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DoseEventsTable, List<DoseEvent>>
  _doseEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.doseEvents,
    aliasName: 'medication_schedules__id__dose_events__schedule_id',
  );

  $$DoseEventsTableProcessedTableManager get doseEventsRefs {
    final manager = $$DoseEventsTableTableManager(
      $_db,
      $_db.doseEvents,
    ).filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_doseEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationSchedulesTable> {
  $$MedicationSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> doseEventsRefs(
    Expression<bool> Function($$DoseEventsTableFilterComposer f) f,
  ) {
    final $$DoseEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableFilterComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationSchedulesTable> {
  $$MedicationSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationSchedulesTable> {
  $$MedicationSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scheduleType => $composableBuilder(
    column: $table.scheduleType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<double> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doseUnit =>
      $composableBuilder(column: $table.doseUnit, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> doseEventsRefs<T extends Object>(
    Expression<T> Function($$DoseEventsTableAnnotationComposer a) f,
  ) {
    final $$DoseEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseEvents,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DoseEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.doseEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationSchedulesTable,
          MedicationSchedule,
          $$MedicationSchedulesTableFilterComposer,
          $$MedicationSchedulesTableOrderingComposer,
          $$MedicationSchedulesTableAnnotationComposer,
          $$MedicationSchedulesTableCreateCompanionBuilder,
          $$MedicationSchedulesTableUpdateCompanionBuilder,
          (MedicationSchedule, $$MedicationSchedulesTableReferences),
          MedicationSchedule,
          PrefetchHooks Function({
            bool medicationId,
            bool memberId,
            bool doseEventsRefs,
          })
        > {
  $$MedicationSchedulesTableTableManager(
    _$AppDatabase db,
    $MedicationSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationSchedulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationSchedulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> scheduleType = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
                Value<String?> daysOfWeek = const Value.absent(),
                Value<double> doseAmount = const Value.absent(),
                Value<String?> doseUnit = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationSchedulesCompanion(
                id: id,
                medicationId: medicationId,
                memberId: memberId,
                scheduleType: scheduleType,
                timeOfDay: timeOfDay,
                daysOfWeek: daysOfWeek,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                startDate: startDate,
                endDate: endDate,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required String memberId,
                required String scheduleType,
                required String timeOfDay,
                Value<String?> daysOfWeek = const Value.absent(),
                Value<double> doseAmount = const Value.absent(),
                Value<String?> doseUnit = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MedicationSchedulesCompanion.insert(
                id: id,
                medicationId: medicationId,
                memberId: memberId,
                scheduleType: scheduleType,
                timeOfDay: timeOfDay,
                daysOfWeek: daysOfWeek,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                startDate: startDate,
                endDate: endDate,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MedicationSchedulesTable, MedicationSchedule>(
                    table,
                  ),
                  $$MedicationSchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                medicationId = false,
                memberId = false,
                doseEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (doseEventsRefs) db.doseEvents],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (medicationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.medicationId,
                            referencedTable:
                                $$MedicationSchedulesTableReferences
                                    ._medicationIdTable(db),
                            referencedColumn:
                                $$MedicationSchedulesTableReferences
                                    ._medicationIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (memberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.memberId,
                            referencedTable:
                                $$MedicationSchedulesTableReferences
                                    ._memberIdTable(db),
                            referencedColumn:
                                $$MedicationSchedulesTableReferences
                                    ._memberIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (doseEventsRefs)
                        await $_getPrefetchedData<
                          MedicationSchedule,
                          $MedicationSchedulesTable,
                          DoseEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationSchedulesTableReferences
                              ._doseEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationSchedulesTableReferences(
                                db,
                                table,
                                p0,
                              ).doseEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scheduleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationSchedulesTable,
      MedicationSchedule,
      $$MedicationSchedulesTableFilterComposer,
      $$MedicationSchedulesTableOrderingComposer,
      $$MedicationSchedulesTableAnnotationComposer,
      $$MedicationSchedulesTableCreateCompanionBuilder,
      $$MedicationSchedulesTableUpdateCompanionBuilder,
      (MedicationSchedule, $$MedicationSchedulesTableReferences),
      MedicationSchedule,
      PrefetchHooks Function({
        bool medicationId,
        bool memberId,
        bool doseEventsRefs,
      })
    >;
typedef $$DoseEventsTableCreateCompanionBuilder = DoseEventsCompanion Function({
  required String id,
  required String memberId,
  required String medicationId,
  Value<String?> scheduleId,
  required DateTime scheduledAt,
  required String status,
  Value<DateTime?> completedAt,
  Value<String?> missedReasonType,
  Value<String?> missedReasonText,
  Value<String?> note,
  Value<DateTime?> snoozedUntil,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DoseEventsTableUpdateCompanionBuilder = DoseEventsCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<String> medicationId,
  Value<String?> scheduleId,
  Value<DateTime> scheduledAt,
  Value<String> status,
  Value<DateTime?> completedAt,
  Value<String?> missedReasonType,
  Value<String?> missedReasonText,
  Value<String?> note,
  Value<DateTime?> snoozedUntil,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$DoseEventsTableReferences
    extends BaseReferences<_$AppDatabase, $DoseEventsTable, DoseEvent> {
  $$DoseEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('dose_events__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias('dose_events__medication_id__medications__id');

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MedicationSchedulesTable _scheduleIdTable(_$AppDatabase db) => db
      .medicationSchedules
      .createAlias('dose_events__schedule_id__medication_schedules__id');

  $$MedicationSchedulesTableProcessedTableManager? get scheduleId {
    final $_column = $_itemColumn<String>('schedule_id');
    if ($_column == null) return null;
    final manager = $$MedicationSchedulesTableTableManager(
      $_db,
      $_db.medicationSchedules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DoseEventsTableFilterComposer
    extends Composer<_$AppDatabase, $DoseEventsTable> {
  $$DoseEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missedReasonType => $composableBuilder(
    column: $table.missedReasonType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missedReasonText => $composableBuilder(
    column: $table.missedReasonText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationSchedulesTableFilterComposer get scheduleId {
    final $$MedicationSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.medicationSchedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.medicationSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DoseEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $DoseEventsTable> {
  $$DoseEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missedReasonType => $composableBuilder(
    column: $table.missedReasonType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missedReasonText => $composableBuilder(
    column: $table.missedReasonText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationSchedulesTableOrderingComposer get scheduleId {
    final $$MedicationSchedulesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleId,
          referencedTable: $db.medicationSchedules,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationSchedulesTableOrderingComposer(
                $db: $db,
                $table: $db.medicationSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DoseEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoseEventsTable> {
  $$DoseEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missedReasonType => $composableBuilder(
    column: $table.missedReasonType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missedReasonText => $composableBuilder(
    column: $table.missedReasonText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationSchedulesTableAnnotationComposer get scheduleId {
    final $$MedicationSchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleId,
          referencedTable: $db.medicationSchedules,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationSchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DoseEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DoseEventsTable,
          DoseEvent,
          $$DoseEventsTableFilterComposer,
          $$DoseEventsTableOrderingComposer,
          $$DoseEventsTableAnnotationComposer,
          $$DoseEventsTableCreateCompanionBuilder,
          $$DoseEventsTableUpdateCompanionBuilder,
          (DoseEvent, $$DoseEventsTableReferences),
          DoseEvent,
          PrefetchHooks Function({
            bool memberId,
            bool medicationId,
            bool scheduleId,
          })
        > {
  $$DoseEventsTableTableManager(_$AppDatabase db, $DoseEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoseEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoseEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoseEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String?> scheduleId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> missedReasonType = const Value.absent(),
                Value<String?> missedReasonText = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoseEventsCompanion(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                scheduleId: scheduleId,
                scheduledAt: scheduledAt,
                status: status,
                completedAt: completedAt,
                missedReasonType: missedReasonType,
                missedReasonText: missedReasonText,
                note: note,
                snoozedUntil: snoozedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String medicationId,
                Value<String?> scheduleId = const Value.absent(),
                required DateTime scheduledAt,
                required String status,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> missedReasonType = const Value.absent(),
                Value<String?> missedReasonText = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DoseEventsCompanion.insert(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                scheduleId: scheduleId,
                scheduledAt: scheduledAt,
                status: status,
                completedAt: completedAt,
                missedReasonType: missedReasonType,
                missedReasonText: missedReasonText,
                note: note,
                snoozedUntil: snoozedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DoseEventsTable, DoseEvent>(table),
                  $$DoseEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({memberId = false, medicationId = false, scheduleId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (memberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.memberId,
                            referencedTable: $$DoseEventsTableReferences
                                ._memberIdTable(db),
                            referencedColumn: $$DoseEventsTableReferences
                                ._memberIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (medicationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.medicationId,
                            referencedTable: $$DoseEventsTableReferences
                                ._medicationIdTable(db),
                            referencedColumn: $$DoseEventsTableReferences
                                ._medicationIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (scheduleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.scheduleId,
                            referencedTable: $$DoseEventsTableReferences
                                ._scheduleIdTable(db),
                            referencedColumn: $$DoseEventsTableReferences
                                ._scheduleIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$DoseEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DoseEventsTable,
      DoseEvent,
      $$DoseEventsTableFilterComposer,
      $$DoseEventsTableOrderingComposer,
      $$DoseEventsTableAnnotationComposer,
      $$DoseEventsTableCreateCompanionBuilder,
      $$DoseEventsTableUpdateCompanionBuilder,
      (DoseEvent, $$DoseEventsTableReferences),
      DoseEvent,
      PrefetchHooks Function({
        bool memberId,
        bool medicationId,
        bool scheduleId,
      })
    >;
typedef $$PharmaciesTableCreateCompanionBuilder = PharmaciesCompanion Function({
  required String id,
  required String memberId,
  required String name,
  Value<String?> address,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> website,
  Value<String?> hoursText,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<bool> isPreferred,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PharmaciesTableUpdateCompanionBuilder = PharmaciesCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<String> name,
  Value<String?> address,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> website,
  Value<String?> hoursText,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<bool> isPreferred,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$PharmaciesTableReferences
    extends BaseReferences<_$AppDatabase, $PharmaciesTable, Pharmacy> {
  $$PharmaciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('pharmacies__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RefillEventsTable, List<RefillEvent>>
  _refillEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.refillEvents,
    aliasName: 'pharmacies__id__refill_events__pharmacy_id',
  );

  $$RefillEventsTableProcessedTableManager get refillEventsRefs {
    final manager = $$RefillEventsTableTableManager(
      $_db,
      $_db.refillEvents,
    ).filter((f) => f.pharmacyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_refillEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PharmaciesTableFilterComposer
    extends Composer<_$AppDatabase, $PharmaciesTable> {
  $$PharmaciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hoursText => $composableBuilder(
    column: $table.hoursText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPreferred => $composableBuilder(
    column: $table.isPreferred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> refillEventsRefs(
    Expression<bool> Function($$RefillEventsTableFilterComposer f) f,
  ) {
    final $$RefillEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refillEvents,
      getReferencedColumn: (t) => t.pharmacyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefillEventsTableFilterComposer(
            $db: $db,
            $table: $db.refillEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PharmaciesTableOrderingComposer
    extends Composer<_$AppDatabase, $PharmaciesTable> {
  $$PharmaciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hoursText => $composableBuilder(
    column: $table.hoursText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPreferred => $composableBuilder(
    column: $table.isPreferred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PharmaciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PharmaciesTable> {
  $$PharmaciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<String> get hoursText =>
      $composableBuilder(column: $table.hoursText, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get isPreferred => $composableBuilder(
    column: $table.isPreferred,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> refillEventsRefs<T extends Object>(
    Expression<T> Function($$RefillEventsTableAnnotationComposer a) f,
  ) {
    final $$RefillEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refillEvents,
      getReferencedColumn: (t) => t.pharmacyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefillEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.refillEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PharmaciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PharmaciesTable,
          Pharmacy,
          $$PharmaciesTableFilterComposer,
          $$PharmaciesTableOrderingComposer,
          $$PharmaciesTableAnnotationComposer,
          $$PharmaciesTableCreateCompanionBuilder,
          $$PharmaciesTableUpdateCompanionBuilder,
          (Pharmacy, $$PharmaciesTableReferences),
          Pharmacy,
          PrefetchHooks Function({bool memberId, bool refillEventsRefs})
        > {
  $$PharmaciesTableTableManager(_$AppDatabase db, $PharmaciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PharmaciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PharmaciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PharmaciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> hoursText = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isPreferred = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PharmaciesCompanion(
                id: id,
                memberId: memberId,
                name: name,
                address: address,
                phone: phone,
                email: email,
                website: website,
                hoursText: hoursText,
                latitude: latitude,
                longitude: longitude,
                isPreferred: isPreferred,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String name,
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> hoursText = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isPreferred = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PharmaciesCompanion.insert(
                id: id,
                memberId: memberId,
                name: name,
                address: address,
                phone: phone,
                email: email,
                website: website,
                hoursText: hoursText,
                latitude: latitude,
                longitude: longitude,
                isPreferred: isPreferred,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PharmaciesTable, Pharmacy>(table),
                  $$PharmaciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({memberId = false, refillEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (refillEventsRefs) db.refillEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (memberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.memberId,
                            referencedTable: $$PharmaciesTableReferences
                                ._memberIdTable(db),
                            referencedColumn: $$PharmaciesTableReferences
                                ._memberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (refillEventsRefs)
                        await $_getPrefetchedData<
                          Pharmacy,
                          $PharmaciesTable,
                          RefillEvent
                        >(
                          currentTable: table,
                          referencedTable: $$PharmaciesTableReferences
                              ._refillEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PharmaciesTableReferences(
                                db,
                                table,
                                p0,
                              ).refillEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pharmacyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PharmaciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PharmaciesTable,
      Pharmacy,
      $$PharmaciesTableFilterComposer,
      $$PharmaciesTableOrderingComposer,
      $$PharmaciesTableAnnotationComposer,
      $$PharmaciesTableCreateCompanionBuilder,
      $$PharmaciesTableUpdateCompanionBuilder,
      (Pharmacy, $$PharmaciesTableReferences),
      Pharmacy,
      PrefetchHooks Function({bool memberId, bool refillEventsRefs})
    >;
typedef $$InventoryRecordsTableCreateCompanionBuilder =
    InventoryRecordsCompanion Function({
      required String id,
      required String memberId,
      required String medicationId,
      required double remainingQuantity,
      required double packageQuantity,
      required double unitsPerDay,
      required String unitLabel,
      Value<int> lowStockThresholdDays,
      Value<DateTime?> lastRefilledAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$InventoryRecordsTableUpdateCompanionBuilder =
    InventoryRecordsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> medicationId,
      Value<double> remainingQuantity,
      Value<double> packageQuantity,
      Value<double> unitsPerDay,
      Value<String> unitLabel,
      Value<int> lowStockThresholdDays,
      Value<DateTime?> lastRefilledAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InventoryRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InventoryRecordsTable, InventoryRecord> {
  $$InventoryRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('inventory_records__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) => db
      .medications
      .createAlias('inventory_records__medication_id__medications__id');

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InventoryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryRecordsTable> {
  $$InventoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingQuantity => $composableBuilder(
    column: $table.remainingQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get packageQuantity => $composableBuilder(
    column: $table.packageQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitsPerDay => $composableBuilder(
    column: $table.unitsPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitLabel => $composableBuilder(
    column: $table.unitLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowStockThresholdDays => $composableBuilder(
    column: $table.lowStockThresholdDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRefilledAt => $composableBuilder(
    column: $table.lastRefilledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryRecordsTable> {
  $$InventoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingQuantity => $composableBuilder(
    column: $table.remainingQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get packageQuantity => $composableBuilder(
    column: $table.packageQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitsPerDay => $composableBuilder(
    column: $table.unitsPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitLabel => $composableBuilder(
    column: $table.unitLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockThresholdDays => $composableBuilder(
    column: $table.lowStockThresholdDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRefilledAt => $composableBuilder(
    column: $table.lastRefilledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryRecordsTable> {
  $$InventoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get remainingQuantity => $composableBuilder(
    column: $table.remainingQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get packageQuantity => $composableBuilder(
    column: $table.packageQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitsPerDay => $composableBuilder(
    column: $table.unitsPerDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitLabel =>
      $composableBuilder(column: $table.unitLabel, builder: (column) => column);

  GeneratedColumn<int> get lowStockThresholdDays => $composableBuilder(
    column: $table.lowStockThresholdDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRefilledAt => $composableBuilder(
    column: $table.lastRefilledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryRecordsTable,
          InventoryRecord,
          $$InventoryRecordsTableFilterComposer,
          $$InventoryRecordsTableOrderingComposer,
          $$InventoryRecordsTableAnnotationComposer,
          $$InventoryRecordsTableCreateCompanionBuilder,
          $$InventoryRecordsTableUpdateCompanionBuilder,
          (InventoryRecord, $$InventoryRecordsTableReferences),
          InventoryRecord,
          PrefetchHooks Function({bool memberId, bool medicationId})
        > {
  $$InventoryRecordsTableTableManager(
    _$AppDatabase db,
    $InventoryRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<double> remainingQuantity = const Value.absent(),
                Value<double> packageQuantity = const Value.absent(),
                Value<double> unitsPerDay = const Value.absent(),
                Value<String> unitLabel = const Value.absent(),
                Value<int> lowStockThresholdDays = const Value.absent(),
                Value<DateTime?> lastRefilledAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryRecordsCompanion(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                remainingQuantity: remainingQuantity,
                packageQuantity: packageQuantity,
                unitsPerDay: unitsPerDay,
                unitLabel: unitLabel,
                lowStockThresholdDays: lowStockThresholdDays,
                lastRefilledAt: lastRefilledAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String medicationId,
                required double remainingQuantity,
                required double packageQuantity,
                required double unitsPerDay,
                required String unitLabel,
                Value<int> lowStockThresholdDays = const Value.absent(),
                Value<DateTime?> lastRefilledAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InventoryRecordsCompanion.insert(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                remainingQuantity: remainingQuantity,
                packageQuantity: packageQuantity,
                unitsPerDay: unitsPerDay,
                unitLabel: unitLabel,
                lowStockThresholdDays: lowStockThresholdDays,
                lastRefilledAt: lastRefilledAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InventoryRecordsTable, InventoryRecord>(table),
                  $$InventoryRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false, medicationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $$InventoryRecordsTableReferences
                            ._memberIdTable(db),
                        referencedColumn: $$InventoryRecordsTableReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (medicationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.medicationId,
                        referencedTable: $$InventoryRecordsTableReferences
                            ._medicationIdTable(db),
                        referencedColumn: $$InventoryRecordsTableReferences
                            ._medicationIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InventoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryRecordsTable,
      InventoryRecord,
      $$InventoryRecordsTableFilterComposer,
      $$InventoryRecordsTableOrderingComposer,
      $$InventoryRecordsTableAnnotationComposer,
      $$InventoryRecordsTableCreateCompanionBuilder,
      $$InventoryRecordsTableUpdateCompanionBuilder,
      (InventoryRecord, $$InventoryRecordsTableReferences),
      InventoryRecord,
      PrefetchHooks Function({bool memberId, bool medicationId})
    >;
typedef $$RefillEventsTableCreateCompanionBuilder =
    RefillEventsCompanion Function({
      required String id,
      required String memberId,
      required String medicationId,
      Value<String?> pharmacyId,
      required double quantityAdded,
      required DateTime refilledAt,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$RefillEventsTableUpdateCompanionBuilder =
    RefillEventsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> medicationId,
      Value<String?> pharmacyId,
      Value<double> quantityAdded,
      Value<DateTime> refilledAt,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$RefillEventsTableReferences
    extends BaseReferences<_$AppDatabase, $RefillEventsTable, RefillEvent> {
  $$RefillEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('refill_events__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) => db
      .medications
      .createAlias('refill_events__medication_id__medications__id');

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PharmaciesTable _pharmacyIdTable(_$AppDatabase db) =>
      db.pharmacies.createAlias('refill_events__pharmacy_id__pharmacies__id');

  $$PharmaciesTableProcessedTableManager? get pharmacyId {
    final $_column = $_itemColumn<String>('pharmacy_id');
    if ($_column == null) return null;
    final manager = $$PharmaciesTableTableManager(
      $_db,
      $_db.pharmacies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pharmacyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RefillEventsTableFilterComposer
    extends Composer<_$AppDatabase, $RefillEventsTable> {
  $$RefillEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityAdded => $composableBuilder(
    column: $table.quantityAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refilledAt => $composableBuilder(
    column: $table.refilledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PharmaciesTableFilterComposer get pharmacyId {
    final $$PharmaciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pharmacyId,
      referencedTable: $db.pharmacies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PharmaciesTableFilterComposer(
            $db: $db,
            $table: $db.pharmacies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefillEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefillEventsTable> {
  $$RefillEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityAdded => $composableBuilder(
    column: $table.quantityAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refilledAt => $composableBuilder(
    column: $table.refilledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PharmaciesTableOrderingComposer get pharmacyId {
    final $$PharmaciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pharmacyId,
      referencedTable: $db.pharmacies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PharmaciesTableOrderingComposer(
            $db: $db,
            $table: $db.pharmacies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefillEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefillEventsTable> {
  $$RefillEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantityAdded => $composableBuilder(
    column: $table.quantityAdded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get refilledAt => $composableBuilder(
    column: $table.refilledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PharmaciesTableAnnotationComposer get pharmacyId {
    final $$PharmaciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pharmacyId,
      referencedTable: $db.pharmacies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PharmaciesTableAnnotationComposer(
            $db: $db,
            $table: $db.pharmacies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefillEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefillEventsTable,
          RefillEvent,
          $$RefillEventsTableFilterComposer,
          $$RefillEventsTableOrderingComposer,
          $$RefillEventsTableAnnotationComposer,
          $$RefillEventsTableCreateCompanionBuilder,
          $$RefillEventsTableUpdateCompanionBuilder,
          (RefillEvent, $$RefillEventsTableReferences),
          RefillEvent,
          PrefetchHooks Function({
            bool memberId,
            bool medicationId,
            bool pharmacyId,
          })
        > {
  $$RefillEventsTableTableManager(_$AppDatabase db, $RefillEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefillEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefillEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefillEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String?> pharmacyId = const Value.absent(),
                Value<double> quantityAdded = const Value.absent(),
                Value<DateTime> refilledAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefillEventsCompanion(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                pharmacyId: pharmacyId,
                quantityAdded: quantityAdded,
                refilledAt: refilledAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String medicationId,
                Value<String?> pharmacyId = const Value.absent(),
                required double quantityAdded,
                required DateTime refilledAt,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => RefillEventsCompanion.insert(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                pharmacyId: pharmacyId,
                quantityAdded: quantityAdded,
                refilledAt: refilledAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RefillEventsTable, RefillEvent>(table),
                  $$RefillEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({memberId = false, medicationId = false, pharmacyId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (memberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.memberId,
                            referencedTable: $$RefillEventsTableReferences
                                ._memberIdTable(db),
                            referencedColumn: $$RefillEventsTableReferences
                                ._memberIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (medicationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.medicationId,
                            referencedTable: $$RefillEventsTableReferences
                                ._medicationIdTable(db),
                            referencedColumn: $$RefillEventsTableReferences
                                ._medicationIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (pharmacyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.pharmacyId,
                            referencedTable: $$RefillEventsTableReferences
                                ._pharmacyIdTable(db),
                            referencedColumn: $$RefillEventsTableReferences
                                ._pharmacyIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$RefillEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefillEventsTable,
      RefillEvent,
      $$RefillEventsTableFilterComposer,
      $$RefillEventsTableOrderingComposer,
      $$RefillEventsTableAnnotationComposer,
      $$RefillEventsTableCreateCompanionBuilder,
      $$RefillEventsTableUpdateCompanionBuilder,
      (RefillEvent, $$RefillEventsTableReferences),
      RefillEvent,
      PrefetchHooks Function({
        bool memberId,
        bool medicationId,
        bool pharmacyId,
      })
    >;
typedef $$VitalEntriesTableCreateCompanionBuilder =
    VitalEntriesCompanion Function({
      required String id,
      required String memberId,
      required String vitalType,
      required double primaryValue,
      Value<double?> secondaryValue,
      Value<double?> pulse,
      required String unit,
      required DateTime recordedAt,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VitalEntriesTableUpdateCompanionBuilder =
    VitalEntriesCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> vitalType,
      Value<double> primaryValue,
      Value<double?> secondaryValue,
      Value<double?> pulse,
      Value<String> unit,
      Value<DateTime> recordedAt,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$VitalEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $VitalEntriesTable, VitalEntry> {
  $$VitalEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('vital_entries__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VitalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VitalEntriesTable> {
  $$VitalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vitalType => $composableBuilder(
    column: $table.vitalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get primaryValue => $composableBuilder(
    column: $table.primaryValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get secondaryValue => $composableBuilder(
    column: $table.secondaryValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VitalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VitalEntriesTable> {
  $$VitalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vitalType => $composableBuilder(
    column: $table.vitalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get primaryValue => $composableBuilder(
    column: $table.primaryValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get secondaryValue => $composableBuilder(
    column: $table.secondaryValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VitalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VitalEntriesTable> {
  $$VitalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vitalType =>
      $composableBuilder(column: $table.vitalType, builder: (column) => column);

  GeneratedColumn<double> get primaryValue => $composableBuilder(
    column: $table.primaryValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get secondaryValue => $composableBuilder(
    column: $table.secondaryValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pulse =>
      $composableBuilder(column: $table.pulse, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VitalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VitalEntriesTable,
          VitalEntry,
          $$VitalEntriesTableFilterComposer,
          $$VitalEntriesTableOrderingComposer,
          $$VitalEntriesTableAnnotationComposer,
          $$VitalEntriesTableCreateCompanionBuilder,
          $$VitalEntriesTableUpdateCompanionBuilder,
          (VitalEntry, $$VitalEntriesTableReferences),
          VitalEntry,
          PrefetchHooks Function({bool memberId})
        > {
  $$VitalEntriesTableTableManager(_$AppDatabase db, $VitalEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VitalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VitalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VitalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> vitalType = const Value.absent(),
                Value<double> primaryValue = const Value.absent(),
                Value<double?> secondaryValue = const Value.absent(),
                Value<double?> pulse = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VitalEntriesCompanion(
                id: id,
                memberId: memberId,
                vitalType: vitalType,
                primaryValue: primaryValue,
                secondaryValue: secondaryValue,
                pulse: pulse,
                unit: unit,
                recordedAt: recordedAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String vitalType,
                required double primaryValue,
                Value<double?> secondaryValue = const Value.absent(),
                Value<double?> pulse = const Value.absent(),
                required String unit,
                required DateTime recordedAt,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VitalEntriesCompanion.insert(
                id: id,
                memberId: memberId,
                vitalType: vitalType,
                primaryValue: primaryValue,
                secondaryValue: secondaryValue,
                pulse: pulse,
                unit: unit,
                recordedAt: recordedAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VitalEntriesTable, VitalEntry>(table),
                  $$VitalEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $$VitalEntriesTableReferences
                            ._memberIdTable(db),
                        referencedColumn: $$VitalEntriesTableReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VitalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VitalEntriesTable,
      VitalEntry,
      $$VitalEntriesTableFilterComposer,
      $$VitalEntriesTableOrderingComposer,
      $$VitalEntriesTableAnnotationComposer,
      $$VitalEntriesTableCreateCompanionBuilder,
      $$VitalEntriesTableUpdateCompanionBuilder,
      (VitalEntry, $$VitalEntriesTableReferences),
      VitalEntry,
      PrefetchHooks Function({bool memberId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$MedicationSchedulesTableTableManager get medicationSchedules =>
      $$MedicationSchedulesTableTableManager(_db, _db.medicationSchedules);
  $$DoseEventsTableTableManager get doseEvents =>
      $$DoseEventsTableTableManager(_db, _db.doseEvents);
  $$PharmaciesTableTableManager get pharmacies =>
      $$PharmaciesTableTableManager(_db, _db.pharmacies);
  $$InventoryRecordsTableTableManager get inventoryRecords =>
      $$InventoryRecordsTableTableManager(_db, _db.inventoryRecords);
  $$RefillEventsTableTableManager get refillEvents =>
      $$RefillEventsTableTableManager(_db, _db.refillEvents);
  $$VitalEntriesTableTableManager get vitalEntries =>
      $$VitalEntriesTableTableManager(_db, _db.vitalEntries);
}
