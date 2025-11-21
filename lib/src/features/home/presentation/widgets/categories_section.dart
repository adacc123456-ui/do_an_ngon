import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/category.dart';
import 'package:flutter_svg/svg.dart';

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  late Future<List<Category>> _futureCategories;
  final _repository = GetIt.I<RestaurantRepository>();

  @override
  void initState() {
    super.initState();
    _futureCategories = _repository.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120.h,
      child: FutureBuilder<List<Category>>(
        future: _futureCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không thể tải danh mục món ăn.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14.sp,
                ),
              ),
            );
          }

          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'Chưa có danh mục.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14.sp,
                ),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryItem(category: category);
            },
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;

  const _CategoryItem({required this.category});

  bool get _hasIcon => category.icon != null && category.icon!.isNotEmpty;
  bool get _isRemoteIcon => _hasIcon && category.icon!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (_hasIcon) {
      if (_isRemoteIcon) {
        iconWidget = Image.network(
          category.icon!,
          width: 55.w,
          height: 55.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _IconFallback(),
        );
      } else {
        iconWidget = SvgPicture.asset(
          category.icon!,
          width: 55.w,
          height: 55.h,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => _IconFallback(),
        );
      }
    } else {
      iconWidget = _IconFallback();
    }

    return GestureDetector(
      onTap: () {
        context.push('/category-foods', extra: category);
      },
      child: Container(
        width: 70.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(55.r),
              child: SizedBox(
                width: 55.w,
                height: 55.h,
                child: iconWidget,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.black,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(55.r),
      ),
      child: Icon(
        Icons.restaurant_menu,
        color: AppColors.grey,
        size: 28.sp,
      ),
    );
  }
}
