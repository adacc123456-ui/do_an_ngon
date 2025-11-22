import 'package:dio/dio.dart';
import 'package:do_an_ngon/src/core/constants/menu_categories.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/network/api_client.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/restaurant.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/category.dart';

class RestaurantRepository {
  final ApiClient _apiClient;

  RestaurantRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Food>> getBestsellingFoods({int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/restaurants/menu/items',
        queryParameters: {
          'sortBy': 'popularity',
          'sortOrder': 'desc',
          'limit': limit,
        },
      );
      return _parseFoods(response.data);
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải danh sách món bán chạy');
    }
  }

  Future<List<Restaurant>> getFeaturedRestaurants({int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/restaurants/featured',
        queryParameters: {
          'limit': limit,
        },
      );
      return _parseRestaurants(response.data);
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải danh sách quán ăn nổi bật');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/restaurants/menu/categories');
      final categories = _parseCategories(response.data);
      if (categories.isNotEmpty) {
        return categories;
      }
      return _deriveCategoriesFromRestaurants();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _deriveCategoriesFromRestaurants();
      }
      throw _mapException(e, defaultMessage: 'Không thể tải danh mục món ăn');
    }
  }

  Future<List<Food>> getFoodsByCategory(
    String category, {
    String? fallbackSearchTerm,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/restaurants/menu/items',
        queryParameters: {
          'category': category,
          'limit': limit,
        },
      );
      var foods = _parseFoods(response.data);
      if (foods.isEmpty) {
        // fallback to search by keyword if category filter not supported
        final fallbackResponse = await _apiClient.dio.get(
          '/restaurants/menu/items',
          queryParameters: {
            'search': fallbackSearchTerm ?? category,
            'limit': limit,
          },
        );
        foods = _parseFoods(fallbackResponse.data);
      }
      return foods;
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải món ăn theo danh mục');
    }
  }

  Future<List<Restaurant>> searchRestaurants({
    String? query,
    String? cuisine,
    double? ratingMin,
    double? priceMin,
    double? priceMax,
    String? district,
    String? city,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'page': page,
      };
      // Hỗ trợ cả 'q' và 'search' parameter
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
        // Cũng thêm 'search' để đảm bảo tương thích
        queryParams['search'] = query;
      }
      if (cuisine != null && cuisine.isNotEmpty) {
        queryParams['cuisine'] = cuisine;
      }
      if (ratingMin != null) {
        queryParams['ratingMin'] = ratingMin;
      }
      if (priceMin != null) {
        queryParams['priceMin'] = priceMin;
      }
      if (priceMax != null) {
        queryParams['priceMax'] = priceMax;
      }
      if (district != null && district.isNotEmpty) {
        queryParams['district'] = district;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sortOrder'] = sortOrder;
      }

      final response = await _apiClient.dio.get(
        '/restaurants',
        queryParameters: queryParams,
      );
      
      // Debug: Log response để kiểm tra
      // print('Search restaurants response: ${response.data}');
      
      return _parseRestaurants(response.data);
    } on DioException catch (e) {
      // Debug: Log error để kiểm tra
      // print('Search restaurants error: ${e.response?.data}');
      throw _mapException(e, defaultMessage: 'Không thể tìm kiếm nhà hàng');
    }
  }

  Future<List<Food>> searchFoods({
    String? search,
    String? category,
    double? priceMax,
    double? priceMin,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'page': page,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (priceMax != null) {
        queryParams['priceMax'] = priceMax;
      }
      if (priceMin != null) {
        queryParams['priceMin'] = priceMin;
      }

      final response = await _apiClient.dio.get(
        '/restaurants/menu/items',
        queryParameters: queryParams,
      );
      return _parseFoods(response.data);
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tìm kiếm món ăn');
    }
  }

  Future<List<Food>> getRestaurantMenu(String restaurantId, {int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get('/restaurants/$restaurantId/menu');
      var foods = _parseRestaurantMenu(response.data);
      if (foods.isEmpty) {
        final fallbackResponse = await _apiClient.dio.get(
          '/restaurants/menu/items',
          queryParameters: {
            'restaurantIds': [restaurantId],
            'restaurantId': restaurantId,
            'limit': limit,
          },
        );
        foods = _parseFoods(fallbackResponse.data);
      }

      return foods
          .where((food) {
            final id = food.restaurantId;
            if (id == null || id.isEmpty) {
              return true;
            }
            return id == restaurantId;
          })
          .toList();
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải thực đơn quán ăn');
    }
  }

  Future<Restaurant> getRestaurantDetail(String restaurantId) async {
    try {
      final response = await _apiClient.dio.get('/restaurants/$restaurantId');
      final data = response.data;
      final parsed = _parseRestaurants(data);
      if (parsed.isNotEmpty) {
        return parsed.first;
      }

      if (data is Map<String, dynamic>) {
        final restaurantData = data['data'] ?? data;
        if (restaurantData is Map<String, dynamic>) {
          final restaurantList = _parseRestaurants({'data': [restaurantData]});
          if (restaurantList.isNotEmpty) {
            return restaurantList.first;
          }
        }
      }

      throw const ApiException(message: 'Không tìm thấy thông tin quán ăn');
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tải thông tin quán ăn');
    }
  }

  Future<String?> findRestaurantIdByName(String name) async {
    try {
      final response = await _apiClient.dio.get(
        '/restaurants',
        queryParameters: {
          'q': name,
          'limit': 1,
        },
      );
      final restaurants = _parseRestaurants(response.data);
      if (restaurants.isNotEmpty) {
        final restaurant = restaurants.first;
        if (restaurant.id.isNotEmpty) {
          return restaurant.id;
        }
      }
      return null;
    } on DioException catch (e) {
      throw _mapException(e, defaultMessage: 'Không thể tìm quán ăn theo tên');
    }
  }

  List<Food> _parseFoods(dynamic data) {
    final Iterable<dynamic> items = _extractList(data, keys: ['data', 'items']) ??
        _extractList(data, keys: ['data']) ??
        (data is List ? data : const []);

    return items.map((item) {
      final map = item as Map<String, dynamic>? ?? {};
      final restaurant = map['restaurant'] as Map<String, dynamic>? ?? {};
      final restaurantAddress = restaurant['address'] as Map<String, dynamic>?;

      // Build full address from nested address object
      String? addressString;
      if (restaurantAddress != null) {
        addressString = _buildFullAddress(restaurantAddress);
      }
      if (addressString == null || addressString.isEmpty) {
        // Fallback to direct string fields
        addressString = _extractString(restaurant, ['address']) ??
            _extractString(map, ['street', 'address']);
      }

      return Food(
        id: _extractString(map, ['id', '_id']) ?? '',
        name: _extractString(map, ['name', 'title']) ?? 'Món ăn',
        imageUrl: _extractString(map, ['imageUrl', 'thumbnail', 'coverImage']) ??
            _extractString(restaurant, ['heroImage', 'imageUrl', 'bannerUrl']) ??
            'assets/images/monan.png',
        restaurantName: _extractString(restaurant, ['name']) ??
            _extractString(map, ['restaurantName', 'vendorName']) ??
            'Quán ăn',
        restaurantAddress: addressString?.isNotEmpty == true
            ? addressString!
            : 'Đang cập nhật',
        restaurantId: _extractString(map, ['restaurantId']) ??
            _extractString(restaurant, ['id', '_id']),
        price: _extractPrice(map),
        rating: _extractFoodRating(map), // Food item rating
        restaurant: _extractRestaurantInfo(map), // Restaurant info with rating
      );
    }).toList();
  }

  double? _extractPrice(Map<String, dynamic> json) {
    final price = json['price'];
    if (price is num) {
      return price.toDouble();
    }
    final basePrice = json['basePrice'];
    if (basePrice is num) {
      return basePrice.toDouble();
    }
    return null;
  }

  List<Restaurant> _parseRestaurants(dynamic data) {
    // Hỗ trợ nhiều format response:
    // 1. { "data": { "items": [...] } } - format mới
    // 2. { "data": { "restaurants": [...] } }
    // 3. { "data": [...] } - format cũ
    // 4. [...] - trực tiếp là array
    final Iterable<dynamic> items = _extractList(data, keys: ['data', 'items']) ??
        _extractList(data, keys: ['data', 'restaurants']) ??
        _extractList(data, keys: ['data']) ??
        (data is List ? data : const []);

    return items.map((item) {
      final map = item as Map<String, dynamic>? ?? {};
      final address = map['address'] as Map<String, dynamic>?;

      return Restaurant(
        id: _extractString(map, ['id', '_id']) ?? '',
        name: _extractString(map, ['name']) ?? 'Quán ăn',
        imageUrl: _extractString(map, ['heroImage', 'bannerImage', 'coverImage', 'imageUrl', 'bannerUrl']) ??
            'assets/images/monan.png',
        address: _extractString(address ?? {}, ['full', 'formatted', 'street', 'address']) ??
            _extractString(map, ['address']) ??
            '',
        slug: _extractString(map, ['slug']),
        phone: _extractString(map, ['phone']),
        rating: _extractRating(map), // Legacy
        ratingInfo: _extractRatingInfo(map), // New rating object
        isAcceptingOrders: map['isAcceptingOrders'] as bool? ?? true,
      );
    }).toList();
  }

  List<Category> _parseCategories(dynamic data) {
    final Iterable<dynamic> items = _extractList(data, keys: ['data', 'categories']) ??
        _extractList(data, keys: ['data']) ??
        (data is List ? data : const []);

    final List<Category> categories = [];

    for (final item in items) {
      final map = item as Map<String, dynamic>? ?? {};
      final category = _buildCategory(
        id: _extractString(map, ['key', 'id', '_id', 'slug']),
        name: _extractString(map, ['name', 'title']),
        icon: _extractString(map, ['icon', 'iconUrl', 'iconPath']),
      );
      if (category != null) {
        categories.add(category);
      }
    }

    return categories;
  }

  Future<List<Category>> _deriveCategoriesFromRestaurants() async {
    final response = await _apiClient.dio.get(
      '/restaurants',
      queryParameters: {'limit': 50},
    );

    final Iterable<dynamic> rawList = _extractList(response.data, keys: ['data', 'restaurants']) ??
        _extractList(response.data, keys: ['data']) ??
        (response.data is List ? response.data as List : const []);

    final Set<String> seenIds = {};
    final List<Category> categories = [];

    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;

      final dynamic tags = item['categories'] ?? item['cuisines'] ?? item['tags'];
      if (tags is! List || tags.isEmpty) continue;

      for (final tag in tags) {
        final String name = tag.toString().trim();
        if (name.isEmpty) continue;
        final category = _buildCategory(
          id: name,
          name: name,
        );
        if (category != null && seenIds.add(category.id)) {
          categories.add(category);
        }
      }
    }

    return categories;
  }

  Category? _buildCategory({
    required String? id,
    required String? name,
    String? icon,
  }) {
    final normalizedId = MenuCategories.normalizeKey(id);
    final fallbackId = MenuCategories.normalizeKey(name);
    final resolvedId = normalizedId.isNotEmpty ? normalizedId : fallbackId;
    if (resolvedId.isEmpty) {
      return null;
    }

    final resolvedName = MenuCategories.resolveName(resolvedId, fallback: name);
    final resolvedIcon = icon ?? MenuCategories.resolveIcon(resolvedId);

    return Category(
      id: resolvedId,
      name: resolvedName,
      icon: resolvedIcon,
    );
  }

  List<Food> _parseRestaurantMenu(dynamic data) {
    final List<Food> items = [];
    final Iterable<dynamic>? categories = _extractList(data, keys: ['data', 'categories']) ??
        _extractList(data, keys: ['categories']);

    if (categories != null) {
      for (final category in categories) {
        if (category is Map<String, dynamic>) {
          final Iterable<dynamic>? foods = _extractList(category, keys: ['items']);
          if (foods != null) {
            items.addAll(_parseFoods({
              'data': foods.toList(),
            }));
          }
        }
      }
    }

    if (items.isEmpty && data is Map<String, dynamic>) {
      final Iterable<dynamic>? inlineItems = _extractList(data, keys: ['data', 'items']);
      if (inlineItems != null) {
        items.addAll(_parseFoods({
          'data': inlineItems.toList(),
        }));
      }
    }

    return items;
  }

  Iterable<dynamic>? _extractList(dynamic data, {required List<String> keys}) {
    dynamic current = data;
    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return null;
      }
    }
    if (current is List) {
      return current;
    }
    return null;
  }

  String? _extractString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _buildFullAddress(Map<String, dynamic>? address) {
    if (address == null) return '';
    
    final parts = <String>[];
    final street = address['street']?.toString();
    final ward = address['ward']?.toString();
    final district = address['district']?.toString();
    final city = address['city']?.toString();
    
    if (street != null && street.isNotEmpty) parts.add(street);
    if (ward != null && ward.isNotEmpty) parts.add(ward);
    if (district != null && district.isNotEmpty) parts.add(district);
    if (city != null && city.isNotEmpty) parts.add(city);
    
    return parts.join(', ');
  }

  double? _extractRating(Map<String, dynamic> json) {
    final rating = json['rating'];
    if (rating is num) {
      return rating.toDouble();
    }
    final avgRating = json['averageRating'];
    if (avgRating is num) {
      return avgRating.toDouble();
    }
    return null;
  }

  RestaurantRating? _extractRatingInfo(Map<String, dynamic> json) {
    final rating = json['rating'];
    if (rating is Map<String, dynamic>) {
      final average = rating['average'];
      final totalReviews = rating['totalReviews'];
      if (average is num && totalReviews is num) {
        return RestaurantRating(
          average: average.toDouble(),
          totalReviews: totalReviews.toInt(),
        );
      }
    }
    return null;
  }

  FoodRating? _extractFoodRating(Map<String, dynamic> json) {
    final rating = json['rating'];
    if (rating is Map<String, dynamic>) {
      final average = rating['average'];
      final totalReviews = rating['totalReviews'];
      if (average is num && totalReviews is num) {
        return FoodRating(
          average: average.toDouble(),
          totalReviews: totalReviews.toInt(),
        );
      }
    }
    return null;
  }

  RestaurantInfo? _extractRestaurantInfo(Map<String, dynamic> json) {
    final restaurant = json['restaurant'];
    if (restaurant is Map<String, dynamic>) {
      final id = _extractString(restaurant, ['id', '_id']);
      final name = _extractString(restaurant, ['name']);
      if (id != null && name != null) {
        final address = restaurant['address'];
        String? addressString;
        if (address is Map<String, dynamic>) {
          addressString = _buildFullAddress(address);
        } else if (address is String) {
          addressString = address;
        }
        
        final rating = _extractFoodRating(restaurant);
        
        return RestaurantInfo(
          id: id,
          name: name,
          address: addressString,
          rating: rating,
        );
      }
    }
    return null;
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
