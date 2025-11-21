import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        image: DecorationImage(
          image: AssetImage('assets/images/backgroud_header.png'),
          fit: BoxFit.cover,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        child: Row(
          children: [
            if (showBackButton)
              GestureDetector(
                onTap: onBackPressed ??
                    () {
                      final router = GoRouter.of(context);  
                      try {
                        if (router.canPop()) {
                          router.pop();
                        } else {
                          context.go('/home');
                        }
                      } catch (e) {
                        context.go('/home');
                      }
                    },
                child: Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: SvgIcon(
                    assetPath: 'assets/svgs/arrow_back.svg',
                    width: 24,
                    height: 24,
                    color: AppColors.white,
                    fallbackIcon: Icons.arrow_back,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (trailing != null) trailing!,
            if (showBackButton && trailing == null) SizedBox(width: 40.w),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}
