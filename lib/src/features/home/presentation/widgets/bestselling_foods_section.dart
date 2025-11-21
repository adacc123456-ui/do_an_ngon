import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/rating_widget.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class BestsellingFoodsSection extends StatefulWidget {
  const BestsellingFoodsSection({super.key});

  @override
  State<BestsellingFoodsSection> createState() => _BestsellingFoodsSectionState();
}

class _BestsellingFoodsSectionState extends State<BestsellingFoodsSection> {
  late Future<List<Food>> _futureFoods;
  final _repository = GetIt.I<RestaurantRepository>();

  @override
  void initState() {
    super.initState();
    _futureFoods = _repository.getBestsellingFoods(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Món ăn bán chạy',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        FutureBuilder<List<Food>>(
          future: _futureFoods,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 220.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 220.h,
                child: Center(
                  child: Text(
                    'Không thể tải danh sách món bán chạy.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }

            final foods = snapshot.data ?? [];
            if (foods.isEmpty) {
              return SizedBox(
                height: 220.h,
                child: Center(
                  child: Text(
                    'Chưa có dữ liệu món ăn',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 240.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: foods.length,
                itemBuilder: (context, index) {
                  final food = foods[index];
                  return _FoodCard(food: food);
                },
              ),
            );
          },
        ),
      ],
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
            width: double.infinity,
            height: 120.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(),
          )
        : Image.asset(
            food.imageUrl,
            width: double.infinity,
            height: 120.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(),
          );

    return GestureDetector(
      onTap: () {
        context.push('/food-detail', extra: food);
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
            // Food Image
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
                    food.name,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  RatingWidget(
                    rating: food.averageRating,
                    totalReviews: food.totalReviews,
                    starSize: 11,
                    fontSize: 9,
                    showReviewsCount: false,
                  ),
                  SizedBox(height: 2.h),
                  if (food.price != null)
                    Text(
                      _currencyFormat.format(food.price!),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  SizedBox(height: 2.h),
                  Text(
                    _displayRestaurantName(food),
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10.sp,
                    ),
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

  String _displayRestaurantName(Food food) {
    if (food.restaurantName.isNotEmpty && food.restaurantAddress.isNotEmpty) {
      return '${food.restaurantName} - ${food.restaurantAddress}';
    }
    if (food.restaurantName.isNotEmpty) {
      return food.restaurantName;
    }
    return 'Quán ăn';
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
