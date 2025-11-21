import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/di/injection_container.dart' as di;
import 'package:do_an_ngon/src/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:do_an_ngon/src/features/splash/presentation/pages/splash_page.dart';
import 'package:do_an_ngon/src/features/home/presentation/pages/home_page.dart';
import 'package:do_an_ngon/src/features/auth/presentation/pages/login_page.dart';
import 'package:do_an_ngon/src/features/auth/presentation/pages/register_page.dart';
import 'package:do_an_ngon/src/features/auth/presentation/pages/vendor_register_page.dart';
import 'package:do_an_ngon/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:do_an_ngon/src/features/auth/presentation/pages/email_verification_page.dart';
import 'package:do_an_ngon/src/features/account/presentation/pages/account_information_page.dart';
import 'package:do_an_ngon/src/features/account/presentation/pages/personal_information_page.dart';
import 'package:do_an_ngon/src/features/account/presentation/pages/addresses_page.dart';
import 'package:do_an_ngon/src/features/account/presentation/pages/add_edit_address_page.dart';
import 'package:do_an_ngon/src/features/account/domain/entities/user_address.dart';
import 'package:do_an_ngon/src/features/random/presentation/pages/random_food_page.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/pages/favorites_page.dart';
import 'package:do_an_ngon/src/features/food/presentation/pages/food_detail_page.dart';
import 'package:do_an_ngon/src/features/cart/presentation/pages/cart_page.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/category.dart';
import 'package:do_an_ngon/src/features/home/presentation/pages/category_foods_page.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/restaurant.dart';
import 'package:do_an_ngon/src/features/home/presentation/pages/restaurant_detail_page.dart';
import 'package:do_an_ngon/src/features/vendor/presentation/pages/vendor_dashboard_page.dart';
import 'package:do_an_ngon/src/features/vendor/presentation/pages/vendor_account_information_page.dart';
import 'package:do_an_ngon/src/features/vendor/presentation/pages/vendor_personal_information_page.dart';
import 'package:do_an_ngon/src/features/vendor/presentation/pages/vendor_menu_items_page.dart';
import 'package:do_an_ngon/src/features/orders/presentation/pages/orders_page.dart';
import 'package:do_an_ngon/src/features/orders/presentation/pages/order_detail_page.dart';
import 'package:do_an_ngon/src/features/reviews/presentation/pages/review_order_page.dart';
import 'package:do_an_ngon/src/features/search/presentation/pages/search_page.dart';

// Helper class for custom page transitions
class CustomTransitionPage extends Page<void> {
  final Widget child;
  final Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  )
  transitionsBuilder;

  const CustomTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    super.key,
  });

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: transitionsBuilder,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder:
            (context, state) => BlocProvider<SplashBloc>(
              create: (_) => di.sl<SplashBloc>(),
              child: const SplashPage(),
            ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<CartBloc>.value(
                    value: di.sl<CartBloc>(),
                  ),
                  BlocProvider<AuthBloc>.value(
                    value: di.sl<AuthBloc>(),
                  ),
                ],
                child: const HomePage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/vendor-dashboard',
        name: 'vendor-dashboard',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<AuthBloc>.value(
                value: di.sl<AuthBloc>(),
                child: const VendorDashboardPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/vendor-account-information',
        name: 'vendor-account-information',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<AuthBloc>.value(
                value: di.sl<AuthBloc>(),
                child: const VendorAccountInformationPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        path: '/vendor-personal-information',
        name: 'vendor-personal-information',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<AuthBloc>.value(
                value: di.sl<AuthBloc>(),
                child: const VendorPersonalInformationPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        path: '/vendor-menu-items',
        name: 'vendor-menu-items',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<AuthBloc>.value(
                value: di.sl<AuthBloc>(),
                child: const VendorMenuItemsPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => BlocProvider<AuthBloc>.value(
          value: di.sl<AuthBloc>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => BlocProvider<AuthBloc>.value(
          value: di.sl<AuthBloc>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/vendor-register',
        name: 'vendor-register',
        builder: (context, state) => BlocProvider<AuthBloc>.value(
          value: di.sl<AuthBloc>(),
          child: const VendorRegisterPage(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.extra is String ? state.extra as String : null;
          return BlocProvider<AuthBloc>.value(
            value: di.sl<AuthBloc>(),
            child: EmailVerificationPage(initialEmail: email),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(step: 1),
      ),
      GoRoute(
        path: '/forgot-password/otp',
        name: 'forgot-password-otp',
        builder: (context, state) {
          final data = state.extra is ForgotPasswordFlowData ? state.extra as ForgotPasswordFlowData : null;
          return ForgotPasswordPage(
            step: 2,
            initialEmail: data?.email,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password/reset',
        name: 'forgot-password-reset',
        builder: (context, state) {
          final data = state.extra is ForgotPasswordFlowData ? state.extra as ForgotPasswordFlowData : null;
          return ForgotPasswordPage(
            step: 3,
            initialEmail: data?.email,
            initialCode: data?.code,
          );
        },
      ),
      GoRoute(
        path: '/account-information',
        name: 'account-information',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<AuthBloc>.value(
                value: di.sl<AuthBloc>(),
                child: const AccountInformationPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        path: '/personal-information',
        name: 'personal-information',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<AuthBloc>.value(
                value: di.sl<AuthBloc>(),
                child: const PersonalInformationPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        path: '/addresses',
        name: 'addresses',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AddressesPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        path: '/add-edit-address',
        name: 'add-edit-address',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: AddEditAddressPage(
                address: state.extra is UserAddress ? state.extra as UserAddress : null,
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                );
              },
            ),
      ),
      GoRoute(
        path: '/random-food',
        name: 'random-food',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RandomFoodPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
            ),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<FavoritesBloc>.value(
                value: di.sl<FavoritesBloc>(),
                child: const FavoritesPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: BlocProvider<AuthBloc>.value(
                value: di.sl<AuthBloc>(),
                child: const OrdersPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/orders/:orderId',
        name: 'order-detail',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: BlocProvider<AuthBloc>.value(
              value: di.sl<AuthBloc>(),
              child: OrderDetailPage(orderId: orderId),
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderId/review',
        name: 'review-order',
        pageBuilder: (context, state) {
          final order = state.extra as Map<String, dynamic>?;
          if (order == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Order not found')),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: BlocProvider<AuthBloc>.value(
              value: di.sl<AuthBloc>(),
              child: ReviewOrderPage(order: order),
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: SearchPage(initialQuery: query),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/category-foods',
        name: 'category-foods',
        pageBuilder: (context, state) {
          final category = state.extra as Category?;
          if (category == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Category not found')),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: CategoryFoodsPage(category: category),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/restaurant-detail',
        name: 'restaurant-detail',
        pageBuilder: (context, state) {
          final restaurant = state.extra as Restaurant?;
          if (restaurant == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Restaurant not found')),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: RestaurantDetailPage(restaurant: restaurant),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/food-detail',
        name: 'food-detail',
        pageBuilder: (context, state) {
          final food = state.extra as Food?;
          if (food == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Food not found')),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<CartBloc>.value(
                  value: di.sl<CartBloc>(),
                ),
                BlocProvider<FavoritesBloc>.value(
                  value: di.sl<FavoritesBloc>(),
                ),
              ],
              child: FoodDetailPage(food: food),
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<CartBloc>.value(
                    value: di.sl<CartBloc>(),
                  ),
                  BlocProvider<AuthBloc>.value(
                    value: di.sl<AuthBloc>(),
                  ),
                ],
                child: const CartPage(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
    ],
  );
}
