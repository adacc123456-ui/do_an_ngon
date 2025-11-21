import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberPassword = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(
        title: '',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            // App Logo/Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  assetPath: 'assets/svgs/fork_knife.svg',
                  width: 32,
                  height: 32,
                  color: AppColors.primary,
                  fallbackIcon: Icons.restaurant,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Hôm nay ăn gì',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            // Screen Title
            Text(
              'Đăng nhập',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32.h),
            // Identifier Field
            Text(
              'Email hoặc số điện thoại',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _identifierController,
              decoration: InputDecoration(
                hintText: 'Nhập email hoặc số điện thoại',
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
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 24.h),
            // Password Field
            Text(
              'Mật khẩu',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
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
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 16.h),
            // Remember Password & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberPassword,
                      onChanged: (value) {
                        setState(() {
                          _rememberPassword = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      'Nhớ mật khẩu',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.go('/forgot-password');
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            // Login Button
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }

                if (state.isAuthenticated && !state.isLoading) {
                  if (state.isVendor) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng nhập với quyền chủ cửa hàng.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    context.go('/vendor-dashboard');
                  } else {
                    context.go('/home');
                  }
                }
              },
              builder: (context, state) {
                final isFormValid =
                    _identifierController.text.isNotEmpty && _passwordController.text.isNotEmpty;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isLoading || !isFormValid
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                                  LoginEvent(
                                    identifier: _identifierController.text.trim(),
                                    password: _passwordController.text,
                                  ),
                                );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: state.isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Đăng Nhập',
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
            SizedBox(height: 24.h),
            // Register Link
            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 14.sp,
                  ),
                  children: [
                    const TextSpan(text: 'Chưa có tài khoản? '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          'Đăng Ký',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12.h),
            // Vendor Register Link
            Center(
              child: TextButton(
                onPressed: () {
                  context.go('/vendor-register');
                },
                child: Text(
                  'Đăng ký chủ cửa hàng',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

