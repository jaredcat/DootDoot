import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'account_profile.dart';
import 'account_secrets.dart';

class AccountStore {
  AccountStore(this._prefs, {AccountSecrets? secrets})
    : _secrets = secrets ?? AccountSecrets();

  static const _accountsKey = 'dootdoot.accounts';
  static const _activeKey = 'dootdoot.activeAccountId';

  final SharedPreferences _prefs;
  final AccountSecrets _secrets;
  final _uuid = const Uuid();

  List<AccountProfile> loadAccounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .whereType<Map>()
        .map((e) => AccountProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  String? get activeAccountId => _prefs.getString(_activeKey);

  AccountProfile? get activeAccount {
    final accounts = loadAccounts();
    if (accounts.isEmpty) return null;
    final id = activeAccountId;
    if (id == null) return accounts.first;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return accounts.first;
  }

  Future<void> setActiveAccountId(String id) async {
    await _prefs.setString(_activeKey, id);
    final accounts = loadAccounts();
    final updated = accounts
        .map((a) => a.id == id ? a.copyWith(lastUsedAt: DateTime.now()) : a)
        .toList();
    await _saveAccounts(updated);
  }

  AccountProfile? findDuplicate({
    required String baseUrl,
    required String email,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final a in loadAccounts()) {
      if (a.baseUrl == baseUrl &&
          a.email.trim().toLowerCase() == normalizedEmail) {
        return a;
      }
    }
    return null;
  }

  Future<AccountProfile> addAccount({
    required String baseUrl,
    required String email,
    required AccountAuthKind authKind,
    required String bearerToken,
    String? label,
    int? userId,
  }) async {
    final existing = findDuplicate(baseUrl: baseUrl, email: email);
    if (existing != null) {
      await _secrets.saveBearerToken(existing.id, bearerToken);
      final updated = existing.copyWith(
        authKind: authKind,
        lastUsedAt: DateTime.now(),
        userId: userId,
        label: label ?? existing.label,
      );
      await upsert(updated);
      await setActiveAccountId(updated.id);
      return updated;
    }

    final now = DateTime.now();
    final profile = AccountProfile(
      id: _uuid.v4(),
      baseUrl: baseUrl,
      label: label ?? email,
      email: email,
      authKind: authKind,
      createdAt: now,
      lastUsedAt: now,
      userId: userId,
    );
    await _secrets.saveBearerToken(profile.id, bearerToken);
    final accounts = [...loadAccounts(), profile];
    await _saveAccounts(accounts);
    await setActiveAccountId(profile.id);
    return profile;
  }

  Future<void> upsert(AccountProfile profile) async {
    final accounts = loadAccounts();
    final index = accounts.indexWhere((a) => a.id == profile.id);
    if (index >= 0) {
      accounts[index] = profile;
    } else {
      accounts.add(profile);
    }
    await _saveAccounts(accounts);
  }

  Future<void> rename(String id, String label) async {
    final accounts = loadAccounts();
    final index = accounts.indexWhere((a) => a.id == id);
    if (index < 0) return;
    accounts[index] = accounts[index].copyWith(label: label);
    await _saveAccounts(accounts);
  }

  Future<void> removeAccount(String id) async {
    final accounts = loadAccounts().where((a) => a.id != id).toList();
    await _secrets.deleteAll(id);
    await _saveAccounts(accounts);
    if (activeAccountId == id) {
      if (accounts.isEmpty) {
        await _prefs.remove(_activeKey);
      } else {
        await setActiveAccountId(accounts.first.id);
      }
    }
  }

  Future<String?> bearerTokenFor(String accountId) {
    return _secrets.readBearerToken(accountId);
  }

  Future<void> _saveAccounts(List<AccountProfile> accounts) async {
    final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _prefs.setString(_accountsKey, encoded);
  }
}
