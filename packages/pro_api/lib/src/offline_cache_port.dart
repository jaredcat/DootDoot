/// Per-account offline cache used by Pro. Free builds use [NoOpOfflineCache].
abstract class OfflineCachePort {
  Future<void> putJson(String accountId, String bucket, Object data);

  Object? getJson(String accountId, String bucket);

  Future<void> clearAccount(String accountId);

  Future<void> enqueueWrite(String accountId, Map<String, dynamic> op);

  List<Map<String, dynamic>> pendingWrites(String accountId);
}

class NoOpOfflineCache implements OfflineCachePort {
  const NoOpOfflineCache();

  @override
  Future<void> putJson(String accountId, String bucket, Object data) async {}

  @override
  Object? getJson(String accountId, String bucket) => null;

  @override
  Future<void> clearAccount(String accountId) async {}

  @override
  Future<void> enqueueWrite(
    String accountId,
    Map<String, dynamic> op,
  ) async {}

  @override
  List<Map<String, dynamic>> pendingWrites(String accountId) => const [];
}
