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

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final RestaurantRepository _repository = GetIt.I<RestaurantRepository>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Restaurant> _restaurants = [];
  List<Food> _foods = [];
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _currentQuery = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _restaurants = [];
        _foods = [];
        _currentQuery = '';
      });
      return;
    }

    if (query == _currentQuery && (_restaurants.isNotEmpty || _foods.isNotEmpty)) {
      return; // Already searched
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentQuery = query;
    });

    try {
      // Search both restaurants and foods in parallel
      final results = await Future.wait([
        _repository.searchRestaurants(query: query, limit: 20),
        _repository.searchFoods(search: query, limit: 20),
      ]);

      if (!mounted) return;

      setState(() {
        _restaurants = results[0] as List<Restaurant>;
        _foods = results[1] as List<Food>;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      // Debug: Log error để kiểm tra
      // print('Search error: $e');
      
      String errorMessage = 'Không thể tìm kiếm. Vui lòng thử lại.';
      if (e.toString().contains('Không thể tìm kiếm nhà hàng')) {
        errorMessage = 'Không thể tìm kiếm nhà hàng. Vui lòng thử lại.';
      } else if (e.toString().contains('Không thể tìm kiếm món ăn')) {
        errorMessage = 'Không thể tìm kiếm món ăn. Vui lòng thử lại.';
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
        _restaurants = [];
        _foods = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Tìm kiếm',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: widget.initialQuery == null,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm món ăn, nhà hàng...',
                      hintStyle: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 14.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.grey,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _restaurants = [];
                                  _foods = [];
                                  _currentQuery = '';
                                });
                                _searchFocusNode.requestFocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Tìm',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 18.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Nhà hàng (${_restaurants.length})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood, size: 18.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Món ăn (${_foods.length})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64.sp, color: AppColors.grey),
                            SizedBox(height: 16.h),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.textGrey, fontSize: 16.sp),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _performSearch,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _currentQuery.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 80.sp, color: AppColors.grey),
                                SizedBox(height: 16.h),
                                Text(
                                  'Nhập từ khóa để tìm kiếm',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Tìm kiếm món ăn hoặc nhà hàng',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              // Restaurants Tab
                              _restaurants.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.restaurant_outlined, size: 64.sp, color: AppColors.grey),
                                          SizedBox(height: 16.h),
                                          Text(
                                            'Không tìm thấy nhà hàng',
                                            style: TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.all(16.w),
                                      itemCount: _restaurants.length,
                                      itemBuilder: (context, index) {
                                        final restaurant = _restaurants[index];
                                        return _RestaurantCard(restaurant: restaurant);
                                      },
                                    ),
                              // Foods Tab
                              _foods.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.fastfood_outlined, size: 64.sp, color: AppColors.grey),
                                          SizedBox(height: 16.h),
                                          Text(
                                            'Không tìm thấy món ăn',
                                            style: TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.all(16.w),
                                      itemCount: _foods.length,
                                      itemBuilder: (context, index) {
                                        final food = _foods[index];
                                        return _FoodCard(food: food);
                                      },
                                    ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantCard({required this.restaurant});

  bool get _hasValidImage {
    final imageUrl = restaurant.imageUrl;
    if (imageUrl.isEmpty || imageUrl == 'assets/images/monan.png') {
      return false;
    }
    return imageUrl.startsWith('http') || imageUrl.startsWith('assets/');
  }

  bool get _isRemoteImage => restaurant.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageWidget = _hasValidImage
        ? (_isRemoteImage
            ? Image.network(
                restaurant.imageUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _ImageFallback(),
              )
            : Image.asset(
                restaurant.imageUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _ImageFallback(),
              ))
        : _ImageFallback();

    return GestureDetector(
      onTap: () {
        context.push('/restaurant-detail', extra: restaurant);
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: imageWidget,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  RatingWidget(
                    rating: restaurant.averageRating,
                    totalReviews: restaurant.totalReviews,
                    starSize: 14,
                    fontSize: 12,
                    showReviewsCount: false,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    restaurant.address,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
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

class _FoodCard extends StatelessWidget {
  final Food food;

  const _FoodCard({required this.food});

  bool get _isRemoteImage => food.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageWidget = _isRemoteImage
        ? Image.network(
            food.imageUrl,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(),
          )
        : Image.asset(
            food.imageUrl,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _ImageFallback(),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
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
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
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
                    food.restaurantName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (food.price != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _currencyFormat.format(food.price!),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(Icons.restaurant, color: AppColors.grey, size: 40.sp),
    );
  }
}

