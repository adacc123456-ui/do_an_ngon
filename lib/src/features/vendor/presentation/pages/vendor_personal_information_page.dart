import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';

class VendorPersonalInformationPage extends StatefulWidget {
  const VendorPersonalInformationPage({super.key});

  @override
  State<VendorPersonalInformationPage> createState() =>
      _VendorPersonalInformationPageState();
}

class _VendorPersonalInformationPageState extends State<VendorPersonalInformationPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  bool _isEditingName = false;
  bool _isEditingPhone = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _nameController = TextEditingController(text: authState.userName ?? '');
    _phoneController = TextEditingController(text: authState.userPhone ?? '');
    _emailController = TextEditingController(text: authState.userEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppHeader(
        title: 'Thông tin cá nhân',
        showBackButton: true,
        onBackPressed: () {
          context.go('/vendor-account-information');
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
            SizedBox(height: 32.h),
            // Input Fields
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  _InputField(
                    label: 'Tên',
                    controller: _nameController,
                    isEditing: _isEditingName,
                    onEditTap: () {
                      setState(() {
                        _isEditingName = !_isEditingName;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  // Phone Field
                  _InputField(
                    label: 'Số điện thoại',
                    controller: _phoneController,
                    isEditing: _isEditingPhone,
                    prefixText: '84+',
                    onEditTap: () {
                      setState(() {
                        _isEditingPhone = !_isEditingPhone;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  // Email Field (Read-only - không thể thay đổi)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _emailController.text.isNotEmpty 
                                    ? _emailController.text 
                                    : 'Chưa có email',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.lock_outline,
                              color: AppColors.grey,
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Email không thể thay đổi. Vui lòng liên hệ hỗ trợ nếu cần thay đổi email.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            // Save Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state.isLoading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        // Save user info (không gửi email vì backend không cho phép)
                        context.read<AuthBloc>().add(
                              UpdateUserInfoEvent(
                                name: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                email: null, // Không gửi email vì backend không cho phép cập nhật
                              ),
                            );
                        
                        // Wait for the update to complete
                        await Future.delayed(const Duration(milliseconds: 500));
                        
                        if (!mounted) return;
                        
                        final updatedState = context.read<AuthBloc>().state;
                        if (updatedState.errorMessage == null) {
                          setState(() {
                            _isEditingName = false;
                            _isEditingPhone = false;
                          });
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã lưu thông tin thành công'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          // Navigate back
                          context.go('/vendor-account-information');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              'Lưu lại',
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
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final String? prefixText;
  final VoidCallback onEditTap;

  const _InputField({
    required this.label,
    required this.controller,
    required this.isEditing,
    this.prefixText,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: GestureDetector(
            onTap: !isEditing ? onEditTap : null,
            behavior: HitTestBehavior.opaque,
            child: TextField(
              controller: controller,
              enabled: isEditing,
              readOnly: !isEditing,
              style: TextStyle(
                color: AppColors.black,
                fontSize: 16.sp,
              ),
              decoration: InputDecoration(
                prefixText: prefixText != null ? '$prefixText ' : null,
                prefixStyle: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                suffixIcon: GestureDetector(
                  onTap: onEditTap,
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Icon(
                      isEditing ? Icons.check : Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

