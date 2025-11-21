import 'package:do_an_ngon/src/features/splash/presentation/bloc/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/constants/app_constants.dart';
import 'package:do_an_ngon/src/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Initialize app
    context.read<SplashBloc>().add(const InitializeAppEvent());

    // Fallback navigation after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_hasNavigated) _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final authState = context.read<AuthBloc>().state;
          if (authState.isAuthenticated && authState.isVendor) {
            context.go('/vendor-dashboard');
          } else {
            context.go('/home');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state.status == SplashStatus.completed && !_hasNavigated) {
          _navigateToHome();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: Center(
          child: Image.asset(
            AppConstants.splashLottiePath,
            width: 200.w,
            height: 200.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
