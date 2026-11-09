// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedEntitiesTable extends CachedEntities
    with TableInfo<$CachedEntitiesTable, CachedEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    entityType,
    uid,
    payloadJson,
    updatedAt,
    dirty,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, entityType, uid};
  @override
  CachedEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEntity(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedEntitiesTable createAlias(String alias) {
    return $CachedEntitiesTable(attachedDatabase, alias);
  }
}

class CachedEntity extends DataClass implements Insertable<CachedEntity> {
  final String accountId;
  final String entityType;
  final String uid;
  final String payloadJson;
  final String? updatedAt;
  final bool dirty;
  final DateTime cachedAt;
  const CachedEntity({
    required this.accountId,
    required this.entityType,
    required this.uid,
    required this.payloadJson,
    this.updatedAt,
    required this.dirty,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['entity_type'] = Variable<String>(entityType);
    map['uid'] = Variable<String>(uid);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedEntitiesCompanion toCompanion(bool nullToAbsent) {
    return CachedEntitiesCompanion(
      accountId: Value(accountId),
      entityType: Value(entityType),
      uid: Value(uid),
      payloadJson: Value(payloadJson),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      dirty: Value(dirty),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEntity(
      accountId: serializer.fromJson<String>(json['accountId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      uid: serializer.fromJson<String>(json['uid']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'entityType': serializer.toJson<String>(entityType),
      'uid': serializer.toJson<String>(uid),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedEntity copyWith({
    String? accountId,
    String? entityType,
    String? uid,
    String? payloadJson,
    Value<String?> updatedAt = const Value.absent(),
    bool? dirty,
    DateTime? cachedAt,
  }) => CachedEntity(
    accountId: accountId ?? this.accountId,
    entityType: entityType ?? this.entityType,
    uid: uid ?? this.uid,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    dirty: dirty ?? this.dirty,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedEntity copyWithCompanion(CachedEntitiesCompanion data) {
    return CachedEntity(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      uid: data.uid.present ? data.uid.value : this.uid,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEntity(')
          ..write('accountId: $accountId, ')
          ..write('entityType: $entityType, ')
          ..write('uid: $uid, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    entityType,
    uid,
    payloadJson,
    updatedAt,
    dirty,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEntity &&
          other.accountId == this.accountId &&
          other.entityType == this.entityType &&
          other.uid == this.uid &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty &&
          other.cachedAt == this.cachedAt);
}

class CachedEntitiesCompanion extends UpdateCompanion<CachedEntity> {
  final Value<String> accountId;
  final Value<String> entityType;
  final Value<String> uid;
  final Value<String> payloadJson;
  final Value<String?> updatedAt;
  final Value<bool> dirty;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedEntitiesCompanion({
    this.accountId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.uid = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedEntitiesCompanion.insert({
    required String accountId,
    required String entityType,
    required String uid,
    required String payloadJson,
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       entityType = Value(entityType),
       uid = Value(uid),
       payloadJson = Value(payloadJson);
  static Insertable<CachedEntity> custom({
    Expression<String>? accountId,
    Expression<String>? entityType,
    Expression<String>? uid,
    Expression<String>? payloadJson,
    Expression<String>? updatedAt,
    Expression<bool>? dirty,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (entityType != null) 'entity_type': entityType,
      if (uid != null) 'uid': uid,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedEntitiesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? entityType,
    Value<String>? uid,
    Value<String>? payloadJson,
    Value<String?>? updatedAt,
    Value<bool>? dirty,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedEntitiesCompanion(
      accountId: accountId ?? this.accountId,
      entityType: entityType ?? this.entityType,
      uid: uid ?? this.uid,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEntitiesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('entityType: $entityType, ')
          ..write('uid: $uid, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxOpsTable extends OutboxOps
    with TableInfo<$OutboxOpsTable, OutboxOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityUidMeta = const VerificationMeta(
    'entityUid',
  );
  @override
  late final GeneratedColumn<String> entityUid = GeneratedColumn<String>(
    'entity_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseJsonMeta = const VerificationMeta(
    'baseJson',
  );
  @override
  late final GeneratedColumn<String> baseJson = GeneratedColumn<String>(
    'base_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseUpdatedAtMeta = const VerificationMeta(
    'baseUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> baseUpdatedAt = GeneratedColumn<String>(
    'base_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _conflictServerJsonMeta =
      const VerificationMeta('conflictServerJson');
  @override
  late final GeneratedColumn<String> conflictServerJson =
      GeneratedColumn<String>(
        'conflict_server_json',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    entity,
    op,
    entityUid,
    payloadJson,
    baseJson,
    baseUpdatedAt,
    clientId,
    status,
    conflictServerJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxOp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('entity_uid')) {
      context.handle(
        _entityUidMeta,
        entityUid.isAcceptableOrUnknown(data['entity_uid']!, _entityUidMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('base_json')) {
      context.handle(
        _baseJsonMeta,
        baseJson.isAcceptableOrUnknown(data['base_json']!, _baseJsonMeta),
      );
    }
    if (data.containsKey('base_updated_at')) {
      context.handle(
        _baseUpdatedAtMeta,
        baseUpdatedAt.isAcceptableOrUnknown(
          data['base_updated_at']!,
          _baseUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('conflict_server_json')) {
      context.handle(
        _conflictServerJsonMeta,
        conflictServerJson.isAcceptableOrUnknown(
          data['conflict_server_json']!,
          _conflictServerJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxOp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      entityUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_uid'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      baseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_json'],
      ),
      baseUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_updated_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      conflictServerJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_server_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxOpsTable createAlias(String alias) {
    return $OutboxOpsTable(attachedDatabase, alias);
  }
}

class OutboxOp extends DataClass implements Insertable<OutboxOp> {
  final int id;
  final String accountId;
  final String entity;
  final String op;
  final String? entityUid;
  final String payloadJson;
  final String? baseJson;
  final String? baseUpdatedAt;
  final String clientId;
  final String status;
  final String? conflictServerJson;
  final DateTime createdAt;
  const OutboxOp({
    required this.id,
    required this.accountId,
    required this.entity,
    required this.op,
    this.entityUid,
    required this.payloadJson,
    this.baseJson,
    this.baseUpdatedAt,
    required this.clientId,
    required this.status,
    this.conflictServerJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<String>(accountId);
    map['entity'] = Variable<String>(entity);
    map['op'] = Variable<String>(op);
    if (!nullToAbsent || entityUid != null) {
      map['entity_uid'] = Variable<String>(entityUid);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || baseJson != null) {
      map['base_json'] = Variable<String>(baseJson);
    }
    if (!nullToAbsent || baseUpdatedAt != null) {
      map['base_updated_at'] = Variable<String>(baseUpdatedAt);
    }
    map['client_id'] = Variable<String>(clientId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || conflictServerJson != null) {
      map['conflict_server_json'] = Variable<String>(conflictServerJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxOpsCompanion toCompanion(bool nullToAbsent) {
    return OutboxOpsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      entity: Value(entity),
      op: Value(op),
      entityUid: entityUid == null && nullToAbsent
          ? const Value.absent()
          : Value(entityUid),
      payloadJson: Value(payloadJson),
      baseJson: baseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(baseJson),
      baseUpdatedAt: baseUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUpdatedAt),
      clientId: Value(clientId),
      status: Value(status),
      conflictServerJson: conflictServerJson == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictServerJson),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxOp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxOp(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      entity: serializer.fromJson<String>(json['entity']),
      op: serializer.fromJson<String>(json['op']),
      entityUid: serializer.fromJson<String?>(json['entityUid']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      baseJson: serializer.fromJson<String?>(json['baseJson']),
      baseUpdatedAt: serializer.fromJson<String?>(json['baseUpdatedAt']),
      clientId: serializer.fromJson<String>(json['clientId']),
      status: serializer.fromJson<String>(json['status']),
      conflictServerJson: serializer.fromJson<String?>(
        json['conflictServerJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<String>(accountId),
      'entity': serializer.toJson<String>(entity),
      'op': serializer.toJson<String>(op),
      'entityUid': serializer.toJson<String?>(entityUid),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'baseJson': serializer.toJson<String?>(baseJson),
      'baseUpdatedAt': serializer.toJson<String?>(baseUpdatedAt),
      'clientId': serializer.toJson<String>(clientId),
      'status': serializer.toJson<String>(status),
      'conflictServerJson': serializer.toJson<String?>(conflictServerJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxOp copyWith({
    int? id,
    String? accountId,
    String? entity,
    String? op,
    Value<String?> entityUid = const Value.absent(),
    String? payloadJson,
    Value<String?> baseJson = const Value.absent(),
    Value<String?> baseUpdatedAt = const Value.absent(),
    String? clientId,
    String? status,
    Value<String?> conflictServerJson = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxOp(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    entity: entity ?? this.entity,
    op: op ?? this.op,
    entityUid: entityUid.present ? entityUid.value : this.entityUid,
    payloadJson: payloadJson ?? this.payloadJson,
    baseJson: baseJson.present ? baseJson.value : this.baseJson,
    baseUpdatedAt: baseUpdatedAt.present
        ? baseUpdatedAt.value
        : this.baseUpdatedAt,
    clientId: clientId ?? this.clientId,
    status: status ?? this.status,
    conflictServerJson: conflictServerJson.present
        ? conflictServerJson.value
        : this.conflictServerJson,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxOp copyWithCompanion(OutboxOpsCompanion data) {
    return OutboxOp(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      entity: data.entity.present ? data.entity.value : this.entity,
      op: data.op.present ? data.op.value : this.op,
      entityUid: data.entityUid.present ? data.entityUid.value : this.entityUid,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      baseJson: data.baseJson.present ? data.baseJson.value : this.baseJson,
      baseUpdatedAt: data.baseUpdatedAt.present
          ? data.baseUpdatedAt.value
          : this.baseUpdatedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      status: data.status.present ? data.status.value : this.status,
      conflictServerJson: data.conflictServerJson.present
          ? data.conflictServerJson.value
          : this.conflictServerJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOp(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('entity: $entity, ')
          ..write('op: $op, ')
          ..write('entityUid: $entityUid, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseJson: $baseJson, ')
          ..write('baseUpdatedAt: $baseUpdatedAt, ')
          ..write('clientId: $clientId, ')
          ..write('status: $status, ')
          ..write('conflictServerJson: $conflictServerJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    entity,
    op,
    entityUid,
    payloadJson,
    baseJson,
    baseUpdatedAt,
    clientId,
    status,
    conflictServerJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxOp &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.entity == this.entity &&
          other.op == this.op &&
          other.entityUid == this.entityUid &&
          other.payloadJson == this.payloadJson &&
          other.baseJson == this.baseJson &&
          other.baseUpdatedAt == this.baseUpdatedAt &&
          other.clientId == this.clientId &&
          other.status == this.status &&
          other.conflictServerJson == this.conflictServerJson &&
          other.createdAt == this.createdAt);
}

class OutboxOpsCompanion extends UpdateCompanion<OutboxOp> {
  final Value<int> id;
  final Value<String> accountId;
  final Value<String> entity;
  final Value<String> op;
  final Value<String?> entityUid;
  final Value<String> payloadJson;
  final Value<String?> baseJson;
  final Value<String?> baseUpdatedAt;
  final Value<String> clientId;
  final Value<String> status;
  final Value<String?> conflictServerJson;
  final Value<DateTime> createdAt;
  const OutboxOpsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.entity = const Value.absent(),
    this.op = const Value.absent(),
    this.entityUid = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.baseJson = const Value.absent(),
    this.baseUpdatedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.status = const Value.absent(),
    this.conflictServerJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxOpsCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required String entity,
    required String op,
    this.entityUid = const Value.absent(),
    required String payloadJson,
    this.baseJson = const Value.absent(),
    this.baseUpdatedAt = const Value.absent(),
    required String clientId,
    this.status = const Value.absent(),
    this.conflictServerJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : accountId = Value(accountId),
       entity = Value(entity),
       op = Value(op),
       payloadJson = Value(payloadJson),
       clientId = Value(clientId);
  static Insertable<OutboxOp> custom({
    Expression<int>? id,
    Expression<String>? accountId,
    Expression<String>? entity,
    Expression<String>? op,
    Expression<String>? entityUid,
    Expression<String>? payloadJson,
    Expression<String>? baseJson,
    Expression<String>? baseUpdatedAt,
    Expression<String>? clientId,
    Expression<String>? status,
    Expression<String>? conflictServerJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (entity != null) 'entity': entity,
      if (op != null) 'op': op,
      if (entityUid != null) 'entity_uid': entityUid,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (baseJson != null) 'base_json': baseJson,
      if (baseUpdatedAt != null) 'base_updated_at': baseUpdatedAt,
      if (clientId != null) 'client_id': clientId,
      if (status != null) 'status': status,
      if (conflictServerJson != null)
        'conflict_server_json': conflictServerJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxOpsCompanion copyWith({
    Value<int>? id,
    Value<String>? accountId,
    Value<String>? entity,
    Value<String>? op,
    Value<String?>? entityUid,
    Value<String>? payloadJson,
    Value<String?>? baseJson,
    Value<String?>? baseUpdatedAt,
    Value<String>? clientId,
    Value<String>? status,
    Value<String?>? conflictServerJson,
    Value<DateTime>? createdAt,
  }) {
    return OutboxOpsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      entity: entity ?? this.entity,
      op: op ?? this.op,
      entityUid: entityUid ?? this.entityUid,
      payloadJson: payloadJson ?? this.payloadJson,
      baseJson: baseJson ?? this.baseJson,
      baseUpdatedAt: baseUpdatedAt ?? this.baseUpdatedAt,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      conflictServerJson: conflictServerJson ?? this.conflictServerJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (entityUid.present) {
      map['entity_uid'] = Variable<String>(entityUid.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (baseJson.present) {
      map['base_json'] = Variable<String>(baseJson.value);
    }
    if (baseUpdatedAt.present) {
      map['base_updated_at'] = Variable<String>(baseUpdatedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (conflictServerJson.present) {
      map['conflict_server_json'] = Variable<String>(conflictServerJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOpsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('entity: $entity, ')
          ..write('op: $op, ')
          ..write('entityUid: $entityUid, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseJson: $baseJson, ')
          ..write('baseUpdatedAt: $baseUpdatedAt, ')
          ..write('clientId: $clientId, ')
          ..write('status: $status, ')
          ..write('conflictServerJson: $conflictServerJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IdMapsTable extends IdMaps with TableInfo<$IdMapsTable, IdMap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdMapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUidMeta = const VerificationMeta(
    'localUid',
  );
  @override
  late final GeneratedColumn<String> localUid = GeneratedColumn<String>(
    'local_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUidMeta = const VerificationMeta(
    'serverUid',
  );
  @override
  late final GeneratedColumn<String> serverUid = GeneratedColumn<String>(
    'server_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [accountId, localUid, serverUid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'id_maps';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdMap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('local_uid')) {
      context.handle(
        _localUidMeta,
        localUid.isAcceptableOrUnknown(data['local_uid']!, _localUidMeta),
      );
    } else if (isInserting) {
      context.missing(_localUidMeta);
    }
    if (data.containsKey('server_uid')) {
      context.handle(
        _serverUidMeta,
        serverUid.isAcceptableOrUnknown(data['server_uid']!, _serverUidMeta),
      );
    } else if (isInserting) {
      context.missing(_serverUidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, localUid};
  @override
  IdMap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdMap(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      localUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_uid'],
      )!,
      serverUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_uid'],
      )!,
    );
  }

  @override
  $IdMapsTable createAlias(String alias) {
    return $IdMapsTable(attachedDatabase, alias);
  }
}

class IdMap extends DataClass implements Insertable<IdMap> {
  final String accountId;
  final String localUid;
  final String serverUid;
  const IdMap({
    required this.accountId,
    required this.localUid,
    required this.serverUid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['local_uid'] = Variable<String>(localUid);
    map['server_uid'] = Variable<String>(serverUid);
    return map;
  }

  IdMapsCompanion toCompanion(bool nullToAbsent) {
    return IdMapsCompanion(
      accountId: Value(accountId),
      localUid: Value(localUid),
      serverUid: Value(serverUid),
    );
  }

  factory IdMap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdMap(
      accountId: serializer.fromJson<String>(json['accountId']),
      localUid: serializer.fromJson<String>(json['localUid']),
      serverUid: serializer.fromJson<String>(json['serverUid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'localUid': serializer.toJson<String>(localUid),
      'serverUid': serializer.toJson<String>(serverUid),
    };
  }

  IdMap copyWith({String? accountId, String? localUid, String? serverUid}) =>
      IdMap(
        accountId: accountId ?? this.accountId,
        localUid: localUid ?? this.localUid,
        serverUid: serverUid ?? this.serverUid,
      );
  IdMap copyWithCompanion(IdMapsCompanion data) {
    return IdMap(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      localUid: data.localUid.present ? data.localUid.value : this.localUid,
      serverUid: data.serverUid.present ? data.serverUid.value : this.serverUid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdMap(')
          ..write('accountId: $accountId, ')
          ..write('localUid: $localUid, ')
          ..write('serverUid: $serverUid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, localUid, serverUid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdMap &&
          other.accountId == this.accountId &&
          other.localUid == this.localUid &&
          other.serverUid == this.serverUid);
}

class IdMapsCompanion extends UpdateCompanion<IdMap> {
  final Value<String> accountId;
  final Value<String> localUid;
  final Value<String> serverUid;
  final Value<int> rowid;
  const IdMapsCompanion({
    this.accountId = const Value.absent(),
    this.localUid = const Value.absent(),
    this.serverUid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdMapsCompanion.insert({
    required String accountId,
    required String localUid,
    required String serverUid,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       localUid = Value(localUid),
       serverUid = Value(serverUid);
  static Insertable<IdMap> custom({
    Expression<String>? accountId,
    Expression<String>? localUid,
    Expression<String>? serverUid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (localUid != null) 'local_uid': localUid,
      if (serverUid != null) 'server_uid': serverUid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdMapsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? localUid,
    Value<String>? serverUid,
    Value<int>? rowid,
  }) {
    return IdMapsCompanion(
      accountId: accountId ?? this.accountId,
      localUid: localUid ?? this.localUid,
      serverUid: serverUid ?? this.serverUid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (localUid.present) {
      map['local_uid'] = Variable<String>(localUid.value);
    }
    if (serverUid.present) {
      map['server_uid'] = Variable<String>(serverUid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdMapsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('localUid: $localUid, ')
          ..write('serverUid: $serverUid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedEntitiesTable cachedEntities = $CachedEntitiesTable(this);
  late final $OutboxOpsTable outboxOps = $OutboxOpsTable(this);
  late final $IdMapsTable idMaps = $IdMapsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedEntities,
    outboxOps,
    idMaps,
  ];
}

typedef $$CachedEntitiesTableCreateCompanionBuilder =
    CachedEntitiesCompanion Function({
      required String accountId,
      required String entityType,
      required String uid,
      required String payloadJson,
      Value<String?> updatedAt,
      Value<bool> dirty,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedEntitiesTableUpdateCompanionBuilder =
    CachedEntitiesCompanion Function({
      Value<String> accountId,
      Value<String> entityType,
      Value<String> uid,
      Value<String> payloadJson,
      Value<String?> updatedAt,
      Value<bool> dirty,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedEntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedEntitiesTable> {
  $$CachedEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedEntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedEntitiesTable> {
  $$CachedEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedEntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedEntitiesTable> {
  $$CachedEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedEntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedEntitiesTable,
          CachedEntity,
          $$CachedEntitiesTableFilterComposer,
          $$CachedEntitiesTableOrderingComposer,
          $$CachedEntitiesTableAnnotationComposer,
          $$CachedEntitiesTableCreateCompanionBuilder,
          $$CachedEntitiesTableUpdateCompanionBuilder,
          (
            CachedEntity,
            BaseReferences<_$AppDatabase, $CachedEntitiesTable, CachedEntity>,
          ),
          CachedEntity,
          PrefetchHooks Function()
        > {
  $$CachedEntitiesTableTableManager(
    _$AppDatabase db,
    $CachedEntitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedEntitiesCompanion(
                accountId: accountId,
                entityType: entityType,
                uid: uid,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                dirty: dirty,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String entityType,
                required String uid,
                required String payloadJson,
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedEntitiesCompanion.insert(
                accountId: accountId,
                entityType: entityType,
                uid: uid,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                dirty: dirty,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedEntitiesTable, CachedEntity>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedEntitiesTable,
                    CachedEntity
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedEntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedEntitiesTable,
      CachedEntity,
      $$CachedEntitiesTableFilterComposer,
      $$CachedEntitiesTableOrderingComposer,
      $$CachedEntitiesTableAnnotationComposer,
      $$CachedEntitiesTableCreateCompanionBuilder,
      $$CachedEntitiesTableUpdateCompanionBuilder,
      (
        CachedEntity,
        BaseReferences<_$AppDatabase, $CachedEntitiesTable, CachedEntity>,
      ),
      CachedEntity,
      PrefetchHooks Function()
    >;
typedef $$OutboxOpsTableCreateCompanionBuilder = OutboxOpsCompanion Function({
  Value<int> id,
  required String accountId,
  required String entity,
  required String op,
  Value<String?> entityUid,
  required String payloadJson,
  Value<String?> baseJson,
  Value<String?> baseUpdatedAt,
  required String clientId,
  Value<String> status,
  Value<String?> conflictServerJson,
  Value<DateTime> createdAt,
});
typedef $$OutboxOpsTableUpdateCompanionBuilder = OutboxOpsCompanion Function({
  Value<int> id,
  Value<String> accountId,
  Value<String> entity,
  Value<String> op,
  Value<String?> entityUid,
  Value<String> payloadJson,
  Value<String?> baseJson,
  Value<String?> baseUpdatedAt,
  Value<String> clientId,
  Value<String> status,
  Value<String?> conflictServerJson,
  Value<DateTime> createdAt,
});

class $$OutboxOpsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxOpsTable> {
  $$OutboxOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityUid => $composableBuilder(
    column: $table.entityUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseJson => $composableBuilder(
    column: $table.baseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUpdatedAt => $composableBuilder(
    column: $table.baseUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictServerJson => $composableBuilder(
    column: $table.conflictServerJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxOpsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxOpsTable> {
  $$OutboxOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityUid => $composableBuilder(
    column: $table.entityUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseJson => $composableBuilder(
    column: $table.baseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUpdatedAt => $composableBuilder(
    column: $table.baseUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictServerJson => $composableBuilder(
    column: $table.conflictServerJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxOpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxOpsTable> {
  $$OutboxOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get entityUid =>
      $composableBuilder(column: $table.entityUid, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseJson =>
      $composableBuilder(column: $table.baseJson, builder: (column) => column);

  GeneratedColumn<String> get baseUpdatedAt => $composableBuilder(
    column: $table.baseUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get conflictServerJson => $composableBuilder(
    column: $table.conflictServerJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxOpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxOpsTable,
          OutboxOp,
          $$OutboxOpsTableFilterComposer,
          $$OutboxOpsTableOrderingComposer,
          $$OutboxOpsTableAnnotationComposer,
          $$OutboxOpsTableCreateCompanionBuilder,
          $$OutboxOpsTableUpdateCompanionBuilder,
          (OutboxOp, BaseReferences<_$AppDatabase, $OutboxOpsTable, OutboxOp>),
          OutboxOp,
          PrefetchHooks Function()
        > {
  $$OutboxOpsTableTableManager(_$AppDatabase db, $OutboxOpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String?> entityUid = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> baseJson = const Value.absent(),
                Value<String?> baseUpdatedAt = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> conflictServerJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxOpsCompanion(
                id: id,
                accountId: accountId,
                entity: entity,
                op: op,
                entityUid: entityUid,
                payloadJson: payloadJson,
                baseJson: baseJson,
                baseUpdatedAt: baseUpdatedAt,
                clientId: clientId,
                status: status,
                conflictServerJson: conflictServerJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String accountId,
                required String entity,
                required String op,
                Value<String?> entityUid = const Value.absent(),
                required String payloadJson,
                Value<String?> baseJson = const Value.absent(),
                Value<String?> baseUpdatedAt = const Value.absent(),
                required String clientId,
                Value<String> status = const Value.absent(),
                Value<String?> conflictServerJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxOpsCompanion.insert(
                id: id,
                accountId: accountId,
                entity: entity,
                op: op,
                entityUid: entityUid,
                payloadJson: payloadJson,
                baseJson: baseJson,
                baseUpdatedAt: baseUpdatedAt,
                clientId: clientId,
                status: status,
                conflictServerJson: conflictServerJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxOpsTable, OutboxOp>(table),
                  BaseReferences<_$AppDatabase, $OutboxOpsTable, OutboxOp>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxOpsTable,
      OutboxOp,
      $$OutboxOpsTableFilterComposer,
      $$OutboxOpsTableOrderingComposer,
      $$OutboxOpsTableAnnotationComposer,
      $$OutboxOpsTableCreateCompanionBuilder,
      $$OutboxOpsTableUpdateCompanionBuilder,
      (OutboxOp, BaseReferences<_$AppDatabase, $OutboxOpsTable, OutboxOp>),
      OutboxOp,
      PrefetchHooks Function()
    >;
typedef $$IdMapsTableCreateCompanionBuilder = IdMapsCompanion Function({
  required String accountId,
  required String localUid,
  required String serverUid,
  Value<int> rowid,
});
typedef $$IdMapsTableUpdateCompanionBuilder = IdMapsCompanion Function({
  Value<String> accountId,
  Value<String> localUid,
  Value<String> serverUid,
  Value<int> rowid,
});

class $$IdMapsTableFilterComposer
    extends Composer<_$AppDatabase, $IdMapsTable> {
  $$IdMapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localUid => $composableBuilder(
    column: $table.localUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUid => $composableBuilder(
    column: $table.serverUid,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IdMapsTableOrderingComposer
    extends Composer<_$AppDatabase, $IdMapsTable> {
  $$IdMapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localUid => $composableBuilder(
    column: $table.localUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUid => $composableBuilder(
    column: $table.serverUid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IdMapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdMapsTable> {
  $$IdMapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get localUid =>
      $composableBuilder(column: $table.localUid, builder: (column) => column);

  GeneratedColumn<String> get serverUid =>
      $composableBuilder(column: $table.serverUid, builder: (column) => column);
}

class $$IdMapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IdMapsTable,
          IdMap,
          $$IdMapsTableFilterComposer,
          $$IdMapsTableOrderingComposer,
          $$IdMapsTableAnnotationComposer,
          $$IdMapsTableCreateCompanionBuilder,
          $$IdMapsTableUpdateCompanionBuilder,
          (IdMap, BaseReferences<_$AppDatabase, $IdMapsTable, IdMap>),
          IdMap,
          PrefetchHooks Function()
        > {
  $$IdMapsTableTableManager(_$AppDatabase db, $IdMapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdMapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdMapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdMapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> localUid = const Value.absent(),
                Value<String> serverUid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdMapsCompanion(
                accountId: accountId,
                localUid: localUid,
                serverUid: serverUid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String localUid,
                required String serverUid,
                Value<int> rowid = const Value.absent(),
              }) => IdMapsCompanion.insert(
                accountId: accountId,
                localUid: localUid,
                serverUid: serverUid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IdMapsTable, IdMap>(table),
                  BaseReferences<_$AppDatabase, $IdMapsTable, IdMap>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IdMapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IdMapsTable,
      IdMap,
      $$IdMapsTableFilterComposer,
      $$IdMapsTableOrderingComposer,
      $$IdMapsTableAnnotationComposer,
      $$IdMapsTableCreateCompanionBuilder,
      $$IdMapsTableUpdateCompanionBuilder,
      (IdMap, BaseReferences<_$AppDatabase, $IdMapsTable, IdMap>),
      IdMap,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedEntitiesTableTableManager get cachedEntities =>
      $$CachedEntitiesTableTableManager(_db, _db.cachedEntities);
  $$OutboxOpsTableTableManager get outboxOps =>
      $$OutboxOpsTableTableManager(_db, _db.outboxOps);
  $$IdMapsTableTableManager get idMaps =>
      $$IdMapsTableTableManager(_db, _db.idMaps);
}
