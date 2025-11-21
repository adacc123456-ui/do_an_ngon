import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/rating_widget.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/restaurant.dart';

class FeaturedRestaurantsSection extends StatefulWidget {
  const FeaturedRestaurantsSection({super.key});

  @override
  State<FeaturedRestaurantsSection> createState() => _FeaturedRestaurantsSectionState();
}

class _FeaturedRestaurantsSectionState extends State<FeaturedRestaurantsSection> {
  late Future<List<Restaurant>> _futureRestaurants;
  final _repository = GetIt.I<RestaurantRepository>();

  @override
  void initState() {
    super.initState();
    _futureRestaurants = _repository.getFeaturedRestaurants(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quán ăn nổi bật',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        FutureBuilder<List<Restaurant>>(
          future: _futureRestaurants,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 200.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 200.h,
                child: Center(
                  child: Text(
                    'Không thể tải danh sách quán ăn nổi bật.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }

            final restaurants = snapshot.data ?? [];
            if (restaurants.isEmpty) {
              return SizedBox(
                height: 200.h,
                child: Center(
                  child: Text(
                    'Chưa có dữ liệu quán ăn',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return _RestaurantCard(restaurant: restaurant);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantCard({required this.restaurant});

  bool get _isRemoteImage => restaurant.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageWidget = _isRemoteImage
        ? Image.network(
            restaurant.imageUrl,
            width: double.infinity,
            height: 120.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(),
          )
        : Image.asset(
            restaurant.imageUrl,
            width: double.infinity,
            height: 120.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(),
          );

    return GestureDetector(
      onTap: () {
        context.push('/restaurant-detail', extra: restaurant);
      },
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 12.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: imageWidget,
            ),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  RatingWidget(
                    rating: restaurant.averageRating,
                    totalReviews: restaurant.totalReviews,
                    starSize: 12,
                    fontSize: 10,
                    showReviewsCount: false,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _displayRestaurantInfo(restaurant),
                    style: TextStyle(color: AppColors.grey, fontSize: 10.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayRestaurantInfo(Restaurant restaurant) {
    final address = restaurant.address;
    if (address.isNotEmpty) {
      return address;
    }
    return 'Đang cập nhật địa chỉ';
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120.h,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Icon(Icons.image, color: AppColors.grey, size: 40.sp),
    );
  }
}
