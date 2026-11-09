class TududiApiException implements Exception {
  TududiApiException({
    required this.message,
    this.statusCode,
    this.body,
  });

  final String message;
  final int? statusCode;
  final Object? body;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  /// No HTTP response — typically offline or DNS/TLS failure.
  bool get isTransportFailure => statusCode == null;

  bool get isGone => statusCode == 404 || statusCode == 410;

  @override
  String toString() => 'TududiApiException($statusCode): $message';
}

class TududiUnsupportedServerException implements Exception {
  TududiUnsupportedServerException([this.message = 'Unsupported tududi server']);

  final String message;

  @override
  String toString() => message;
}
