class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? accessExpires;
  final DateTime? refreshExpires;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessExpires,
    this.refreshExpires,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessExpires: parseDate(json['accessExpires'] ?? json['accessTokenExpiresAt']),
      refreshExpires: parseDate(json['refreshExpires'] ?? json['refreshTokenExpiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      if (accessExpires != null) 'accessExpires': accessExpires!.toIso8601String(),
      if (refreshExpires != null) 'refreshExpires': refreshExpires!.toIso8601String(),
    };
  }

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}
