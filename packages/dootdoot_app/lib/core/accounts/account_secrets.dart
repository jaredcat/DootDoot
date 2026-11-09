import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountSecrets {
  AccountSecrets({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveBearerToken(String accountId, String token) {
    return _storage.write(key: _tokenKey(accountId), value: token);
  }

  Future<String?> readBearerToken(String accountId) {
    return _storage.read(key: _tokenKey(accountId));
  }

  Future<void> deleteAll(String accountId) async {
    await _storage.delete(key: _tokenKey(accountId));
    await _storage.delete(key: _cookieKey(accountId));
  }

  Future<void> saveCookieBlob(String accountId, String blob) {
    return _storage.write(key: _cookieKey(accountId), value: blob);
  }

  Future<String?> readCookieBlob(String accountId) {
    return _storage.read(key: _cookieKey(accountId));
  }

  String _tokenKey(String id) => 'account/$id/bearer';
  String _cookieKey(String id) => 'account/$id/cookies';
}
