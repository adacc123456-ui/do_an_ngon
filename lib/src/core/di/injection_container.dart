import 'package:get_it/get_it.dart';
import 'package:do_an_ngon/src/features/splash/data/repositories/splash_repository_impl.dart';
import 'package:do_an_ngon/src/features/splash/domain/repositories/splash_repository.dart';
import 'package:do_an_ngon/src/features/splash/domain/usecases/initialize_app_usecase.dart';
import 'package:do_an_ngon/src/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:do_an_ngon/src/core/services/local_storage_service.dart';
import 'package:do_an_ngon/src/core/network/api_client.dart';
import 'package:do_an_ngon/src/features/auth/data/repositories/auth_repository.dart';
import 'package:do_an_ngon/src/features/home/data/repositories/restaurant_repository.dart';
import 'package:do_an_ngon/src/features/orders/data/repositories/order_repository.dart';
import 'package:do_an_ngon/src/features/account/data/repositories/user_address_repository.dart';
import 'package:do_an_ngon/src/features/vendor/data/repositories/vendor_repository.dart';
import 'package:do_an_ngon/src/features/reviews/data/repositories/review_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  _initCore();

  // Features - Splash
  _initSplash();

  // Features - Cart
  _initCart();

  // Features - Auth
  _initAuth();

  // Features - Favorites
  _initFavorites();

  // Add other feature initializations here
}

void _initCore() {
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(localStorageService: sl()));
  sl.registerLazySingleton<RestaurantRepository>(
    () => RestaurantRepository(apiClient: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(() => OrderRepository(apiClient: sl()));
  sl.registerLazySingleton<UserAddressRepository>(() => UserAddressRepository(apiClient: sl()));
  sl.registerLazySingleton<VendorRepository>(() => VendorRepository(apiClient: sl()));
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepository(apiClient: sl()));
}

void _initSplash() {
  // Repository
  sl.registerLazySingleton<SplashRepository>(
    () => SplashRepositoryImpl(),
  );

  // Use cases
  sl.registerLazySingleton(() => InitializeAppUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => SplashBloc(
      initializeAppUseCase: sl(),
    ),
  );
}

void _initCart() {
  // Bloc - Singleton để giữ state giỏ hàng
  sl.registerLazySingleton<CartBloc>(() => CartBloc(localStorageService: sl()));
}

void _initAuth() {
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(apiClient: sl()));

  // Bloc - Singleton để giữ auth state
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      localStorageService: sl(),
      authRepository: sl(),
    ),
  );
}

void _initFavorites() {
  // Bloc - Singleton để giữ favorites state
  sl.registerLazySingleton<FavoritesBloc>(
    () => FavoritesBloc(localStorageService: sl()),
  );
}

