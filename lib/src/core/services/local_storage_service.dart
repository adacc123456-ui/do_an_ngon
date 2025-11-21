import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyIsAuthenticated = 'is_authenticated';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserEmail = 'user_email';
  static const String _keyCart = 'cart_items';
  static const String _keyFavorites = 'favorites';

  static const String _keyAuthTokens = 'auth_tokens';
  static const String _keyAuthUser = 'auth_user';
  static const String _keyIsVendor = 'is_vendor';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Auth methods
  Future<void> saveAuthState({
    required String userId,
    required String userName,
    String? phone,
    String? email,
  }) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyIsAuthenticated, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);
    if (phone != null) {
      await prefs.setString(_keyUserPhone, phone);
    }
    if (email != null) {
      await prefs.setString(_keyUserEmail, email);
    }
  }

  Future<Map<String, String?>> getAuthState() async {
    final prefs = await _prefs;
    final isAuthenticated = prefs.getBool(_keyIsAuthenticated) ?? false;

    if (!isAuthenticated) {
      return {'isAuthenticated': 'false'};
    }

    return {
      'isAuthenticated': 'true',
      'userId': prefs.getString(_keyUserId),
      'userName': prefs.getString(_keyUserName),
      'userPhone': prefs.getString(_keyUserPhone),
      'userEmail': prefs.getString(_keyUserEmail),
    };
  }

  Future<void> clearLegacyAuthState() async {
    final prefs = await _prefs;
    await prefs.remove(_keyIsAuthenticated);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserEmail);
  }

  Future<void> clearAuthState() async {
    await clearAuthData();
  }

  Future<void> updateUserInfo({
    String? name,
    String? phone,
    String? email,
  }) async {
    final prefs = await _prefs;
    if (name != null) {
      await prefs.setString(_keyUserName, name);
    }
    if (phone != null) {
      await prefs.setString(_keyUserPhone, phone);
    }
    if (email != null) {
      await prefs.setString(_keyUserEmail, email);
    }
  }

  Future<Map<String, dynamic>?> getAuthTokens() async {
    final prefs = await _prefs;
    final tokensJson = prefs.getString(_keyAuthTokens);
    if (tokensJson == null) return null;
    try {
      return jsonDecode(tokensJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    final tokens = await getAuthTokens();
    if (tokens == null) return null;
    return tokens['accessToken'] as String?;
  }

  Future<String?> getRefreshToken() async {
    final tokens = await getAuthTokens();
    if (tokens == null) return null;
    return tokens['refreshToken'] as String?;
  }

  Future<void> saveAuthTokens(Map<String, dynamic> tokens) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAuthTokens, jsonEncode(tokens));
  }

  Future<void> saveUserProfile(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAuthUser, jsonEncode(user));
    final isVendor = _isVendor(user);
    await prefs.setBool(_keyIsVendor, isVendor);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await _prefs;
    final userJson = prefs.getString(_keyAuthUser);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isVendorAccount() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyIsVendor) ?? false;
  }

  Future<void> clearAuthData() async {
    final prefs = await _prefs;
    await prefs.remove(_keyAuthTokens);
    await prefs.remove(_keyAuthUser);
    await prefs.remove(_keyIsVendor);
    await clearLegacyAuthState();
  }

  bool _isVendor(Map<String, dynamic> userJson) {
    if (userJson.containsKey('managedRestaurants')) {
      final managed = userJson['managedRestaurants'];
      if (managed is List && managed.isNotEmpty) {
        return true;
      }
    }
    if (userJson['role'] == 'vendor' || userJson['role'] == 'restaurant_owner') {
      return true;
    }
    return false;
  }

  // Cart methods
  Future<void> saveCart(String cartJson) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCart, cartJson);
  }

  Future<String?> getCart() async {
    final prefs = await _prefs;
    return prefs.getString(_keyCart);
  }

  Future<void> clearCart() async {
    final prefs = await _prefs;
    await prefs.remove(_keyCart);
  }

  // Favorites methods
  Future<void> saveFavorites(String favoritesJson) async {
    final prefs = await _prefs;
    await prefs.setString(_keyFavorites, favoritesJson);
  }

  Future<String?> getFavorites() async {
    final prefs = await _prefs;
    return prefs.getString(_keyFavorites);
  }

  Future<void> clearFavorites() async {
    final prefs = await _prefs;
    await prefs.remove(_keyFavorites);
  }
}

