import 'package:dio/dio.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/network/api_client.dart';

class OrderRequestItem {
  final String menuItemId;
  final int quantity;
  final List<Map<String, dynamic>> selectedOptions;
  final String? notes;

  const OrderRequestItem({
    required this.menuItemId,
    required this.quantity,
    this.selectedOptions = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'quantity': quantity,
      if (selectedOptions.isNotEmpty) 'selectedOptions': selectedOptions,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> createOrder({
    required String restaurantId,
    required List<OrderRequestItem> items,
    String paymentMethod = 'COD',
    String? promotionCode,
    String? addressId,
    String? note,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/orders',
        data: {
          'restaurantId': restaurantId,
          'items': items.map((item) => item.toJson()).toList(),
          'paymentMethod': paymentMethod,
          if (promotionCode != null && promotionCode.isNotEmpty)
            'promotionCode': promotionCode,
          if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'message': 'Đặt hàng thành công'};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tạo đơn hàng');
    }
  }

  /// Lấy danh sách đơn hàng của user
  Future<Map<String, dynamic>> getOrders({
    String? status,
    String? restaurantId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (restaurantId != null && restaurantId.isNotEmpty) {
        queryParams['restaurantId'] = restaurantId;
      }

      final response = await _apiClient.dio.get(
        '/orders',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Response có cấu trúc: { "data": { "items": [...], "total": ... } }
        return data;
      }
      return {'data': {'items': [], 'total': 0}};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải danh sách đơn hàng');
    }
  }

  /// Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final response = await _apiClient.dio.get('/orders/$orderId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải chi tiết đơn hàng');
    }
  }

  /// Lấy timeline (lịch sử trạng thái) của đơn hàng
  Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId) async {
    try {
      final response = await _apiClient.dio.get('/orders/$orderId/timeline');
      final data = response.data;
      
      if (data is Map<String, dynamic>) {
        final timelineData = data['data'];
        if (timelineData is List) {
          return timelineData.map((item) => item as Map<String, dynamic>).toList();
        }
      } else if (data is List) {
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      
      return [];
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải tiến trình đơn hàng');
    }
  }

  /// Hủy đơn hàng (user chỉ có thể hủy đơn của mình)
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    String? note,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/orders/$orderId/status',
        data: {
          'status': 'cancelled',
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'message': 'Đã hủy đơn hàng thành công'};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể hủy đơn hàng');
    }
  }

  /// Xác nhận đã nhận hàng (chỉ khi đơn hàng ở trạng thái delivering)
  Future<Map<String, dynamic>> confirmDelivery(String orderId) async {
    try {
      final response = await _apiClient.dio.post('/orders/$orderId/confirm-delivery');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'message': 'Xác nhận nhận hàng thành công'};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể xác nhận nhận hàng');
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
