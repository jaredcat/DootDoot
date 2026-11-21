import 'package:equatable/equatable.dart';

import 'user.dart';

class LoginResult extends Equatable {
  const LoginResult({required this.user});

  final TududiUser user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    return LoginResult(user: TududiUser.fromJson(userJson));
  }

  @override
  List<Object?> get props => [user];
}

class ApiKeyInfo extends Equatable {
  const ApiKeyInfo({
    required this.id,
    required this.name,
    this.tokenPrefix,
    this.createdAt,
    this.lastUsedAt,
    this.expiresAt,
    this.revokedAt,
  });

  final int id;
  final String name;
  final String? tokenPrefix;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) {
    return ApiKeyInfo(
      id: _asInt(json['id']),
      name: (json['name'] ?? 'DootDoot').toString(),
      tokenPrefix: json['token_prefix']?.toString(),
      createdAt: _asDateTime(json['created_at']),
      lastUsedAt: _asDateTime(json['last_used_at']),
      expiresAt: _asDateTime(json['expires_at']),
      revokedAt: _asDateTime(json['revoked_at']),
    );
  }

  @override
  List<Object?> get props => [id, name, tokenPrefix, revokedAt];
}

class ApiKeyCreated extends Equatable {
  const ApiKeyCreated({
    required this.token,
    required this.id,
    required this.name,
    this.tokenPrefix,
  });

  final String token;
  final int id;
  final String name;
  final String? tokenPrefix;

  factory ApiKeyCreated.fromJson(Map<String, dynamic> json) {
    final apiKey = json['apiKey'] is Map<String, dynamic>
        ? json['apiKey'] as Map<String, dynamic>
        : json;
    final info = ApiKeyInfo.fromJson(apiKey);
    return ApiKeyCreated(
      token: (json['token'] ?? '').toString(),
      id: info.id,
      name: info.name,
      tokenPrefix: info.tokenPrefix,
    );
  }

  @override
  List<Object?> get props => [token, id, name, tokenPrefix];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
