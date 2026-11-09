import 'package:equatable/equatable.dart';

enum AccountAuthKind { session, apiToken, oidc }

class AccountProfile extends Equatable {
  const AccountProfile({
    required this.id,
    required this.baseUrl,
    required this.label,
    required this.email,
    required this.authKind,
    required this.createdAt,
    required this.lastUsedAt,
    this.userId,
  });

  final String id;
  final String baseUrl;
  final String label;
  final String email;
  final AccountAuthKind authKind;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final int? userId;

  Uri get hostUri => Uri.parse(baseUrl);
  String get hostLabel => hostUri.host;

  AccountProfile copyWith({
    String? label,
    String? email,
    AccountAuthKind? authKind,
    DateTime? lastUsedAt,
    int? userId,
  }) {
    return AccountProfile(
      id: id,
      baseUrl: baseUrl,
      label: label ?? this.label,
      email: email ?? this.email,
      authKind: authKind ?? this.authKind,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'baseUrl': baseUrl,
    'label': label,
    'email': email,
    'authKind': authKind.name,
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt.toIso8601String(),
    'userId': userId,
  };

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      id: json['id'] as String,
      baseUrl: json['baseUrl'] as String,
      label: json['label'] as String? ?? json['email'] as String? ?? 'Account',
      email: json['email'] as String? ?? '',
      authKind: AccountAuthKind.values.firstWhere(
        (e) => e.name == json['authKind'],
        orElse: () => AccountAuthKind.apiToken,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastUsedAt:
          DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ??
          DateTime.now(),
      userId: json['userId'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, baseUrl, email, authKind];
}
