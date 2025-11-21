import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class FavoritesBottomSheet extends StatefulWidget {
  const FavoritesBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FavoritesBottomSheet(),
    );
  }

  @override
  State<FavoritesBottomSheet> createState() => _FavoritesBottomSheetState();
}

class _FavoritesBottomSheetState extends State<FavoritesBottomSheet> {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
            child: Text(
              'Món ăn, quán ăn yêu thích',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
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
          SizedBox(height: 16.h),
          // Favorites List
          Expanded(
            child: BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

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
                          'Chưa có món ăn yêu thích',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Hãy thêm món ăn bạn thích vào danh sách này',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
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
                    food.restaurantName,
                    style: TextStyle(color: AppColors.grey, fontSize: 14.sp),
                  ),
                ],
              ),
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
      child: Icon(Icons.restaurant, color: AppColors.grey, size: 32.sp),
    );
  }
}

