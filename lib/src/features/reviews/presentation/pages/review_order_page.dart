import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/features/reviews/data/repositories/review_repository.dart';

class ReviewOrderPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const ReviewOrderPage({super.key, required this.order});

  @override
  State<ReviewOrderPage> createState() => _ReviewOrderPageState();
}

class _ReviewOrderPageState extends State<ReviewOrderPage> {
  final ReviewRepository _reviewRepository = GetIt.I<ReviewRepository>();
  final TextEditingController _restaurantCommentController = TextEditingController();
  final Map<String, TextEditingController> _itemCommentControllers = {};
  final Map<String, int> _itemRatings = {};
  final Map<String, List<String>> _itemTags = {};
  
  int _restaurantRating = 5;
  List<String> _restaurantTags = [];
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Giao nhanh',
    'Ngon',
    'Giá hợp lý',
    'Phục vụ tốt',
    'Đóng gói đẹp',
    'Đúng món',
    'Nhiều',
    'Ít',
    'Cay vừa',
    'Không cay',
  ];

  @override
  void initState() {
    super.initState();
    final review = widget.order['review'] as Map<String, dynamic>?;
    final restaurantReview = review?['restaurant'] as Map<String, dynamic>?;
    final itemsReview = review?['items'] as Map<String, dynamic>? ?? {};
    
    // Pre-fill restaurant review if exists
    if (restaurantReview != null) {
      _restaurantRating = restaurantReview['rating'] as int? ?? 5;
      final comment = restaurantReview['comment']?.toString();
      if (comment != null && comment.isNotEmpty) {
        _restaurantCommentController.text = comment;
      }
      final tags = restaurantReview['tags'] as List<dynamic>?;
      if (tags != null) {
        _restaurantTags = tags.map((e) => e.toString()).toList();
      }
    }
    
    final items = widget.order['items'] as List<dynamic>? ?? [];
    for (final item in items) {
      final itemMap = item as Map<String, dynamic>;
      // Try to get menuItemId from various possible fields
      final itemId = itemMap['menuItemId']?.toString() ??
          itemMap['_id']?.toString() ??
          itemMap['id']?.toString() ??
          itemMap['menuItem']?['_id']?.toString() ??
          itemMap['menuItem']?['id']?.toString() ??
          '';
      if (itemId.isNotEmpty) {
        _itemCommentControllers[itemId] = TextEditingController();
        _itemRatings[itemId] = 5;
        _itemTags[itemId] = [];
        
        // Pre-fill item review if exists
        final itemReview = itemsReview[itemId] as Map<String, dynamic>?;
        if (itemReview != null) {
          _itemRatings[itemId] = itemReview['rating'] as int? ?? 5;
          final comment = itemReview['comment']?.toString();
          if (comment != null && comment.isNotEmpty) {
            _itemCommentControllers[itemId]?.text = comment;
          }
          final tags = itemReview['tags'] as List<dynamic>?;
          if (tags != null) {
            _itemTags[itemId] = tags.map((e) => e.toString()).toList();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _restaurantCommentController.dispose();
    for (final controller in _itemCommentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleTag(String tag, {String? itemId}) {
    setState(() {
      if (itemId != null) {
        final tags = _itemTags[itemId] ?? [];
        if (tags.contains(tag)) {
          tags.remove(tag);
        } else {
          tags.add(tag);
        }
        _itemTags[itemId] = tags;
      } else {
        if (_restaurantTags.contains(tag)) {
          _restaurantTags.remove(tag);
        } else {
          _restaurantTags.add(tag);
        }
      }
    });
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final orderId = widget.order['_id']?.toString() ?? widget.order['id']?.toString() ?? '';
      final restaurantId = widget.order['restaurantId']?.toString() ?? '';
      final items = widget.order['items'] as List<dynamic>? ?? [];
      final review = widget.order['review'] as Map<String, dynamic>?;
      final restaurantReview = review?['restaurant'] as Map<String, dynamic>?;
      final itemsReview = review?['items'] as Map<String, dynamic>? ?? {};

      if (orderId.isEmpty || restaurantId.isEmpty) {
        throw const ApiException(message: 'Thông tin đơn hàng không hợp lệ');
      }

      // Submit restaurant review only if not already reviewed
      if (restaurantReview == null) {
        await _reviewRepository.createReview(
          orderId: orderId,
          restaurantId: restaurantId,
          rating: _restaurantRating,
          comment: _restaurantCommentController.text.trim().isNotEmpty
              ? _restaurantCommentController.text.trim()
              : null,
          tags: _restaurantTags.isNotEmpty ? _restaurantTags : null,
        );
      }

      // Submit reviews for each menu item only if not already reviewed
      for (final item in items) {
        final itemMap = item as Map<String, dynamic>;
        // Try to get menuItemId from various possible fields
        final menuItemId = itemMap['menuItemId']?.toString() ??
            itemMap['_id']?.toString() ??
            itemMap['id']?.toString() ??
            itemMap['menuItem']?['_id']?.toString() ??
            itemMap['menuItem']?['id']?.toString() ??
            '';
        
        if (menuItemId.isEmpty) continue;
        
        // Skip if already reviewed
        if (itemsReview.containsKey(menuItemId)) continue;

        final rating = _itemRatings[menuItemId] ?? 5;
        final comment = _itemCommentControllers[menuItemId]?.text.trim();
        final tags = _itemTags[menuItemId];

        await _reviewRepository.createReview(
          orderId: orderId,
          restaurantId: restaurantId,
          menuItemId: menuItemId,
          rating: rating,
          comment: comment?.isNotEmpty == true ? comment : null,
          tags: tags?.isNotEmpty == true ? tags : null,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đánh giá thành công! Cảm ơn bạn đã đánh giá.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi đánh giá. Vui lòng thử lại.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantName = widget.order['restaurant']?['name']?.toString() ??
        'Nhà hàng';
    final items = widget.order['items'] as List<dynamic>? ?? [];
    final review = widget.order['review'] as Map<String, dynamic>?;
    final restaurantReview = review?['restaurant'] as Map<String, dynamic>?;
    final isRestaurantReviewed = restaurantReview != null;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Đánh giá đơn hàng',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Review Section
            Container(
              padding: EdgeInsets.all(16.w),
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 24.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đánh giá nhà hàng',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    restaurantName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ),
                                if (isRestaurantReviewed) ...[
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.check_circle,
                                    size: 16.sp,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Đã đánh giá',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Rating Stars
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: isRestaurantReviewed ? null : () {
                            setState(() {
                              _restaurantRating = starIndex;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(
                              starIndex <= _restaurantRating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 40.sp,
                              color: starIndex <= _restaurantRating
                                  ? Colors.amber
                                  : AppColors.lightGrey,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Comment
                  TextField(
                    controller: _restaurantCommentController,
                    maxLines: 4,
                    enabled: !isRestaurantReviewed,
                    decoration: InputDecoration(
                      hintText: isRestaurantReviewed 
                          ? 'Đã đánh giá' 
                          : 'Chia sẻ trải nghiệm của bạn về nhà hàng...',
                      hintStyle: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 14.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.lightGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.lightGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.green.withOpacity(0.3)),
                      ),
                      contentPadding: EdgeInsets.all(16.w),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Tags
                  Text(
                    'Tags (tùy chọn)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _availableTags.map((tag) {
                      final isSelected = _restaurantTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: isRestaurantReviewed ? null : (_) => _toggleTag(tag),
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textGrey,
                          fontSize: 13.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.lightGrey,
                            width: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Menu Items Reviews
            if (items.isNotEmpty) ...[
              Text(
                'Đánh giá món ăn',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 12.h),
              ...items.map((item) {
                final itemMap = item as Map<String, dynamic>;
                // Try to get menuItemId from various possible fields
                final itemId = itemMap['menuItemId']?.toString() ??
                    itemMap['_id']?.toString() ??
                    itemMap['id']?.toString() ??
                    itemMap['menuItem']?['_id']?.toString() ??
                    itemMap['menuItem']?['id']?.toString() ??
                    '';
                final itemName = itemMap['name']?.toString() ??
                    itemMap['menuItem']?['name']?.toString() ??
                    'Món ăn';
                final imageUrl = itemMap['imageUrl']?.toString() ??
                    itemMap['menuItem']?['imageUrl']?.toString();
                final rating = _itemRatings[itemId] ?? 5;
                final tags = _itemTags[itemId] ?? [];
                
                // Check if already reviewed
                final review = widget.order['review'] as Map<String, dynamic>?;
                final itemsReview = review?['items'] as Map<String, dynamic>? ?? {};
                final isReviewed = itemsReview.containsKey(itemId);

                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.all(16.w),
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
                      Row(
                        children: [
                          // Item Image
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              color: AppColors.lightGrey,
                              image: imageUrl != null && imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                      onError: (_, __) {},
                                    )
                                  : null,
                            ),
                            child: imageUrl == null || imageUrl.isEmpty
                                ? Icon(Icons.fastfood, size: 30.sp, color: AppColors.grey)
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ),
                                if (isReviewed) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14.sp,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Đã đánh giá',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Rating Stars
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            return GestureDetector(
                              onTap: isReviewed ? null : () {
                                setState(() {
                                  _itemRatings[itemId] = starIndex;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: Icon(
                                  starIndex <= rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 32.sp,
                                  color: starIndex <= rating
                                      ? Colors.amber
                                      : AppColors.lightGrey,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Comment
                      TextField(
                        controller: _itemCommentControllers[itemId],
                        maxLines: 3,
                        enabled: !isReviewed,
                        decoration: InputDecoration(
                          hintText: isReviewed ? 'Đã đánh giá' : 'Chia sẻ về món này...',
                          hintStyle: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14.sp,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.green.withOpacity(0.3)),
                          ),
                          contentPadding: EdgeInsets.all(16.w),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Tags
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _availableTags.map((tag) {
                          final isSelected = tags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: isReviewed ? null : (_) => _toggleTag(tag, itemId: itemId),
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textGrey,
                              fontSize: 12.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.lightGrey,
                                width: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
            SizedBox(height: 24.h),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Gửi đánh giá',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

