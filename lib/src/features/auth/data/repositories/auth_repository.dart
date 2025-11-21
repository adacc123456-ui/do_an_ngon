import 'package:dio/dio.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/network/api_client.dart';
import 'package:do_an_ngon/src/features/auth/data/models/auth_response.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic> && nestedData.isNotEmpty) {
        return nestedData;
      }
      return data;
    }
    return <String, dynamic>{};
  }

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      final payload = _extractPayload(response.data);
      final authResponse = AuthResponse.fromJson(payload);
      if (!authResponse.isValid) {
        throw const ApiException(message: 'Phản hồi đăng nhập không hợp lệ');
      }
      return authResponse;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      final payload = _extractPayload(response.data);
      final authResponse = AuthResponse.fromJson(payload);
      if (!authResponse.isValid) {
        throw const ApiException(message: 'Phản hồi refresh token không hợp lệ');
      }
      return authResponse;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode >= 500 || statusCode == 0) {
        throw ApiException(
          message: _extractErrorMessage(e),
          statusCode: statusCode,
        );
      }
      // Nếu logout bị 401/403 thì coi như token hết hạn => bỏ qua
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    List<String>? favoriteCuisines,
    List<String>? dietaryRestrictions,
    String accountType = 'user',
    List<String>? managedRestaurantIds,
    Map<String, dynamic>? vendorRestaurant,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'accountType': accountType,
          if (favoriteCuisines != null && favoriteCuisines.isNotEmpty) 'favoriteCuisines': favoriteCuisines,
          if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty)
            'dietaryRestrictions': dietaryRestrictions,
          if (managedRestaurantIds != null && managedRestaurantIds.isNotEmpty)
            'managedRestaurantIds': managedRestaurantIds,
          if (vendorRestaurant != null && vendorRestaurant.isNotEmpty)
            'vendorRestaurant': vendorRestaurant,
        },
      );

      final payload = _extractPayload(response.data);
      // Backend mới trả về { requiresVerification: true, email: "..." } thay vì tokens
      return payload;
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<void> requestEmailVerification({required String email}) async {
    try {
      await _apiClient.dio.post(
        '/auth/verification/request',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<AuthResponse> confirmEmailVerification({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verification/confirm',
        data: {
          'email': email,
          'code': code,
        },
      );

      final payload = _extractPayload(response.data);
      // Backend mới trả về { user, tokens } sau khi tạo tài khoản
      final authResponse = AuthResponse.fromJson(payload);
      if (!authResponse.isValid) {
        throw const ApiException(message: 'Phản hồi xác minh email không hợp lệ');
      }
      return authResponse;
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      final payload = _extractPayload(response.data);
      return payload['user'] as Map<String, dynamic>? ?? payload;
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      // Email không thể cập nhật trực tiếp qua API này, cần xác minh lại
      // if (email != null) updateData['email'] = email;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;

      final response = await _apiClient.dio.put(
        '/users/me',
        data: updateData,
      );
      final payload = _extractPayload(response.data);
      return payload['user'] as Map<String, dynamic>? ?? payload;
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
        data: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  String _extractErrorMessage(DioException exception) {
    final responseData = exception.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      final error = responseData['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }
    if (exception.message != null && exception.message!.isNotEmpty) {
      return exception.message!;
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
