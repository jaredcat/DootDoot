import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:uuid/uuid.dart';

import '../providers.dart';
import '../../features/tasks/task_providers.dart';
import 'drift/drift_offline_cache.dart';

/// Result of a mutation that may have been queued offline.
class OfflineMutationResult<T> {
  const OfflineMutationResult({
    required this.value,
    this.queuedOffline = false,
  });

  final T value;
  final bool queuedOffline;
}

typedef OfflineTaskMutationResult = OfflineMutationResult<TududiTask>;
typedef OfflineNoteMutationResult = OfflineMutationResult<TududiNote>;

/// Outcome of draining the offline write queue.
enum OfflineDrainStatus {
  idle,
  drained,
  stoppedUnauthorized,
  failed,
  hasConflicts,
}

/// Queues writes when Pro offline mode is active and the network fails.
class OfflineWriteCoordinator {
  OfflineWriteCoordinator(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  bool get _offlineActive {
    final controller = _ref.read(proControllerProvider.notifier);
    return _ref.read(proControllerProvider) && controller.offlineEnabled;
  }

  OfflineCachePort get _cache => _ref.read(offlineCacheProvider);

  DriftOfflineCache? get _drift =>
      _cache is DriftOfflineCache ? _cache as DriftOfflineCache : null;

  String? get _accountId => _ref.read(activeAccountProvider)?.id;

  Future<OfflineTaskMutationResult> createTask(Map<String, dynamic> body) async {
    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      final task = await client.createTask(body);
      await _upsertTaskEntity(task);
      return OfflineTaskMutationResult(value: task);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      final accountId = _accountId;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      final clientId = _uuid.v4();
      final localUid = 'local_$clientId';
      final optimistic = TududiTask(
        id: -DateTime.now().millisecondsSinceEpoch,
        name: (body['name'] ?? '').toString(),
        uid: localUid,
        note: body['note']?.toString(),
        status: TaskStatus.notStarted,
        priority: body['priority']?.toString(),
        dueDate: body['due_date']?.toString(),
      );
      await _cache.enqueueWrite(accountId, {
        'entity': 'task',
        'op': 'create',
        'clientId': clientId,
        'localUid': localUid,
        'body': body,
      });
      await _patchTaskSnapshots(accountId, (tasks) => [...tasks, optimistic]);
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return OfflineTaskMutationResult(value: optimistic, queuedOffline: true);
    }
  }

