import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/widgets/rating_widget.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/category.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class CategoryFoodsPage extends StatelessWidget {
  final Category category;

  const CategoryFoodsPage({
    super.key,
    required this.category,
  });

  Future<List<Food>> _loadFoods() {
    return GetIt.I<RestaurantRepository>().getFoodsByCategory(
      category.id,
      fallbackSearchTerm: category.name,
      limit: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: category.name,
        showBackButton: true,
      ),
      body: FutureBuilder<List<Food>>(
        future: _loadFoods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  'Không thể tải món ăn cho danh mục này.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 15.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final foods = snapshot.data ?? [];
          if (foods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 80.sp,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Chưa có món ăn trong danh mục này',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              return _FoodCard(food: food);
            },
          );
        },
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Food food;

  const _FoodCard({required this.food});

  bool get _isRemoteImage => food.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageWidget = _isRemoteImage
        ? Image.network(
            food.imageUrl,
            width: 100.w,
            height: 100.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(size: 100.w),
          )
        : Image.asset(
            food.imageUrl,
            width: 100.w,
            height: 100.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(size: 100.w),
          );

    return GestureDetector(
      onTap: () {
        context.push('/food-detail', extra: food);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Food Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: imageWidget,
            ),
            SizedBox(width: 12.w),
            // Food Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  RatingWidget(
                    rating: food.averageRating,
                    totalReviews: food.totalReviews,
                    starSize: 14,
                    fontSize: 12,
                    showReviewsCount: false,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _displayRestaurantName(food),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (food.price != null)
                    Text(
                      _currencyFormat.format(food.price!),
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Text(
                    _displayRestaurantAddress(food),
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.grey,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  String _displayRestaurantName(Food food) {
    if (food.restaurantName.isNotEmpty) {
      return food.restaurantName;
    }
    return 'Quán ăn';
  }

  String _displayRestaurantAddress(Food food) {
    if (food.restaurantAddress.isNotEmpty) {
      return food.restaurantAddress;
    }
    return 'Đang cập nhật địa chỉ';
  }
}

class _ImageFallback extends StatelessWidget {
  final double size;

  const _ImageFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.restaurant,
        color: AppColors.grey,
        size: 40.sp,
      ),
    );
  }
}

