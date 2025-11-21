import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/orange_header.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/bottom_navigation_bar.dart'
    as home;

final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Food> _filterFavorites(List<Food> favorites, String query) {
    if (query.isEmpty) return favorites;
    final lowerQuery = query.toLowerCase();
    return favorites.where((food) {
      return food.name.toLowerCase().contains(lowerQuery) ||
          food.restaurantName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: const OrangeHeader(
        title: 'Món ăn, quán ăn yêu thích',
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20.r),
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
                  SvgIcon(
                    assetPath: 'assets/svgs/search.svg',
                    width: 20,
                    height: 20,
                    color: AppColors.grey,
                    fallbackIcon: Icons.search,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm trong yêu thích...',
                        hintStyle: TextStyle(color: AppColors.grey, fontSize: 14.sp),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: 20.sp, color: AppColors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          // Favorites List
          Expanded(
            child: BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                final filteredFavorites = _filterFavorites(state.favorites, _searchQuery);
                
                if (state.favorites.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80.sp,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Chưa có món yêu thích',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Hãy thêm món ăn yêu thích của bạn',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredFavorites.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80.sp,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Không tìm thấy kết quả',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Thử tìm kiếm với từ khóa khác',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filteredFavorites.length,
                  itemBuilder: (context, index) {
                    final food = filteredFavorites[index];
                    return _FavoriteItemCard(food: food);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const home.HomeBottomNavigationBar(currentIndex: 1),
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final Food food;

  const _FavoriteItemCard({required this.food});

  bool get _isRemoteImage => food.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageWidget = _isRemoteImage
        ? Image.network(
            food.imageUrl,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(size: 80.w),
          )
        : Image.asset(
            food.imageUrl,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(size: 80.w),
          );

    return Container(
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
      child: GestureDetector(
        onTap: () {
          context.push('/food-detail', extra: food);
        },
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
                  if (food.price != null) SizedBox(height: 4.h),
                  Text(
                    food.restaurantName,
                    style: TextStyle(color: AppColors.grey, fontSize: 14.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    food.restaurantAddress,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Remove from favorites button
            BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    context.read<FavoritesBloc>().add(
                          RemoveFromFavoritesEvent(foodId: food.id),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa khỏi yêu thích'),
                        duration: Duration(seconds: 1),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 24.sp,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
      child: Icon(Icons.fastfood, color: AppColors.grey, size: 40.sp),
    );
  }
}