  Future<OfflineTaskMutationResult> updateTask(
    String uid,
    Map<String, dynamic> body, {
    TududiTask? current,
  }) async {
    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      final task = await client.updateTask(uid, body);
      await _upsertTaskEntity(task);
      return OfflineTaskMutationResult(value: task);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      final accountId = _accountId;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      final clientId = _uuid.v4();
      final base = current;
      await _cache.enqueueWrite(accountId, {
        'entity': 'task',
        'op': 'update',
        'clientId': clientId,
        'uid': uid,
        'body': body,
        if (base != null) 'base': _taskJson(base),
      });
      final fallback = base ??
          TududiTask(id: 0, name: body['name']?.toString() ?? '', uid: uid);
      final optimistic = TududiTask(
        id: fallback.id,
        name: body['name']?.toString() ?? fallback.name,
        uid: uid,
        note: body.containsKey('note')
            ? body['note']?.toString()
            : fallback.note,
        status: body['status'] is int
            ? body['status'] as int
            : int.tryParse(body['status']?.toString() ?? '') ??
                fallback.status,
        priority: body.containsKey('priority')
            ? body['priority']?.toString()
            : fallback.priority,
        dueDate: body.containsKey('due_date')
            ? body['due_date']?.toString()
            : fallback.dueDate,
        dueTime: fallback.dueTime,
        projectId: body.containsKey('project_id')
            ? (body['project_id'] is int
                ? body['project_id'] as int
                : int.tryParse(body['project_id']?.toString() ?? ''))
            : fallback.projectId,
        projectUid: body.containsKey('project_uid')
            ? body['project_uid']?.toString()
            : fallback.projectUid,
        projectName: body.containsKey('project_name')
            ? body['project_name']?.toString()
            : (body.containsKey('project_id') && body['project_id'] == null
                ? null
                : fallback.projectName),
        areaId: fallback.areaId,
        areaUid: fallback.areaUid,
        goalUid: fallback.goalUid,
        tags: fallback.tags,
        subtasks: fallback.subtasks,
        completedAt: fallback.completedAt,
        recurrenceType: body.containsKey('recurrence_type')
            ? body['recurrence_type']?.toString()
            : fallback.recurrenceType,
        recurrenceInterval: body.containsKey('recurrence_interval')
            ? (body['recurrence_interval'] is int
                ? body['recurrence_interval'] as int
                : int.tryParse(body['recurrence_interval']?.toString() ?? ''))
            : fallback.recurrenceInterval,
        recurrenceWeekday: body.containsKey('recurrence_weekday')
            ? (body['recurrence_weekday'] is int
                ? body['recurrence_weekday'] as int
                : int.tryParse(body['recurrence_weekday']?.toString() ?? ''))
            : fallback.recurrenceWeekday,
        recurrenceWeekdays: body.containsKey('recurrence_weekdays')
            ? _asIntList(body['recurrence_weekdays'])
            : fallback.recurrenceWeekdays,
        recurrenceMonthDay: body.containsKey('recurrence_month_day')
            ? (body['recurrence_month_day'] is int
                ? body['recurrence_month_day'] as int
                : int.tryParse(body['recurrence_month_day']?.toString() ?? ''))
            : fallback.recurrenceMonthDay,
        recurrenceWeekOfMonth: body.containsKey('recurrence_week_of_month')
            ? (body['recurrence_week_of_month'] is int
                ? body['recurrence_week_of_month'] as int
                : int.tryParse(
                    body['recurrence_week_of_month']?.toString() ?? '',
                  ))
            : fallback.recurrenceWeekOfMonth,
        recurrenceEndDate: body.containsKey('recurrence_end_date')
            ? body['recurrence_end_date']?.toString()
            : fallback.recurrenceEndDate,
        completionBased: body.containsKey('completion_based')
            ? body['completion_based'] == true
            : fallback.completionBased,
        originalName: fallback.originalName,
        todayMoveCount: fallback.todayMoveCount,
      );
      await _patchTaskSnapshots(accountId, (tasks) {
        return [
          for (final t in tasks)
            if (t.uid == uid) optimistic else t,
        ];
      });
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return OfflineTaskMutationResult(value: optimistic, queuedOffline: true);
    }
  }

  Future<OfflineTaskMutationResult> completeTask(
    String uid, {
    required bool done,
    TududiTask? current,
  }) async {
    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      final task = await client.completeTask(uid, done: done);
      await _upsertTaskEntity(task);
      return OfflineTaskMutationResult(value: task);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      final accountId = _accountId;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      final clientId = _uuid.v4();
      await _cache.enqueueWrite(accountId, {
        'entity': 'task',
        'op': 'complete',
        'clientId': clientId,
        'uid': uid,
        'body': {'done': done},
        if (current != null) 'base': _taskJson(current),
      });
      final base = current ??
          TududiTask(
            id: 0,
            name: '',
            uid: uid,
            status: done ? TaskStatus.notStarted : TaskStatus.done,
          );
      final optimistic = base.copyWith(
        status: done ? TaskStatus.done : TaskStatus.notStarted,
        completedAt: done ? DateTime.now().toIso8601String() : null,
      );
      await _patchTaskSnapshots(accountId, (tasks) {
        return [
          for (final t in tasks)
            if (t.uid == uid) optimistic else t,
        ];
      });
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return OfflineTaskMutationResult(value: optimistic, queuedOffline: true);
    }
  }

  Future<OfflineMutationResult<void>> deleteTask(
    String uid, {
    TududiTask? current,
  }) async {
    final accountId = _accountId;
    Future<void> removeLocal() async {
      if (accountId == null) return;
      await _patchTaskSnapshots(
        accountId,
        (tasks) => [for (final t in tasks) if (t.uid != uid) t],
      );
    }

    // Never-synced local creates: drop from cache only.
    if (uid.startsWith('local_')) {
      await removeLocal();
      return const OfflineMutationResult(value: null, queuedOffline: true);
    }

    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      await client.deleteTask(uid);
      await removeLocal();
      return const OfflineMutationResult(value: null);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      await _cache.enqueueWrite(accountId, {
        'entity': 'task',
        'op': 'delete',
        'clientId': _uuid.v4(),
        'uid': uid,
        'body': <String, dynamic>{},
        if (current != null) 'base': _taskJson(current),
      });
      await removeLocal();
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return const OfflineMutationResult(value: null, queuedOffline: true);
    }
  }

  Future<OfflineNoteMutationResult> createNote(Map<String, dynamic> body) async {
    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      final note = await client.createNote(body);
      await _cacheNote(note);
      return OfflineNoteMutationResult(value: note);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      final accountId = _accountId;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      final clientId = _uuid.v4();
      final localUid = 'local_$clientId';
      final optimistic = TududiNote(
        id: -DateTime.now().millisecondsSinceEpoch,
        title: (body['title'] ?? '').toString(),
        uid: localUid,
        content: body['content']?.toString(),
      );
      await _cache.enqueueWrite(accountId, {
        'entity': 'note',
        'op': 'create',
        'clientId': clientId,
        'localUid': localUid,
        'body': body,
      });
      await _patchNotes(accountId, (notes) => [...notes, optimistic]);
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return OfflineNoteMutationResult(value: optimistic, queuedOffline: true);
    }
  }

  Future<OfflineNoteMutationResult> updateNote(
    String uid,
    Map<String, dynamic> body, {
    TududiNote? current,
  }) async {
    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      final note = await client.updateNote(uid, body);
      await _cacheNote(note);
      return OfflineNoteMutationResult(value: note);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      final accountId = _accountId;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      final clientId = _uuid.v4();
      await _cache.enqueueWrite(accountId, {
        'entity': 'note',
        'op': 'update',
        'clientId': clientId,
        'uid': uid,
        'body': body,
        if (current != null) 'base': _noteJson(current),
        if (current?.updatedAt != null) 'baseUpdatedAt': current!.updatedAt,
      });
      final optimistic = TududiNote(
        id: current?.id ?? 0,
        title: body['title']?.toString() ?? current?.title ?? '',
        uid: uid,
        content: body['content']?.toString() ?? current?.content,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _patchNotes(accountId, (notes) {
        return [
          for (final n in notes)
            if (n.uid == uid) optimistic else n,
        ];
      });
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return OfflineNoteMutationResult(value: optimistic, queuedOffline: true);
    }
  }

  Future<OfflineMutationResult<void>> deleteNote(
    String uid, {
    TududiNote? current,
  }) async {
    final accountId = _accountId;
    Future<void> removeLocal() async {
      if (accountId == null) return;
      await _patchNotes(
        accountId,
        (notes) => [for (final n in notes) if (n.uid != uid) n],
      );
    }

    if (uid.startsWith('local_')) {
      await removeLocal();
      return const OfflineMutationResult(value: null, queuedOffline: true);
    }

    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      await client.deleteNote(uid);
      await removeLocal();
      return const OfflineMutationResult(value: null);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      await _cache.enqueueWrite(accountId, {
        'entity': 'note',
        'op': 'delete',
        'clientId': _uuid.v4(),
        'uid': uid,
        'body': <String, dynamic>{},
        if (current != null) 'base': _noteJson(current),
      });
      await removeLocal();
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return const OfflineMutationResult(value: null, queuedOffline: true);
    }
  }

  Future<OfflineMutationResult<void>> completeHabit(String uid) async {
    final client = await _ref.read(tududiClientProvider.future);
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    try {
      await client.completeHabit(uid);
      return const OfflineMutationResult(value: null);
    } on TududiApiException catch (e) {
      if (!_offlineActive || !e.isTransportFailure) rethrow;
      final accountId = _accountId;
      if (accountId == null) rethrow;
      _ref.read(syncStatusProvider.notifier).markOffline();

      await _cache.enqueueWrite(accountId, {
        'entity': 'habit',
        'op': 'complete',
        'clientId': _uuid.v4(),
        'uid': uid,
        'body': <String, dynamic>{},
      });
      _ref.read(syncStatusProvider.notifier).refreshPending();
      return const OfflineMutationResult(value: null, queuedOffline: true);
    }
  }

  Future<OfflineDrainStatus> drain() async {
    if (!_offlineActive) return OfflineDrainStatus.idle;
    final accountId = _accountId;
    final client = await _ref.read(tududiClientProvider.future);
    if (accountId == null || client == null) return OfflineDrainStatus.idle;

    final status = await drainWith(
      cache: _cache,
      client: client,
      accountId: accountId,
    );
    _ref.read(syncStatusProvider.notifier).markOnline();
    _ref.read(syncStatusProvider.notifier).refreshPending();
    return status;
  }

  static Future<OfflineDrainStatus> drainWith({
    required OfflineCachePort cache,
    required TududiClient client,
    required String accountId,
  }) async {
    final drift = cache is DriftOfflineCache ? cache : null;
    final pending = await cache.pendingWrites(accountId);
    if (pending.isEmpty) {
      final conflicts = drift == null
          ? const <Map<String, dynamic>>[]
          : await drift.conflictWritesAsync(accountId);
      return conflicts.isEmpty
          ? OfflineDrainStatus.idle
          : OfflineDrainStatus.hasConflicts;
    }

    var drainedAny = false;
    var sawConflict = false;

    for (final op in pending) {
      final outboxId = op['_outboxId'] as int?;
      try {
        final conflict = await _detectConflict(client, op);
        if (conflict != null) {
          sawConflict = true;
          if (drift != null && outboxId != null) {
            await drift.markConflict(outboxId, jsonEncode(conflict));
          }
          continue;
        }
        final mapped = await _replayOp(
          client,
          op,
          drift: drift,
          accountId: accountId,
        );
        if (mapped != null && drift != null) {
          await drift.mapLocalUid(
            accountId: accountId,
            localUid: mapped.$1,
            serverUid: mapped.$2,
          );
        }
        drainedAny = true;
        if (drift != null && outboxId != null) {
          await drift.removeOutbox(outboxId);
        }
      } on TududiApiException catch (e) {
        if (e.isUnauthorized) {
          return OfflineDrainStatus.stoppedUnauthorized;
        }
        if (e.isGone) {
          drainedAny = true;
          if (drift != null && outboxId != null) {
            await drift.removeOutbox(outboxId);
          }
          continue;
        }
        return OfflineDrainStatus.failed;
      } catch (_) {
        return OfflineDrainStatus.failed;
      }
    }

    if (drift == null) {
      // Prefs-style: rebuild remaining from conflicts only (pending drained inline).
      final left = await cache.pendingWrites(accountId);
      await cache.replaceQueue(accountId, left);
    }

    if (sawConflict) return OfflineDrainStatus.hasConflicts;
    return drainedAny ? OfflineDrainStatus.drained : OfflineDrainStatus.idle;
  }

  /// Keep local version: clear conflict and force push on next drain.
  Future<void> resolveKeepMine(int outboxId) async {
    final drift = _drift;
    if (drift == null) return;
    await drift.resolveKeepMine(outboxId);
    // Strip base so next drain won't re-conflict; force overwrite.
    final accountId = _accountId;
    if (accountId == null) return;
    final pending = await drift.pendingWrites(accountId);
    for (final op in pending) {
      if (op['_outboxId'] == outboxId) {
        op.remove('base');
        op.remove('baseUpdatedAt');
        op.remove('_outboxId');
        op.remove('_status');
        op.remove('_conflictServerJson');
        op['force'] = true;
        await drift.removeOutbox(outboxId);
        await drift.enqueueWrite(accountId, op);
        break;
      }
    }
    await drain();
  }

  /// Keep server version: drop outbox op and refresh local cache from server snapshot.
  Future<void> resolveKeepServer(int outboxId) async {
    final drift = _drift;
    final accountId = _accountId;
    if (drift == null || accountId == null) return;

    final conflicts = await drift.conflictWritesAsync(accountId);
    Map<String, dynamic>? op;
    for (final item in conflicts) {
      if (item['_outboxId'] == outboxId) {
        op = item;
        break;
      }
    }

    final serverRaw = op?['_conflictServerJson']?.toString();
    if (serverRaw != null && serverRaw.isNotEmpty) {
      try {
        final server = Map<String, dynamic>.from(jsonDecode(serverRaw) as Map);
        final entity = op?['entity']?.toString() ?? 'task';
        if (entity == 'note') {
          await _patchNotes(accountId, (notes) {
            final uid = server['uid']?.toString() ?? op?['uid']?.toString();
            return [
              for (final n in notes)
                if (n.uid == uid) TududiNote.fromJson(server) else n,
            ];
          });
        } else if (entity == 'task') {
          await _patchTaskSnapshots(accountId, (tasks) {
            final uid = server['uid']?.toString() ?? op?['uid']?.toString();
            return [
              for (final t in tasks)
                if (t.uid == uid) TududiTask.fromJson(server) else t,
            ];
          });
        }
      } catch (_) {}
    }

    await drift.removeOutbox(outboxId);
    _ref.read(syncStatusProvider.notifier).refreshPending();
    _ref.invalidate(tasksProvider);
    _ref.invalidate(notesProvider);
  }

  static Future<Map<String, dynamic>?> _detectConflict(
    TududiClient client,
    Map<String, dynamic> op,
  ) async {
    if (op['force'] == true) return null;
    final kind = op['op']?.toString();
    final entity = op['entity']?.toString() ?? 'task';
    final uid = op['uid']?.toString();
    if (kind == 'create' || uid == null || uid.startsWith('local_')) {
      return null;
    }

    try {
      if (entity == 'note' && (kind == 'update')) {
        final server = await client.getNote(uid);
        final baseUpdated = op['baseUpdatedAt']?.toString();
        final base = op['base'];
        if (baseUpdated != null &&
            server.updatedAt != null &&
            server.updatedAt != baseUpdated) {
          final localBody = op['body'] is Map
              ? Map<String, dynamic>.from(op['body'] as Map)
              : <String, dynamic>{};
          if (server.title != localBody['title'] ||
              (server.content ?? '') != (localBody['content'] ?? '')) {
            return _noteJson(server);
          }
        }
        if (base is Map) {
          final baseNote = TududiNote.fromJson(Map<String, dynamic>.from(base));
          if (baseNote.title != server.title ||
              (baseNote.content ?? '') != (server.content ?? '')) {
            final localBody = op['body'] is Map
                ? Map<String, dynamic>.from(op['body'] as Map)
                : <String, dynamic>{};
            if (server.title != localBody['title'] ||
                (server.content ?? '') != (localBody['content'] ?? '')) {
              return _noteJson(server);
            }
          }
        }
      }
      if (entity == 'task' && (kind == 'update' || kind == 'complete')) {
        final server = await client.getTask(uid);
        final base = op['base'];
        if (base is Map) {
          final baseTask =
              TududiTask.fromJson(Map<String, dynamic>.from(base));
          if (!_taskEquals(baseTask, server)) {
            // Server moved since enqueue.
            final body = op['body'] is Map
                ? Map<String, dynamic>.from(op['body'] as Map)
                : <String, dynamic>{};
            final localView = baseTask.copyWith(
              name: body['name']?.toString() ?? baseTask.name,
              note: body['note']?.toString() ?? baseTask.note,
              status: kind == 'complete'
                  ? ((body['done'] != false)
                      ? TaskStatus.done
                      : TaskStatus.notStarted)
                  : (body['status'] is int
                      ? body['status'] as int
                      : baseTask.status),
            );
            if (!_taskEquals(localView, server)) {
              return _taskJson(server);
            }
          }
        }
      }
    } on TududiApiException catch (e) {
      if (e.isGone) return null;
      rethrow;
    }
    return null;
  }

  /// Returns `(localUid, serverUid)` when a create needs id remapping.
  static Future<(String, String)?> _replayOp(
    TududiClient client,
    Map<String, dynamic> op, {
    DriftOfflineCache? drift,
    required String accountId,
  }) async {
    final kind = op['op']?.toString();
    final entity = op['entity']?.toString() ?? 'task';
    final body = op['body'] is Map
        ? Map<String, dynamic>.from(op['body'] as Map)
        : <String, dynamic>{};
    var uid = op['uid']?.toString();
    if (uid != null && uid.startsWith('local_') && drift != null) {
      uid = await drift.resolveUid(accountId, uid) ?? uid;
    }
    final localUid = op['localUid']?.toString();

    switch (entity) {
      case 'note':
        switch (kind) {
          case 'create':
            final note = await client.createNote(body);
            final serverUid = note.uid;
            if (localUid != null && serverUid != null) {
              return (localUid, serverUid);
            }
            return null;
          case 'update':
            if (uid == null || uid.startsWith('local_')) {
              throw TududiApiException(message: 'Missing uid', statusCode: 404);
            }
            await client.updateNote(uid, body);
            return null;
          case 'delete':
            if (uid == null || uid.startsWith('local_')) {
              throw TududiApiException(message: 'Missing uid', statusCode: 404);
            }
            await client.deleteNote(uid);
            return null;
          default:
            throw TududiApiException(message: 'Unknown op', statusCode: 404);
        }
      case 'habit':
        if (kind != 'complete' || uid == null) {
          throw TududiApiException(message: 'Unknown op', statusCode: 404);
        }
        await client.completeHabit(uid);
        return null;
      case 'task':
      default:
        switch (kind) {
          case 'create':
            final task = await client.createTask(body);
            final serverUid = task.uid;
            if (localUid != null && serverUid != null) {
              return (localUid, serverUid);
            }
            return null;
          case 'update':
            if (uid == null || uid.startsWith('local_')) {
              throw TududiApiException(message: 'Missing uid', statusCode: 404);
            }
            await client.updateTask(uid, body);
            return null;
          case 'complete':
            if (uid == null || uid.startsWith('local_')) {
              throw TududiApiException(message: 'Missing uid', statusCode: 404);
            }
            await client.completeTask(uid, done: body['done'] != false);
            return null;
          case 'delete':
            if (uid == null || uid.startsWith('local_')) {
              throw TududiApiException(message: 'Missing uid', statusCode: 404);
            }
            await client.deleteTask(uid);
            return null;
          default:
            throw TududiApiException(message: 'Unknown op', statusCode: 404);
        }
    }
  }

  Future<void> _upsertTaskEntity(TududiTask task) async {
    final accountId = _accountId;
    final uid = task.uid;
    if (accountId == null || uid == null) return;
    await _patchTaskSnapshots(accountId, (tasks) {
      var found = false;
      final next = <TududiTask>[];
      for (final t in tasks) {
        if (t.uid == uid) {
          next.add(task);
          found = true;
        } else {
          next.add(t);
        }
      }
      if (!found) next.insert(0, task);
      return next;
    });
  }

  Future<void> _cacheNote(TududiNote note) async {
    final accountId = _accountId;
    if (accountId == null) return;
    final raw = await _cache.getJson(accountId, 'notes');
    final list = raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    final uid = note.uid;
    var found = false;
    for (var i = 0; i < list.length; i++) {
      if (list[i]['uid']?.toString() == uid) {
        list[i] = _noteJson(note);
        found = true;
        break;
      }
    }
    if (!found) list.add(_noteJson(note));
    await _cache.putJson(accountId, 'notes', list);
  }

  Future<void> _patchTaskSnapshots(
    String accountId,
    List<TududiTask> Function(List<TududiTask> tasks) transform,
  ) async {
    for (final filter in TaskListFilter.values) {
      final bucket = 'tasks_${filter.name}';
      final raw = await _cache.getJson(accountId, bucket);
      if (raw is! List) continue;
      final tasks = raw
          .whereType<Map>()
          .map((e) => TududiTask.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final next = transform(tasks);
      await _cache.putJson(
        accountId,
        bucket,
        next.map(_taskJson).toList(),
      );
    }
  }

  Future<void> _patchNotes(
    String accountId,
    List<TududiNote> Function(List<TududiNote> notes) transform,
  ) async {
    final raw = await _cache.getJson(accountId, 'notes');
    final notes = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => TududiNote.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TududiNote>[];
    final next = transform(notes);
    await _cache.putJson(accountId, 'notes', next.map(_noteJson).toList());
  }

  static Map<String, dynamic> _taskJson(TududiTask t) => {
        'id': t.id,
        'uid': t.uid,
        'name': t.displayName,
        'status': t.status,
        'due_date': t.dueDate,
        'priority': t.priority,
        'project_name': t.projectName,
        if (t.note != null) 'note': t.note,
        if (t.completedAt != null) 'completed_at': t.completedAt,
        ...t.recurrenceToJson(),
      };

  static List<int> _asIntList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is int)
          item
        else if (item is num)
          item.toInt()
        else
          ...[
            if (int.tryParse(item.toString()) != null)
              int.parse(item.toString()),
          ],
    ];
  }

  static Map<String, dynamic> _noteJson(TududiNote n) => {
        'id': n.id,
        'uid': n.uid,
        'title': n.title,
        if (n.content != null) 'content': n.content,
        if (n.updatedAt != null) 'updated_at': n.updatedAt,
      };

  static bool _taskEquals(TududiTask a, TududiTask b) {
    return a.displayName == b.displayName &&
        a.status == b.status &&
        a.dueDate == b.dueDate &&
        a.priority == b.priority &&
        (a.note ?? '') == (b.note ?? '');
  }
}

