import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';

class AccountInformationPage extends StatelessWidget {
  const AccountInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Thông tin Tài khoản',
        showBackButton: true,
        onBackPressed: () {
          final authState = context.read<AuthBloc>().state;
          final router = GoRouter.of(context);
          
          // Nếu là vendor, quay về vendor dashboard
          if (authState.isVendor) {
            router.go('/vendor-dashboard');
          } else {
            // Nếu không phải vendor, dùng logic back mặc định
            try {
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/home');
              }
            } catch (e) {
              router.go('/home');
            }
          }
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
                color: AppColors.grey,
                border: Border.all(
                  color: AppColors.white,
                  width: 4,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 60.sp,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 16.h),
            // User Name
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Text(
                  state.userName ?? 'Người dùng',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final roleLabel = state.isVendor ? 'Chủ cửa hàng' : 'Khách hàng';
                return Container(
                  margin: EdgeInsets.only(top: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: state.isVendor
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: state.isVendor ? AppColors.primary : AppColors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
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
                      context.go('/personal-information');
                    },
                  ),
                  SizedBox(height: 12.h),
                  // Addresses
                  _MenuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Địa chỉ giao hàng',
                    onTap: () {
                      context.go('/addresses');
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
                    context.go('/home');
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

