import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pro_api/pro_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';

/// Pro offline store: Drift SQLite for buckets, entities, and outbox.
class DriftOfflineCache implements OfflineCachePort {
  DriftOfflineCache(this.db, {this.prefs});

  final AppDatabase db;
  final SharedPreferences? prefs;
  var _migrated = false;

  static DriftOfflineCache open({SharedPreferences? prefs}) {
    return DriftOfflineCache(AppDatabase(), prefs: prefs);
  }

  Future<void> ensureMigrated() async {
    if (_migrated) return;
    _migrated = true;
    final prefs = this.prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((k) => k.startsWith('dootdoot.offline.'));
    for (final key in keys) {
      final parts = key.split('.');
      // dootdoot.offline.{accountId}.{bucket}
      if (parts.length < 4) continue;
      final accountId = parts[2];
      final bucket = parts.sublist(3).join('.');
      final raw = prefs.getString(key);
      if (raw == null) continue;
      if (bucket == 'queue') {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          for (final item in list.whereType<Map>()) {
            final op = Map<String, dynamic>.from(item);
            await db.enqueueOutbox(
              OutboxOpsCompanion.insert(
                accountId: accountId,
                entity: (op['entity'] ?? 'task').toString(),
                op: (op['op'] ?? 'update').toString(),
                entityUid: Value(
                  op['uid']?.toString() ?? op['localUid']?.toString(),
                ),
                payloadJson: jsonEncode(op),
                clientId: (op['clientId'] ??
                        op['enqueuedAt'] ??
                        'migrated')
                    .toString(),
                baseJson: Value(
                  op['base'] != null ? jsonEncode(op['base']) : null,
                ),
                baseUpdatedAt: Value(op['baseUpdatedAt']?.toString()),
              ),
            );
          }
        } catch (_) {}
      } else {
        await putJson(accountId, bucket, jsonDecode(raw));
      }
      await prefs.remove(key);
    }
  }

  @override
  Future<void> putJson(String accountId, String bucket, Object data) async {
    await ensureMigrated();
    final encoded = jsonEncode(data);
    await db.upsertEntity(
      accountId: accountId,
      entityType: 'bucket',
      uid: bucket,
      payloadJson: encoded,
    );
    // Also index task rows when caching a task list snapshot.
    if (bucket.startsWith('tasks_') && data is List) {
      for (final item in data.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final uid = map['uid']?.toString();
        if (uid == null || uid.isEmpty) continue;
        await db.upsertEntity(
          accountId: accountId,
          entityType: 'task',
          uid: uid,
          payloadJson: jsonEncode(map),
          updatedAt: map['updated_at']?.toString() ?? map['completed_at']?.toString(),
        );
      }
    }
    if (bucket == 'notes' && data is List) {
      for (final item in data.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final uid = map['uid']?.toString();
        if (uid == null || uid.isEmpty) continue;
        await db.upsertEntity(
          accountId: accountId,
          entityType: 'note',
          uid: uid,
          payloadJson: jsonEncode(map),
          updatedAt: map['updated_at']?.toString(),
        );
      }
    }
    if (bucket.startsWith('habits') && data is List) {
      for (final item in data.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final uid = map['uid']?.toString() ?? map['id']?.toString();
        if (uid == null || uid.isEmpty) continue;
        await db.upsertEntity(
          accountId: accountId,
          entityType: 'habit',
          uid: uid,
          payloadJson: jsonEncode(map),
        );
      }
    }
    if ((bucket == 'projects' || bucket == 'areas' || bucket == 'goals') &&
        data is List) {
      final type = bucket.endsWith('s') ? bucket.substring(0, bucket.length - 1) : bucket;
      for (final item in data.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final uid = map['uid']?.toString() ?? map['id']?.toString();
        if (uid == null || uid.isEmpty) continue;
        await db.upsertEntity(
          accountId: accountId,
          entityType: type,
          uid: uid,
          payloadJson: jsonEncode(map),
        );
      }
    }
  }

  @override
  Future<Object?> getJson(String accountId, String bucket) async {
    await ensureMigrated();
    final row = await db.entityByUid(accountId, 'bucket', bucket);
    if (row == null) return null;
    return jsonDecode(row.payloadJson);
  }

  @override
  Future<void> clearAccount(String accountId) async {
    await ensureMigrated();
    await db.clearAccount(accountId);
  }

  @override
  Future<void> enqueueWrite(
    String accountId,
    Map<String, dynamic> op,
  ) async {
    await ensureMigrated();
    final entity = (op['entity'] ?? 'task').toString();
    await db.enqueueOutbox(
      OutboxOpsCompanion.insert(
        accountId: accountId,
        entity: entity,
        op: (op['op'] ?? 'update').toString(),
        entityUid: Value(op['uid']?.toString() ?? op['localUid']?.toString()),
        payloadJson: jsonEncode(op),
        clientId: (op['clientId'] ?? DateTime.now().toIso8601String()).toString(),
        baseJson: Value(
          op['base'] != null ? jsonEncode(op['base']) : op['baseJson']?.toString(),
        ),
        baseUpdatedAt: Value(op['baseUpdatedAt']?.toString()),
      ),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> pendingWrites(String accountId) async {
    await ensureMigrated();
    final rows = await db.pendingOutbox(accountId);
    return [
      for (final row in rows)
        {
          ...Map<String, dynamic>.from(jsonDecode(row.payloadJson) as Map),
          '_outboxId': row.id,
          '_status': row.status,
          if (row.conflictServerJson != null)
            '_conflictServerJson': row.conflictServerJson,
          if (row.baseJson != null) 'baseJson': row.baseJson,
          if (row.baseUpdatedAt != null) 'baseUpdatedAt': row.baseUpdatedAt,
        },
    ];
  }

  @override
  Future<int> pendingCount(String accountId) async {
    await ensureMigrated();
    return db.outboxPendingCount(accountId);
  }

  Future<List<Map<String, dynamic>>> conflictWritesAsync(String accountId) async {
    await ensureMigrated();
    final rows = await db.conflictOutbox(accountId);
    return [
      for (final row in rows)
        {
          ...Map<String, dynamic>.from(jsonDecode(row.payloadJson) as Map),
          '_outboxId': row.id,
          '_status': row.status,
          if (row.conflictServerJson != null)
            '_conflictServerJson': row.conflictServerJson,
        },
    ];
  }

  @override
  Future<void> replaceQueue(
    String accountId,
    List<Map<String, dynamic>> ops,
  ) async {
    await ensureMigrated();
    final existing = await db.pendingOutbox(accountId);
    for (final row in existing) {
      await db.deleteOutbox(row.id);
    }
    for (final op in ops) {
      await enqueueWrite(accountId, op);
    }
  }

  Future<void> removeOutbox(int id) => db.deleteOutbox(id);

  Future<void> markConflict(int id, String serverJson) {
    return db.markOutboxConflict(id: id, serverJson: serverJson);
  }

  Future<void> resolveKeepMine(int id) => db.markOutboxPending(id);

  Future<void> mapLocalUid({
    required String accountId,
    required String localUid,
    required String serverUid,
  }) {
    return db.putIdMap(
      accountId: accountId,
      localUid: localUid,
      serverUid: serverUid,
    );
  }

  Future<String?> resolveUid(String accountId, String uid) async {
    if (!uid.startsWith('local_')) return uid;
    return db.serverUidFor(accountId, uid);
  }
}
