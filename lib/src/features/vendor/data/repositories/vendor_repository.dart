import 'package:dio/dio.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/network/api_client.dart';

class VendorRepository {
  final ApiClient _apiClient;

  VendorRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Lấy danh sách đơn hàng của nhà hàng
  Future<List<Map<String, dynamic>>> getVendorOrders({
    String? status,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['fromDate'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['toDate'] = toDate;
      }

      final response = await _apiClient.dio.get(
        '/vendor/orders',
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> items = [];
      
      if (data is Map<String, dynamic>) {
        final dataObj = data['data'];
        if (dataObj is Map<String, dynamic>) {
          // Response có cấu trúc: { "data": { "items": [...], "total": ... } }
          items = dataObj['items'] as List<dynamic>? ?? [];
        } else if (dataObj is List<dynamic>) {
          // Fallback: nếu data['data'] là List trực tiếp
          items = dataObj;
        }
      } else if (data is List) {
        items = data;
      }

      return items.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải danh sách đơn hàng');
    }
  }

  /// Cập nhật trạng thái đơn hàng
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/vendor/orders/$orderId/status',
        data: {
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

      final data = response.data;
      return data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>? ?? data)
          : {'message': 'Cập nhật thành công'};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể cập nhật trạng thái đơn hàng');
    }
  }

  /// Cập nhật thời gian giao hàng ước tính cho đơn
  Future<Map<String, dynamic>> updateDeliveryEstimate({
    required String orderId,
    required int minMinutes,
    required int maxMinutes,
    int? preparationTimeMinutes,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'estimatedDeliveryTime': {
          'min': minMinutes,
          'max': maxMinutes,
        },
      };

      if (preparationTimeMinutes != null) {
        payload['preparationTimeMinutes'] = preparationTimeMinutes;
      }

      if (note != null && note.isNotEmpty) {
        payload['note'] = note;
      }

      final response = await _apiClient.dio.patch(
        '/vendor/orders/$orderId/estimate',
        data: payload,
      );

      final data = response.data;
      return data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>? ?? data)
          : {'message': 'Đã cập nhật thời gian giao hàng'};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể cập nhật thời gian giao dự kiến');
    }
  }

  /// Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final response = await _apiClient.dio.get('/orders/$orderId');
      final data = response.data;
      return data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>? ?? data)
          : {};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải chi tiết đơn hàng');
    }
  }

  /// Lấy danh sách món ăn của vendor
  Future<List<Map<String, dynamic>>> getVendorMenuItems({
    String? restaurantId,
    String? category,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (restaurantId != null && restaurantId.isNotEmpty) {
        queryParams['restaurantId'] = restaurantId;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.dio.get(
        '/vendor/menu-items',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : (data is List ? data : []);

      return items.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải danh sách món ăn');
    }
  }

  /// Tạo món ăn mới
  Future<void> createMenuItem({
    required String name,
    required double price,
    required String category,
    required String imageUrl,
    String? restaurantId,
    String? description,
    List<String>? tags,
    List<Map<String, dynamic>>? options,
    bool isAvailable = true,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
      };
      if (restaurantId != null && restaurantId.isNotEmpty) {
        payload['restaurantId'] = restaurantId;
      }
      if (description != null && description.isNotEmpty) {
        payload['description'] = description;
      }
      if (tags != null && tags.isNotEmpty) {
        payload['tags'] = tags;
      }
      if (options != null && options.isNotEmpty) {
        payload['options'] = options;
      }

      await _apiClient.dio.post('/vendor/menu-items', data: payload);
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tạo món ăn mới');
    }
  }

  /// Cập nhật món ăn
  Future<void> updateMenuItem({
    required String menuItemId,
    String? name,
    double? price,
    String? category,
    String? imageUrl,
    String? description,
    List<String>? tags,
    List<Map<String, dynamic>>? options,
    bool? isAvailable,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.isNotEmpty) payload['name'] = name;
      if (price != null) payload['price'] = price;
      if (category != null && category.isNotEmpty) payload['category'] = category;
      if (imageUrl != null && imageUrl.isNotEmpty) payload['imageUrl'] = imageUrl;
      if (description != null) payload['description'] = description;
      if (tags != null) payload['tags'] = tags;
      if (options != null) payload['options'] = options;
      if (isAvailable != null) payload['isAvailable'] = isAvailable;

      await _apiClient.dio.put('/vendor/menu-items/$menuItemId', data: payload);
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể cập nhật món ăn');
    }
  }

  /// Xóa món ăn
  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      await _apiClient.dio.delete('/vendor/menu-items/$menuItemId');
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể xóa món ăn');
    }
  }

  /// Cập nhật trạng thái nhận đơn hàng
  Future<void> updateAcceptingOrders({
    required String restaurantId,
    required bool isAcceptingOrders,
  }) async {
    try {
      await _apiClient.dio.patch(
        '/vendor/restaurants/$restaurantId/accepting-orders',
        data: {'isAcceptingOrders': isAcceptingOrders},
      );
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể cập nhật trạng thái nhận đơn');
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

