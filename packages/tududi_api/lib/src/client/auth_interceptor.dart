import 'package:dio/dio.dart';

/// Supplies Bearer token and/or CSRF header for mutating session requests.
class TududiAuthInterceptor extends Interceptor {
  TududiAuthInterceptor({
    this.getBearerToken,
    this.getCsrfToken,
  });

  final Future<String?> Function()? getBearerToken;
  final Future<String?> Function()? getCsrfToken;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await getBearerToken?.call();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else if (_isMutating(options.method)) {
        final csrf = await getCsrfToken?.call();
        if (csrf != null && csrf.isNotEmpty) {
          options.headers['x-csrf-token'] = csrf;
        }
      }
      handler.next(options);
    } catch (e, st) {
      handler.reject(
        DioException(requestOptions: options, error: e, stackTrace: st),
      );
    }
  }

  bool _isMutating(String method) {
    final m = method.toUpperCase();
    return m == 'POST' || m == 'PUT' || m == 'PATCH' || m == 'DELETE';
  }
}
