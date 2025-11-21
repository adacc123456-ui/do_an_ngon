import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/widgets/cart_icon_button.dart';
import 'package:do_an_ngon/src/core/widgets/rating_widget.dart';
import 'package:do_an_ngon/src/features/cart/domain/entities/food_detail.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_event.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/restaurant.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:do_an_ngon/src/core/widgets/flying_cart_animation.dart';

class FoodDetailPage extends StatefulWidget {
  final Food food;

  const FoodDetailPage({
    super.key,
    required this.food,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int _quantity = 1;
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _cartIconKey = GlobalKey();

  bool get _isRemoteFoodImage => widget.food.imageUrl.startsWith('http');

  String get _restaurantImageUrl =>
      _isRemoteFoodImage ? widget.food.imageUrl : 'assets/images/monan.png';

  // Mock food detail data
  FoodDetail get _foodDetail => FoodDetail(
        id: widget.food.id,
        name: widget.food.name,
        imageUrl: widget.food.imageUrl,
        description:
            'Món ăn ngon miệng, được chế biến từ những nguyên liệu tươi ngon nhất. Hương vị đậm đà, thơm ngon, đảm bảo sẽ làm hài lòng thực khách.',
        price: widget.food.price ?? 150000,
        restaurantName: widget.food.restaurantName,
        restaurantAddress: widget.food.restaurantAddress,
        rating: widget.food.averageRating > 0 ? widget.food.averageRating : 4.5,
        reviewCount: widget.food.totalReviews > 0 ? widget.food.totalReviews : 128,
      );

  void _addToCart() {
    final cartBloc = context.read<CartBloc>();
    final food = Food(
      id: widget.food.id,
      name: widget.food.name,
      imageUrl: widget.food.imageUrl,
      restaurantName: widget.food.restaurantName,
      restaurantAddress: widget.food.restaurantAddress,
      restaurantId: widget.food.restaurantId,
      price: widget.food.price ?? _foodDetail.price,
    );

    cartBloc.add(
      AddToCartEvent(
        food: food,
        quantity: _quantity,
        price: _foodDetail.price,
      ),
    );

    // Show flying animation
    _showFlyingAnimation();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${_foodDetail.name} vào giỏ hàng'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFlyingAnimation() {
    final RenderBox? imageRenderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? cartRenderBox =
        _cartIconKey.currentContext?.findRenderObject() as RenderBox?;

    if (imageRenderBox != null && cartRenderBox != null) {
      final startPosition = imageRenderBox.localToGlobal(Offset.zero);
      final imageSize = imageRenderBox.size;
      final cartPosition = cartRenderBox.localToGlobal(Offset.zero);
      final cartSize = cartRenderBox.size;

      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        builder: (context) => Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              FlyingCartAnimation(
                startPosition: Offset(
                  startPosition.dx + imageSize.width / 2,
                  startPosition.dy + imageSize.height / 2,
                ),
                endPosition: Offset(
                  cartPosition.dx + cartSize.width / 2,
                  cartPosition.dy + cartSize.height / 2,
                ),
                onComplete: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  void _navigateToRestaurantDetail() {
    final restaurantId = widget.food.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin quán ăn.'),
        ),
      );
      return;
    }

    final restaurant = Restaurant(
      id: restaurantId,
      name: widget.food.restaurantName,
      imageUrl: _restaurantImageUrl,
      address: widget.food.restaurantAddress,
    );

    context.push('/restaurant-detail', extra: restaurant);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(
        title: _foodDetail.name,
        showBackButton: true,
        trailing: Container(
          key: _cartIconKey,
          child: const CartIconButton(),
        ),
      ),
      
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            Stack(
              children: [
                Container(
                  key: _imageKey,
                  width: double.infinity,
                  height: 300.h,
                  child: _isRemoteFoodImage
                      ? Image.network(
                          widget.food.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.lightGrey,
                            child: Icon(
                              Icons.restaurant,
                              size: 100.sp,
                              color: AppColors.grey,
                            ),
                          ),
                        )
                      : Image.asset(
                          widget.food.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.lightGrey,
                            child: Icon(
                              Icons.restaurant,
                              size: 100.sp,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                ),
                // Favorite Button
                Positioned(
                  top: 16.h,
                  right: 16.w,
                  child: BlocBuilder<FavoritesBloc, FavoritesState>(
                    builder: (context, state) {
                      final isFavorite = state.isFavorite(widget.food.id);
                      return GestureDetector(
                        onTap: () {
                          context.read<FavoritesBloc>().add(
                                ToggleFavoriteEvent(food: widget.food),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite
                                    ? 'Đã xóa khỏi yêu thích'
                                    : 'Đã thêm vào yêu thích',
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? Colors.red
                                : AppColors.black,
                            size: 24.sp,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Food Info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _foodDetail.name,
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${_foodDetail.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Rating
                  RatingWidget(
                    rating: widget.food.averageRating,
                    totalReviews: widget.food.totalReviews,
                    starSize: 18,
                    fontSize: 14,
                    showReviewsCount: true,
                  ),
                  SizedBox(height: 16.h),
                  // Description
                  Text(
                    'Mô tả',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _foodDetail.description,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Restaurant Info
                  GestureDetector(
                    onTap: _navigateToRestaurantDetail,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foodDetail.restaurantName,
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _foodDetail.restaurantAddress,
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.grey,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Quantity Selector
                  Text(
                    'Số lượng',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      // Decrease Button
                      GestureDetector(
                        onTap: () {
                          if (_quantity > 1) {
                            setState(() {
                              _quantity--;
                            });
                          }
                        },
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: _quantity > 1
                                ? AppColors.primary
                                : AppColors.lightGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove,
                            color: _quantity > 1
                                ? AppColors.white
                                : AppColors.grey,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Quantity Display
                      Text(
                        _quantity.toString(),
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Increase Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColors.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Total Price
                      Text(
                        '${(_foodDetail.price * _quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Thêm vào giỏ hàng',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

