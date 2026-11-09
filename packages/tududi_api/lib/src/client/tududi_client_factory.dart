import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../urls.dart';
import 'auth_interceptor.dart';
import 'tududi_client.dart';

class TududiClientConfig {
  const TududiClientConfig({
    required this.baseUrl,
    this.bearerToken,
    this.cookieJar,
    this.getCsrfToken,
  });

  final String baseUrl;
  final String? bearerToken;
  final CookieJar? cookieJar;
  final Future<String?> Function()? getCsrfToken;
}

/// Builds a [TududiClient] scoped to one account / server.
class TududiClientFactory {
  const TududiClientFactory();

  TududiClient create(TududiClientConfig config) {
    final baseUrl = TududiUrls.normalizeBaseUrl(config.baseUrl);
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    final jar = config.cookieJar;
    if (jar != null) {
      dio.interceptors.add(CookieManager(jar));
    }

    dio.interceptors.add(
      TududiAuthInterceptor(
        getBearerToken: () async => config.bearerToken,
        getCsrfToken: config.getCsrfToken,
      ),
    );

    return TududiClient(dio: dio, baseUrl: baseUrl);
  }
}
