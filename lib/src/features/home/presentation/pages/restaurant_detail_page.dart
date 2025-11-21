import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/widgets/rating_widget.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/restaurant.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailPage({super.key, required this.restaurant});

  Future<List<Food>> _loadMenu() {
    return GetIt.I<RestaurantRepository>().getRestaurantMenu(restaurant.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: restaurant.name,
        showBackButton: true,
      ),
      body: FutureBuilder<List<Food>>(
        future: _loadMenu(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  'Không thể tải thực đơn của quán ăn.',
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

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _RestaurantHeader(restaurant: restaurant),
              SizedBox(height: 24.h),
              Text(
                'Thực đơn',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              if (foods.isEmpty)
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 64.sp,
                        color: AppColors.grey,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Quán ăn chưa có thực đơn',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...foods.map(
                  (food) => _FoodListTile(food: food),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantHeader({required this.restaurant});

  bool get _isRemoteImage => restaurant.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageWidget = _isRemoteImage
        ? Image.network(
            restaurant.imageUrl,
            height: 200.h,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(height: 200.h),
          )
        : Image.asset(
            restaurant.imageUrl,
            height: 200.h,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(height: 200.h),
          );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: imageWidget,
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        restaurant.address,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                if (restaurant.phone != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: AppColors.primary,
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        restaurant.phone!,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12.h),
                RatingWidget(
                  rating: restaurant.averageRating,
                  totalReviews: restaurant.totalReviews,
                  starSize: 18,
                  fontSize: 14,
                  showReviewsCount: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodListTile extends StatelessWidget {
  final Food food;

  const _FoodListTile({required this.food});

  bool get _isRemoteImage => food.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageWidget = _isRemoteImage
        ? Image.network(
            food.imageUrl,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _FoodImageFallback(size: 80.w),
          )
        : Image.asset(
            food.imageUrl,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _FoodImageFallback(size: 80.w),
          );

    return GestureDetector(
      onTap: () => context.push('/food-detail', extra: food),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: imageWidget,
            ),
            SizedBox(width: 12.w),
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
                  SizedBox(height: 4.h),
                  if (food.price != null)
                    Text(
                      _currencyFormat.format(food.price!),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Text(
                    food.restaurantAddress,
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
}

class _ImageFallback extends StatelessWidget {
  final double height;

  const _ImageFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.lightGrey,
      child: Icon(
        Icons.restaurant,
        color: AppColors.grey,
        size: 48.sp,
      ),
    );
  }
}

class _FoodImageFallback extends StatelessWidget {
  final double size;

  const _FoodImageFallback({required this.size});

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
        size: 32.sp,
      ),
    );
  }
}
