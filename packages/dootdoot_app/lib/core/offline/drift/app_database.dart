import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CachedEntities, OutboxOps, IdMaps])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'dootdoot_offline'));

  @override
  int get schemaVersion => 1;

  Future<void> upsertEntity({
    required String accountId,
    required String entityType,
    required String uid,
    required String payloadJson,
    String? updatedAt,
    bool dirty = false,
  }) {
    return into(cachedEntities).insertOnConflictUpdate(
      CachedEntitiesCompanion.insert(
        accountId: accountId,
        entityType: entityType,
        uid: uid,
        payloadJson: payloadJson,
        updatedAt: Value(updatedAt),
        dirty: Value(dirty),
      ),
    );
  }

  Future<List<CachedEntity>> entitiesOfType(
    String accountId,
    String entityType,
  ) {
    return (select(cachedEntities)..where(
          (t) =>
              t.accountId.equals(accountId) & t.entityType.equals(entityType),
        ))
        .get();
  }

  Future<CachedEntity?> entityByUid(
    String accountId,
    String entityType,
    String uid,
  ) {
    return (select(cachedEntities)..where(
          (t) =>
              t.accountId.equals(accountId) &
              t.entityType.equals(entityType) &
              t.uid.equals(uid),
        ))
        .getSingleOrNull();
  }

  Future<int> enqueueOutbox(OutboxOpsCompanion row) {
    return into(outboxOps).insert(row);
  }

  Future<List<OutboxOp>> pendingOutbox(String accountId) {
    return (select(outboxOps)
          ..where(
            (t) =>
                t.accountId.equals(accountId) & t.status.equals('pending'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<List<OutboxOp>> conflictOutbox(String accountId) {
    return (select(outboxOps)
          ..where(
            (t) =>
                t.accountId.equals(accountId) & t.status.equals('conflict'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<int> outboxPendingCount(String accountId) async {
    final count = countAll();
    final query = selectOnly(outboxOps)
      ..addColumns([count])
      ..where(
        outboxOps.accountId.equals(accountId) &
            outboxOps.status.isIn(['pending', 'conflict']),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> deleteOutbox(int id) {
    return (delete(outboxOps)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markOutboxConflict({
    required int id,
    required String serverJson,
  }) {
    return (update(outboxOps)..where((t) => t.id.equals(id))).write(
      OutboxOpsCompanion(
        status: const Value('conflict'),
        conflictServerJson: Value(serverJson),
      ),
    );
  }

  Future<void> markOutboxPending(int id) {
    return (update(outboxOps)..where((t) => t.id.equals(id))).write(
      const OutboxOpsCompanion(
        status: Value('pending'),
        conflictServerJson: Value(null),
      ),
    );
  }

  Future<void> putIdMap({
    required String accountId,
    required String localUid,
    required String serverUid,
  }) {
    return into(idMaps).insertOnConflictUpdate(
      IdMapsCompanion.insert(
        accountId: accountId,
        localUid: localUid,
        serverUid: serverUid,
      ),
    );
  }

  Future<String?> serverUidFor(String accountId, String localUid) async {
    final row = await (select(idMaps)..where(
          (t) => t.accountId.equals(accountId) & t.localUid.equals(localUid),
        ))
        .getSingleOrNull();
    return row?.serverUid;
  }

  Future<void> clearAccount(String accountId) async {
    await (delete(cachedEntities)..where((t) => t.accountId.equals(accountId)))
        .go();
    await (delete(outboxOps)..where((t) => t.accountId.equals(accountId))).go();
    await (delete(idMaps)..where((t) => t.accountId.equals(accountId))).go();
  }
}
