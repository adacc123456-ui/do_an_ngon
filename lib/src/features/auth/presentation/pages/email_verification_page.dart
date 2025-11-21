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
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';

class EmailVerificationPage extends StatefulWidget {
  final String? initialEmail;

  const EmailVerificationPage({super.key, this.initialEmail});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final AuthRepository _authRepository = GetIt.I<AuthRepository>();

  bool _isSending = false;
  bool _isConfirming = false;
  bool _initialized = false;
  String? _errorMessage;
  int _countdown = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final authState = context.read<AuthBloc>().state;
    final email = widget.initialEmail ?? authState.userEmail;
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$');
    return emailRegex.hasMatch(value);
  }

  void _startCountdown({int? start}) {
    if (start != null) {
      setState(() => _countdown = start);
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      }
    });
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Email không hợp lệ.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.requestEmailVerification(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi mã xác minh đến $email'),
          backgroundColor: AppColors.primary,
        ),
      );
      _startCountdown(start: 60);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể gửi mã xác minh. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmVerification() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Email không hợp lệ.');
      return;
    }
    if (code.length != 6) {
      setState(() => _errorMessage = 'Mã xác minh phải gồm 6 chữ số.');
      return;
    }

    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    try {
      // Backend mới: xác minh email sẽ tạo tài khoản và trả về tokens
      final authResponse = await _authRepository.confirmEmailVerification(email: email, code: code);
      if (!mounted) return;
      
      // Đăng nhập tự động sau khi xác minh email thành công
      context.read<AuthBloc>().add(CompleteAuthEvent(authResponse));
      
      // Wait a bit for auth state to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác minh email thành công! Đã đăng nhập tự động.'),
          backgroundColor: AppColors.primary,
        ),
      );
      
      if (!mounted) return;
      
      final updatedAuthState = context.read<AuthBloc>().state;
      if (updatedAuthState.isAuthenticated && updatedAuthState.isVendor) {
        context.go('/vendor-dashboard');
      } else {
        context.go('/home');
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Không thể xác minh email. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
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
            Text(
              'Xác minh email',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Nhập email và mã xác minh gồm 6 chữ số được gửi tới hộp thư của bạn.',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Email',
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
            SizedBox(height: 24.h),
            Text(
              'Mã xác minh',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Nhập mã 6 chữ số',
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
            SizedBox(height: 16.h),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 12.h),
            ],
            ElevatedButton(
              onPressed: (_isSending || _countdown > 0) ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h,horizontal: 20.w,),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isSending
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      _countdown > 0 ? 'Gửi lại mã sau ${_countdown}s' : 'Gửi lại mã xác minh',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirmVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isConfirming
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(
                        'Xác minh',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Nếu bạn không thấy email xác minh, hãy kiểm tra hộp thư spam hoặc nhấn “Gửi mã xác minh” để nhận lại.',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

