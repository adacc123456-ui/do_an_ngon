class AuthResponse {
  final Map<String, dynamic> user;
  final String accessToken;
  final String refreshToken;
  final DateTime? accessExpires;
  final DateTime? refreshExpires;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.accessExpires,
    this.refreshExpires,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = (json['user'] ?? json['data']?['user']) as Map<String, dynamic>?;
    final tokensJson = (json['tokens'] ?? json['data']?['tokens']) as Map<String, dynamic>?;

    if (userJson == null || tokensJson == null) {
      throw const FormatException('Invalid auth response format');
    }

    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AuthResponse(
      user: userJson,
      accessToken: tokensJson['accessToken'] as String? ?? '',
      refreshToken: tokensJson['refreshToken'] as String? ?? '',
      accessExpires: _parseDate(tokensJson['accessExpires']),
      refreshExpires: _parseDate(tokensJson['refreshExpires']),
    );
  }

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;

  bool get isVendor {
    if (user.containsKey('managedRestaurants')) {
      final managed = user['managedRestaurants'];
      if (managed is List && managed.isNotEmpty) {
        return true;
      }
    }
    final role = user['role'];
    return role == 'vendor' || role == 'restaurant_owner';
  }

  String? get userId => user['id']?.toString() ?? user['_id']?.toString();
  String? get name => user['name']?.toString();
  String? get phone => user['phone']?.toString();
  String? get email => user['email']?.toString();
}
