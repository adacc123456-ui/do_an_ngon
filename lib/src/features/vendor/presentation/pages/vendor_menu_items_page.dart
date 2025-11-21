import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/restaurant.dart';
import 'package:do_an_ngon/src/features/vendor/data/repositories/vendor_repository.dart';
import 'package:do_an_ngon/src/core/widgets/rating_widget.dart';

class VendorMenuItemsPage extends StatefulWidget {
  const VendorMenuItemsPage({super.key});

  @override
  State<VendorMenuItemsPage> createState() => _VendorMenuItemsPageState();
}

class _VendorMenuItemsPageState extends State<VendorMenuItemsPage> {
  final RestaurantRepository _restaurantRepository = GetIt.I<RestaurantRepository>();
  final VendorRepository _vendorRepository = GetIt.I<VendorRepository>();

  List<Map<String, dynamic>> _menuItems = [];
  List<Restaurant> _managedRestaurants = [];
  bool _isLoadingRestaurants = true;
  bool _isLoadingItems = true;
  String? _restaurantsError;
  String? _itemsError;
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    _loadManagedRestaurants();
  }

  Future<void> _loadManagedRestaurants() async {
    final authState = context.read<AuthBloc>().state;
    final managedRestaurants = authState.userProfile?['managedRestaurants'] as List<dynamic>?;
    if (managedRestaurants == null || managedRestaurants.isEmpty) {
      setState(() {
        _restaurantsError = 'Tài khoản của bạn chưa được gán nhà hàng nào.';
        _isLoadingRestaurants = false;
        _isLoadingItems = false;
      });
      return;
    }

    setState(() {
      _isLoadingRestaurants = true;
      _restaurantsError = null;
    });

    final ids = managedRestaurants.map((entry) {
      if (entry is String) return entry;
      if (entry is Map<String, dynamic>) {
        return entry['_id']?.toString() ?? entry['id']?.toString();
      }
      return null;
    }).whereType<String>().toList();

    try {
      final restaurants = <Restaurant>[];
      for (final id in ids) {
        if (id.isEmpty) continue;
        final restaurant = await _restaurantRepository.getRestaurantDetail(id);
        restaurants.add(restaurant);
      }
      if (restaurants.isEmpty) {
        throw const ApiException(message: 'Không tìm thấy thông tin nhà hàng.');
      }
      setState(() {
        _managedRestaurants = restaurants;
        _selectedRestaurantId ??= restaurants.first.id;
        _isLoadingRestaurants = false;
      });
      await _loadMenuItems();
    } on ApiException catch (e) {
      setState(() {
        _restaurantsError = e.message;
        _isLoadingRestaurants = false;
        _isLoadingItems = false;
      });
    } catch (_) {
      setState(() {
        _restaurantsError = 'Không thể tải danh sách nhà hàng.';
        _isLoadingRestaurants = false;
        _isLoadingItems = false;
      });
    }
  }

  Future<void> _loadMenuItems() async {
    final restaurantId = _selectedRestaurantId;
    if (restaurantId == null || restaurantId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _itemsError = 'Vui lòng chọn nhà hàng để xem món ăn.';
        _isLoadingItems = false;
      });
      return;
    }

    setState(() {
      _isLoadingItems = true;
      _itemsError = null;
    });

    try {
      final items = await _vendorRepository.getVendorMenuItems(
        restaurantId: restaurantId,
        limit: 100, // Lấy tất cả món ăn
      );
      if (!mounted) return;
      setState(() {
        _menuItems = items;
        _isLoadingItems = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _itemsError = e.message;
        _isLoadingItems = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _itemsError = 'Không thể tải danh sách món ăn.';
        _isLoadingItems = false;
      });
    }
  }

  void _onRestaurantChanged(String? restaurantId) {
    if (restaurantId == _selectedRestaurantId) return;
    setState(() {
      _selectedRestaurantId = restaurantId;
      _menuItems = [];
    });
    _loadMenuItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Danh sách món ăn',
        showBackButton: true,
        onBackPressed: () {
          context.go('/vendor-account-information');
        },
      ),
      body: Column(
        children: [
          // Restaurant selector
          if (_managedRestaurants.length > 1)
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppColors.white,
              child: DropdownButtonFormField<String>(
                value: _selectedRestaurantId,
                decoration: InputDecoration(
                  labelText: 'Chọn nhà hàng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
                items: _managedRestaurants.map((restaurant) {
                  return DropdownMenuItem<String>(
                    value: restaurant.id,
                    child: Text(restaurant.name),
                  );
                }).toList(),
                onChanged: _isLoadingRestaurants ? null : _onRestaurantChanged,
              ),
            ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingRestaurants || _isLoadingItems) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_restaurantsError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: AppColors.grey),
              SizedBox(height: 16.h),
              Text(
                _restaurantsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_itemsError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: AppColors.grey),
              SizedBox(height: 16.h),
              Text(
                _itemsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadMenuItems,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_menuItems.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 64.sp, color: AppColors.grey),
              SizedBox(height: 16.h),
              Text(
                'Chưa có món ăn nào',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return _MenuItemCard(item: item);
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Món ăn';
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final price = item['price'];
    final ratingData = item['rating'] as Map<String, dynamic>?;
    final averageRatingValue = ratingData?['average'];
    final averageRating = averageRatingValue is num 
        ? averageRatingValue.toDouble() 
        : (averageRatingValue as double? ?? 0.0);
    final totalReviewsValue = ratingData?['totalReviews'];
    final totalReviews = totalReviewsValue is int 
        ? totalReviewsValue 
        : (totalReviewsValue as int? ?? 0);
    final isAvailable = item['isAvailable'] as bool? ?? true;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80.w,
                      height: 80.w,
                      color: AppColors.lightGrey,
                      child: Icon(Icons.restaurant, color: AppColors.grey, size: 32.sp),
                    ),
                  )
                : Container(
                    width: 80.w,
                    height: 80.w,
                    color: AppColors.lightGrey,
                    child: Icon(Icons.restaurant, color: AppColors.grey, size: 32.sp),
                  ),
          ),
          SizedBox(width: 12.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isAvailable)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Hết hàng',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                if (price != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '${_formatPrice(price)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                // Rating
                if (totalReviews > 0)
                  Row(
                    children: [
                      RatingWidget(
                        rating: averageRating,
                        starSize: 12,
                        fontSize: 12,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '($totalReviews đánh giá)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Chưa có đánh giá',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price is num) {
      return '${price.toInt().toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )} đ';
    }
    return '0 đ';
  }
}

