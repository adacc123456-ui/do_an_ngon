import 'package:dio/dio.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/network/api_client.dart';
import 'package:do_an_ngon/src/features/account/domain/entities/user_address.dart';

class UserAddressRepository {
  final ApiClient _apiClient;

  UserAddressRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<UserAddress>> getAddresses() async {
    try {
      final response = await _apiClient.dio.get('/users/me/addresses');
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : (data is List ? data : []);

      return items
          .map((item) => UserAddress.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải danh sách địa chỉ');
    }
  }

  Future<UserAddress> createAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String street,
    required String ward,
    required String district,
    required String city,
    String? note,
    bool isDefault = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/users/me/addresses',
        data: {
          'label': label,
          'recipientName': recipientName,
          'phone': phone,
          'street': street,
          'ward': ward,
          'district': district,
          'city': city,
          if (note != null && note.isNotEmpty) 'note': note,
          'isDefault': isDefault,
        },
      );
      final data = response.data;
      final addressData = data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>? ?? data)
          : data;
      return UserAddress.fromJson(addressData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tạo địa chỉ');
    }
  }

  Future<UserAddress> updateAddress({
    required String addressId,
    String? label,
    String? recipientName,
    String? phone,
    String? street,
    String? ward,
    String? district,
    String? city,
    String? note,
    bool? isDefault,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (label != null) updateData['label'] = label;
      if (recipientName != null) updateData['recipientName'] = recipientName;
      if (phone != null) updateData['phone'] = phone;
      if (street != null) updateData['street'] = street;
      if (ward != null) updateData['ward'] = ward;
      if (district != null) updateData['district'] = district;
      if (city != null) updateData['city'] = city;
      if (note != null) updateData['note'] = note;
      if (isDefault != null) updateData['isDefault'] = isDefault;

      final response = await _apiClient.dio.put(
        '/users/me/addresses/$addressId',
        data: updateData,
      );
      final data = response.data;
      final addressData = data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>? ?? data)
          : data;
      return UserAddress.fromJson(addressData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể cập nhật địa chỉ');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _apiClient.dio.delete('/users/me/addresses/$addressId');
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể xóa địa chỉ');
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _apiClient.dio.patch('/users/me/addresses/$addressId/default');
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể đặt địa chỉ mặc định');
    }
  }

  ApiException _mapException(DioException exception, {required String defaultMessage}) {
    final response = exception.response;
    String message = defaultMessage;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      final dataMessage = data['message'] ?? data['error'];
      if (dataMessage is String && dataMessage.isNotEmpty) {
        message = dataMessage;
      }
    } else if (exception.message != null && exception.message!.isNotEmpty) {
      message = exception.message!;
    }

    return ApiException(
      message: message,
      statusCode: response?.statusCode,
      data: response?.data is Map<String, dynamic> ? response?.data as Map<String, dynamic> : null,
    );
  }
}

