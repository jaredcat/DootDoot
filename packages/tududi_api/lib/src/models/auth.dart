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
    return ApiKeyCreated(
      token: (json['token'] ?? '').toString(),
      id: _asInt(apiKey['id']),
      name: (apiKey['name'] ?? 'DootDoot').toString(),
      tokenPrefix: apiKey['token_prefix']?.toString(),
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
