import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tududi_api/tududi_api.dart';

import 'accounts/account_profile.dart';
import 'accounts/account_session.dart';
import 'accounts/account_store.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main()');
});

final accountStoreProvider = Provider<AccountStore>((ref) {
  return AccountStore(ref.watch(sharedPreferencesProvider));
});

final accountSessionProvider = Provider<AccountSessionService>((ref) {
  return AccountSessionService(ref.watch(accountStoreProvider));
});

final accountsProvider =
    NotifierProvider<AccountsNotifier, List<AccountProfile>>(
      AccountsNotifier.new,
    );

final activeAccountIdProvider =
    NotifierProvider<ActiveAccountIdNotifier, String?>(
      ActiveAccountIdNotifier.new,
    );

final activeAccountProvider = Provider<AccountProfile?>((ref) {
  final id = ref.watch(activeAccountIdProvider);
  final accounts = ref.watch(accountsProvider);
  if (accounts.isEmpty) return null;
  if (id == null) return accounts.first;
  for (final account in accounts) {
    if (account.id == id) return account;
  }
  return accounts.first;
});

final tududiClientProvider = FutureProvider<TududiClient?>((ref) async {
  final account = ref.watch(activeAccountProvider);
  final session = ref.watch(accountSessionProvider);
  return session.clientFor(account);
});

final offlineCacheProvider = Provider<OfflineCachePort>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ref.watch(proControllerProvider.notifier).createOfflineCache(prefs);
});

class AccountsNotifier extends Notifier<List<AccountProfile>> {
  @override
  List<AccountProfile> build() {
    return ref.watch(accountStoreProvider).loadAccounts();
  }

  void refresh() {
    state = ref.read(accountStoreProvider).loadAccounts();
  }
}

class ActiveAccountIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.watch(accountStoreProvider).activeAccountId;
  }

  Future<void> switchTo(String id) async {
    await ref.read(accountStoreProvider).setActiveAccountId(id);
    state = id;
    ref.read(accountsProvider.notifier).refresh();
    ref.invalidate(tududiClientProvider);
  }
}
