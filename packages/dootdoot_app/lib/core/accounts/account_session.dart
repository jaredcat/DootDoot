import 'package:cookie_jar/cookie_jar.dart';
import 'package:tududi_api/tududi_api.dart';

import 'account_profile.dart';
import 'account_store.dart';
import 'device_install_identity.dart';

/// Handles sign-in against a Tududi server and persists a Bearer token.
class AccountSessionService {
  AccountSessionService(
    this._store, {
    DeviceInstallIdentity? deviceIdentity,
    TududiClientFactory? clientFactory,
  }) : _deviceIdentity = deviceIdentity ?? DeviceInstallIdentity(),
       _factory = clientFactory ?? const TududiClientFactory();

  final AccountStore _store;
  final DeviceInstallIdentity _deviceIdentity;
  final TududiClientFactory _factory;

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
    final resolvedEmail = login.user.email.isNotEmpty
        ? login.user.email
        : email;
    final resolvedLabel = label ?? login.user.name ?? email;

    final reused = await _tryReuseStoredToken(
      baseUrl: normalized,
      email: resolvedEmail,
      label: resolvedLabel,
      userId: login.user.id,
    );
    if (reused != null) return reused;

    // Prefer API token so mutating calls skip CSRF (session writes need it).
    final withCsrf = _factory.create(
      TududiClientConfig(
        baseUrl: normalized,
        cookieJar: jar,
        getCsrfToken: sessionClient.fetchCsrfToken,
      ),
    );
    final keyName = await _deviceIdentity.apiKeyName();
    final ApiKeyCreated created;
    try {
      created = await withCsrf.createApiKey(name: keyName);
    } on TududiApiException catch (e) {
      throw _mapApiKeyCreateError(e);
    }
    final token = created.token;
    if (token.isEmpty) {
      throw TududiApiException(message: 'Server returned an empty API token');
    }

    return _store.addAccount(
      baseUrl: normalized,
      email: resolvedEmail,
      authKind: AccountAuthKind.apiToken,
      bearerToken: token,
      label: resolvedLabel,
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

  /// If this account is already on device with a working token, reuse it.
  Future<AccountProfile?> _tryReuseStoredToken({
    required String baseUrl,
    required String email,
    required String label,
    int? userId,
  }) async {
    final existing = _store.findDuplicate(baseUrl: baseUrl, email: email);
    if (existing == null) return null;
    final token = await _store.bearerTokenFor(existing.id);
    if (token == null || token.isEmpty) return null;

    try {
      final client = _factory.create(
        TududiClientConfig(baseUrl: baseUrl, bearerToken: token),
      );
      await client.currentUser();
    } catch (_) {
      return null;
    }

    return _store.addAccount(
      baseUrl: baseUrl,
      email: email,
      authKind: AccountAuthKind.apiToken,
      bearerToken: token,
      label: label,
      userId: userId,
    );
  }

  TududiApiException _mapApiKeyCreateError(TududiApiException e) {
    if (!e.isRateLimited) return e;
    return TududiApiException(
      message:
          'This tududi server rate-limits API key changes (about 10/hour). '
          'Wait and try again, or use Advanced and paste an existing key from '
          'Profile → API Keys.',
      statusCode: e.statusCode ?? 429,
      body: e.body,
    );
  }
}
