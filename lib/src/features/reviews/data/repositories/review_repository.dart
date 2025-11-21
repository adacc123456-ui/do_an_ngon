import 'package:dio/dio.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/network/api_client.dart';

class ReviewRepository {
  final ApiClient _apiClient;

  ReviewRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Tạo đánh giá cho nhà hàng hoặc món ăn
  Future<Map<String, dynamic>> createReview({
    required String orderId,
    required String restaurantId,
    String? menuItemId,
    required int rating,
    String? comment,
    List<String>? photos,
    List<String>? tags,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/reviews',
        data: {
          'orderId': orderId,
          'restaurantId': restaurantId,
          if (menuItemId != null && menuItemId.isNotEmpty) 'menuItemId': menuItemId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (photos != null && photos.isNotEmpty) 'photos': photos,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'message': 'Đánh giá thành công'};
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể gửi đánh giá');
    }
  }

  /// Lấy danh sách đánh giá của nhà hàng
  Future<List<Map<String, dynamic>>> getRestaurantReviews(
    String restaurantId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reviews/restaurants/$restaurantId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final items = data['data'] as List<dynamic>? ?? [];
        return items.map((item) => item as Map<String, dynamic>).toList();
      } else if (data is List) {
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải đánh giá nhà hàng');
    }
  }

  /// Lấy danh sách đánh giá của món ăn
  Future<List<Map<String, dynamic>>> getMenuItemReviews(
    String menuItemId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reviews/menu-items/$menuItemId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final items = data['data'] as List<dynamic>? ?? [];
        return items.map((item) => item as Map<String, dynamic>).toList();
      } else if (data is List) {
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải đánh giá món ăn');
    }
  }

  /// Lấy danh sách đánh giá của user
  Future<List<Map<String, dynamic>>> getMyReviews({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reviews/me',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final items = data['data'] as List<dynamic>? ?? [];
        return items.map((item) => item as Map<String, dynamic>).toList();
      } else if (data is List) {
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải đánh giá của bạn');
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

