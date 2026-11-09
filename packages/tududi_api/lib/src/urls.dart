/// Known Tududi endpoints and helpers for normalizing base URLs.
abstract final class TududiUrls {
  static const cloud = 'https://app.tududi.com';

  /// Normalize user input into an origin with scheme, no trailing slash.
  static String normalizeBaseUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      throw ArgumentError('Server URL is required');
    }
    if (!value.contains('://')) {
      value = 'https://$value';
    }
    final uri = Uri.parse(value);
    if (uri.host.isEmpty) {
      throw ArgumentError('Invalid server URL');
    }
    final port = uri.hasPort ? ':${uri.port}' : '';
    final path = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    // Drop trailing path that looks like /api — users sometimes paste API URLs.
    final cleanedPath = path == '/api' || path == '/api/v1' ? '' : path;
    return '${uri.scheme}://${uri.host}$port$cleanedPath';
  }

  static bool isCloud(String baseUrl) {
    final host = Uri.parse(normalizeBaseUrl(baseUrl)).host;
    return host == 'app.tududi.com' || host == 'tududi.com';
  }
}
