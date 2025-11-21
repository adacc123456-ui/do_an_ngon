import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.lightGrey, width: 1),
        ),
        child: Row(
          children: [
            SvgIcon(
              assetPath: 'assets/svgs/search.svg',
              width: 20,
              height: 20,
              color: AppColors.primary,
              fallbackIcon: Icons.search,
            ),
            SizedBox(width: 8.w),
            Text(
              'Tìm kiếm món ăn',
              style: TextStyle(color: AppColors.grey, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}
