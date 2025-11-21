class UserProfile {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final bool emailVerified;
  final bool phoneVerified;
  final List<String> managedRestaurants;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? raw;

  const UserProfile({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.managedRestaurants = const [],
    this.preferences,
    this.raw,
  });

  bool get isVendor => managedRestaurants.isNotEmpty;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    final managed = userJson['managedRestaurants'];
    final managedList = <String>[];
    if (managed is List) {
      for (final item in managed) {
        if (item is String) {
          managedList.add(item);
        } else if (item is Map<String, dynamic> && item['_id'] is String) {
          managedList.add(item['_id'] as String);
        }
      }
    }

    return UserProfile(
      id: userJson['_id'] as String? ?? userJson['id'] as String? ?? '',
      email: userJson['email'] as String?,
      name: userJson['name'] as String?,
      phone: userJson['phone'] as String?,
      emailVerified: userJson['emailVerified'] as bool? ?? false,
      phoneVerified: userJson['phoneVerified'] as bool? ?? false,
      managedRestaurants: managedList,
      preferences: userJson['preferences'] is Map<String, dynamic>
          ? userJson['preferences'] as Map<String, dynamic>
          : null,
      raw: userJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'managedRestaurants': managedRestaurants,
      if (preferences != null) 'preferences': preferences,
      if (raw != null) 'raw': raw,
    };
  }
}
