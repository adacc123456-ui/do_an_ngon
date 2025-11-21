import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';

class VendorAccountInformationPage extends StatelessWidget {
  const VendorAccountInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Cài đặt tài khoản',
        showBackButton: true,
        onBackPressed: () {
          context.go('/vendor-dashboard');
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 32.h),
            // Profile Picture
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: AppColors.white,
                  width: 4,
                ),
              ),
              child: Icon(
                Icons.restaurant,
                size: 60.sp,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 16.h),
            // User Name
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Text(
                  state.userName ?? 'Chủ cửa hàng',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            Container(
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Chủ cửa hàng',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // Menu Items
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  // Personal Information
                  _MenuTile(
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    onTap: () {
                      context.go('/vendor-personal-information');
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Menu Items
                  _MenuTile(
                    icon: Icons.restaurant_menu,
                    title: 'Danh sách món ăn',
                    onTap: () {
                      context.go('/vendor-menu-items');
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Change Password
                  _MenuTile(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    onTap: () {
                      context.go('/forgot-password');
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            // Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (!state.isAuthenticated) {
                    context.go('/login');
                  }
                },
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(const LogoutEvent());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Đăng Xuất',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.black,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
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

