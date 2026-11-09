import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Per-account offline cache used by Pro. Free builds use [NoOpOfflineCache].
abstract class OfflineCachePort {
  Future<void> putJson(String accountId, String bucket, Object data);

  Future<Object?> getJson(String accountId, String bucket);

  Future<void> clearAccount(String accountId);

  Future<void> enqueueWrite(String accountId, Map<String, dynamic> op);

  Future<List<Map<String, dynamic>>> pendingWrites(String accountId);

  /// Replace the entire pending write queue (used after a partial drain).
  Future<void> replaceQueue(
    String accountId,
    List<Map<String, dynamic>> ops,
  );

  /// Pending + conflict outbox count (for status indicator).
  Future<int> pendingCount(String accountId) async {
    final pending = await pendingWrites(accountId);
    return pending.length;
  }
}

class NoOpOfflineCache implements OfflineCachePort {
  const NoOpOfflineCache();

  @override
  Future<void> putJson(String accountId, String bucket, Object data) async {}

  @override
  Future<Object?> getJson(String accountId, String bucket) async => null;

  @override
  Future<void> clearAccount(String accountId) async {}

  @override
  Future<void> enqueueWrite(
    String accountId,
    Map<String, dynamic> op,
  ) async {}

  @override
  Future<List<Map<String, dynamic>>> pendingWrites(String accountId) async =>
      const [];

  @override
  Future<void> replaceQueue(
    String accountId,
    List<Map<String, dynamic>> ops,
  ) async {}

  @override
  Future<int> pendingCount(String accountId) async => 0;
}

/// Legacy SharedPreferences cache (migration source / tests).
class PrefsOfflineCache implements OfflineCachePort {
  PrefsOfflineCache(this._prefs);

  final SharedPreferences _prefs;

  String _key(String accountId, String bucket) =>
      'dootdoot.offline.$accountId.$bucket';

  @override
  Future<void> putJson(
    String accountId,
    String bucket,
    Object data,
  ) async {
    await _prefs.setString(_key(accountId, bucket), jsonEncode(data));
  }

  @override
  Future<Object?> getJson(String accountId, String bucket) async {
    final raw = _prefs.getString(_key(accountId, bucket));
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  @override
  Future<void> clearAccount(String accountId) async {
    final prefix = 'dootdoot.offline.$accountId.';
    for (final key in _prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await _prefs.remove(key);
    }
  }

  @override
  Future<void> enqueueWrite(
    String accountId,
    Map<String, dynamic> op,
  ) async {
    final existing = await getJson(accountId, 'queue');
    final list = existing is List
        ? existing.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    list.add({...op, 'enqueuedAt': DateTime.now().toIso8601String()});
    await putJson(accountId, 'queue', list);
  }

  @override
  Future<List<Map<String, dynamic>>> pendingWrites(String accountId) async {
    final existing = await getJson(accountId, 'queue');
    if (existing is! List) return const [];
    return existing
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Future<void> replaceQueue(
    String accountId,
    List<Map<String, dynamic>> ops,
  ) async {
    if (ops.isEmpty) {
      await _prefs.remove(_key(accountId, 'queue'));
      return;
    }
    await putJson(accountId, 'queue', ops);
  }

  @override
  Future<int> pendingCount(String accountId) async {
    final pending = await pendingWrites(accountId);
    return pending.length;
  }
}
