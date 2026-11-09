import 'package:cookie_jar/cookie_jar.dart';
import 'package:tududi_api/tududi_api.dart';

import 'account_profile.dart';
import 'account_store.dart';

/// Handles sign-in against a Tududi server and persists a Bearer token.
class AccountSessionService {
  AccountSessionService(this._store);

  final AccountStore _store;
  final _factory = const TududiClientFactory();

  Future<AccountProfile> signInWithPassword({
    required String baseUrl,
    required String email,
    required String password,
    String? label,
  }) async {
    final normalized = TududiUrls.normalizeBaseUrl(baseUrl);
    final jar = CookieJar();
    final sessionClient = _factory.create(
      TududiClientConfig(baseUrl: normalized, cookieJar: jar),
    );

    await sessionClient.probeServer();
    final login = await sessionClient.login(email: email, password: password);

    // Prefer API token so mutating calls skip CSRF (session writes need it).
    final withCsrf = _factory.create(
      TududiClientConfig(
        baseUrl: normalized,
        cookieJar: jar,
        getCsrfToken: sessionClient.fetchCsrfToken,
      ),
    );
    final created = await withCsrf.createApiKey(name: 'DootDoot Mobile');
    final token = created.token;
    if (token.isEmpty) {
      throw TududiApiException(message: 'Server returned an empty API token');
    }

    return _store.addAccount(
      baseUrl: normalized,
      email: login.user.email.isNotEmpty ? login.user.email : email,
      authKind: AccountAuthKind.apiToken,
      bearerToken: token,
      label: label ?? login.user.name ?? email,
      userId: login.user.id,
    );
  }

  Future<AccountProfile> signInWithApiToken({
    required String baseUrl,
    required String token,
    String? label,
  }) async {
    final normalized = TududiUrls.normalizeBaseUrl(baseUrl);
    final client = _factory.create(
      TududiClientConfig(baseUrl: normalized, bearerToken: token),
    );
    await client.probeServer();
    final user = await client.currentUser();
    return _store.addAccount(
      baseUrl: normalized,
      email: user.email,
      authKind: AccountAuthKind.apiToken,
      bearerToken: token,
      label: label ?? user.name ?? user.email,
      userId: user.id,
    );
  }

  Future<TududiClient?> clientFor(AccountProfile? profile) async {
    if (profile == null) return null;
    final token = await _store.bearerTokenFor(profile.id);
    if (token == null || token.isEmpty) return null;
    return _factory.create(
      TududiClientConfig(baseUrl: profile.baseUrl, bearerToken: token),
    );
  }
}