final offlineWriteCoordinatorProvider = Provider<OfflineWriteCoordinator>((
  ref,
) {
  return OfflineWriteCoordinator(ref);
});

String? offlineQueuedMessage(OfflineMutationResult<dynamic> result) {
  if (!result.queuedOffline) return null;
  return 'Saved offline — will sync when online';
}

/// App-wide sync connectivity / pending state for the status indicator.
class SyncStatus {
  const SyncStatus({
    this.offline = false,
    this.pendingCount = 0,
    this.conflictCount = 0,
  });

  final bool offline;
  final int pendingCount;
  final int conflictCount;

  bool get hasPending => pendingCount > 0 || conflictCount > 0;
}

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  void markOffline() => state = SyncStatus(
        offline: true,
        pendingCount: state.pendingCount,
        conflictCount: state.conflictCount,
      );

  void markOnline() => state = SyncStatus(
        offline: false,
        pendingCount: state.pendingCount,
        conflictCount: state.conflictCount,
      );

  Future<void> refreshPending() async {
    final account = ref.read(activeAccountProvider);
    if (account == null) {
      state = SyncStatus(offline: state.offline);
      return;
    }
    final cache = ref.read(offlineCacheProvider);
    final pending = await cache.pendingCount(account.id);
    var conflicts = 0;
    if (cache is DriftOfflineCache) {
      conflicts = (await cache.conflictWritesAsync(account.id)).length;
    }
    // pendingCount from port includes conflicts for Drift; split for UI.
    final pendingOnly = pending > conflicts ? pending - conflicts : pending;
    state = SyncStatus(
      offline: state.offline,
      pendingCount: pendingOnly,
      conflictCount: conflicts,
    );
  }
}

final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);
