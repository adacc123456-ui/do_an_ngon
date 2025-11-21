import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:do_an_ngon/src/core/di/injection_container.dart' as di;
import 'package:do_an_ngon/src/core/routes/app_router.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️  Không tìm thấy file .env, sử dụng cấu hình mặc định. Chi tiết: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnv();

  // Initialize dependency injection
  await di.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<CartBloc>.value(
              value: di.sl<CartBloc>(),
            ),
            BlocProvider<AuthBloc>.value(
              value: di.sl<AuthBloc>(),
            ),
          ],
          child: MaterialApp.router(
            title: 'Hôm nay ăn gì',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFF76B1C),
              ),
              useMaterial3: true,
            ),
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
