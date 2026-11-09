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

  @override
  String toString() => 'TududiApiException($statusCode): $message';
}

class TududiUnsupportedServerException implements Exception {
  TududiUnsupportedServerException([this.message = 'Unsupported Tududi server']);

  final String message;

  @override
  String toString() => message;
}
