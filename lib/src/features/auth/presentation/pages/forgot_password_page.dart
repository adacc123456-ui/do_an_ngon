import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/widgets/app_header.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/auth/data/repositories/auth_repository.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';

class ForgotPasswordFlowData {
  final String email;
  final String? code;

  const ForgotPasswordFlowData({required this.email, this.code});
}

class ForgotPasswordPage extends StatefulWidget {
  final int step; // 1: Email, 2: OTP, 3: Reset Password
  final String? initialEmail;
  final String? initialCode;

  const ForgotPasswordPage({
    super.key,
    this.step = 1,
    this.initialEmail,
    this.initialCode,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late int _currentStep;
  late final TextEditingController _emailController;
  late final TextEditingController _otpController;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 600; // 10:00 in seconds
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _email;
  String? _code;

  AuthRepository get _authRepository => GetIt.I<AuthRepository>();

  @override
  void initState() {
    super.initState();
    _currentStep = widget.step;
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _otpController = TextEditingController(text: widget.initialCode ?? '');
    _email = widget.initialEmail;
    _code = widget.initialCode;

    if (_currentStep == 2) {
      _startCountdown(reset: true);
    }
  }

  void _startCountdown({bool reset = false}) {
    if (reset) {
      setState(() => _countdown = 600);
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_currentStep == 2 && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$');
    return emailRegex.hasMatch(value);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    switch (_currentStep) {
      case 1:
        await _submitEmail();
        break;
      case 2:
        await _submitOtp();
        break;
      case 3:
        await _submitNewPassword();
        break;
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Email không hợp lệ.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authRepository.requestPasswordReset(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi mã xác thực tới $email'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go(
        '/forgot-password/otp',
        extra: ForgotPasswordFlowData(email: email),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể gửi mã xác thực. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Vui lòng nhập mã gồm 6 chữ số.');
      return;
    }
    if (_email == null || !_isValidEmail(_email!)) {
      setState(() => _errorMessage = 'Email không hợp lệ. Vui lòng quay lại bước đầu tiên.');
      return;
    }

    context.go(
      '/forgot-password/reset',
      extra: ForgotPasswordFlowData(email: _email!, code: code),
    );
  }

  Future<void> _submitNewPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }
    if (_email == null || _code == null) {
      setState(() => _errorMessage = 'Thiếu thông tin xác thực. Vui lòng làm lại từ đầu.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authRepository.resetPassword(
        email: _email!,
        code: _code!,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/login');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể đặt lại mật khẩu. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_email == null) return;
    setState(() => _isSubmitting = true);
    try {
      await _authRepository.requestPasswordReset(email: _email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi lại mã tới $_email'),
          backgroundColor: AppColors.primary,
        ),
      );
      _startCountdown(reset: true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể gửi lại mã. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(
        title: '',
        showBackButton: true,
        onBackPressed: () {
          final authState = context.read<AuthBloc>().state;
          final router = GoRouter.of(context);
          
          // Nếu là vendor, quay về vendor account information
          if (authState.isVendor) {
            router.go('/vendor-account-information');
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
              _currentStep == 1
                  ? 'Quên mật khẩu'
                  : _currentStep == 2
                      ? 'Nhập mã xác thực'
                      : 'Đặt lại mật khẩu',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            if (_currentStep == 1)
              Text(
                'Nhập email đã đăng ký để nhận mã xác thực đặt lại mật khẩu.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
              ),
            if (_currentStep == 2)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã xác thực đã được gửi tới $_email.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Mã sẽ hết hạn sau ${_formatCountdown(_countdown)}.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
                  ),
                ],
              ),
            if (_currentStep == 3)
              Text(
                'Mật khẩu mới cần khác với mật khẩu hiện tại.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
              ),
            SizedBox(height: 32.h),
            if (_currentStep == 1) _buildEmailStep(),
            if (_currentStep == 2) _buildOtpStep(),
            if (_currentStep == 3) _buildResetStep(),
            SizedBox(height: 32.h),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 16.h),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(
                        _currentStep == 3 ? 'Đặt lại mật khẩu' : 'Tiếp tục',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (_currentStep == 2) ...[
              SizedBox(height: 12.h),
              TextButton(
                onPressed: (_countdown == 0 && !_isSubmitting) ? _resendCode : null,
                child: Text(
                  _countdown == 0 ? 'Gửi lại mã' : 'Gửi lại mã sau ${_formatCountdown(_countdown)}',
                  style: TextStyle(
                    color: _countdown == 0 ? AppColors.primary : AppColors.grey,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email đã đăng ký',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Nhập email',
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
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mã xác thực (6 chữ số)',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Nhập mã',
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
        ),
      ],
    );
  }

  Widget _buildResetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mật khẩu mới',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
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
        ),
        SizedBox(height: 24.h),
        Text(
          'Xác nhận mật khẩu mới',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
        ),
      ],
    );
  }
}
