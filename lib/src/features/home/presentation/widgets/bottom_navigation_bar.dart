import 'package:do_an_ngon/src/resources/generated/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';

class HomeBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const HomeBottomNavigationBar({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Container(
          height: 70.h,
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home Tab
              _BottomNavItem(
                iconPath: 'assets/svgs/home.svg',
                label: 'Trang chủ',
                isActive: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    context.go('/home');
                  }
                },
              ),
              // Favorites Tab
              _BottomNavItem(
                iconPath: Assets.svgs.iconFavorite.path,
                label: 'Yêu thích',
                isActive: currentIndex == 1,
                onTap: () {
                  if (currentIndex != 1) {
                    context.go('/favorites');
                  }
                },
              ),
              // Cart Tab
              _BottomNavItem(
                iconPath: '',
                label: 'Giỏ hàng',
                isActive: currentIndex == 2,
                onTap: () {
                  if (currentIndex != 2) {
                    context.go('/cart');
                  }
                },
                icon: Icons.shopping_cart,
              ),
              // Orders Tab - chỉ hiển thị khi đã đăng nhập
              if (authState.isAuthenticated)
                _BottomNavItem(
                  iconPath: '',
                  label: 'Đơn hàng',
                  isActive: currentIndex == 3,
                  onTap: () {
                    if (currentIndex != 3) {
                      context.go('/orders');
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  const _BottomNavItem({
    required this.iconPath,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconPath.isEmpty
              ? Icon(
                  icon ?? (isActive ? Icons.shopping_bag : Icons.shopping_bag_outlined),
                  size: 24.sp,
                  color: isActive ? AppColors.primary : AppColors.darkGrey,
                )
              : SvgIcon(
                  assetPath: iconPath,
                  width: 24,
                  height: 24,
                  color: isActive ? AppColors.primary : AppColors.darkGrey,
                  fallbackIcon:
                      iconPath.contains('home')
                          ? Icons.home
                          : iconPath.contains('heart')
                          ? (isActive ? Icons.favorite : Icons.favorite_border)
                          : Icons.help_outline,
                ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.darkGrey,
              fontSize: 12.sp,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
