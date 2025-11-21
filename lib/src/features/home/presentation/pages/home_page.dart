import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/home_search_bar.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/categories_section.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/bestselling_foods_section.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/promotional_banner.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/featured_restaurants_section.dart';
import 'package:do_an_ngon/src/features/home/presentation/widgets/bottom_navigation_bar.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:do_an_ngon/src/resources/generated/assets.gen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeaderHeight = 220.h;
    final double minHeaderHeight = 100.h;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          /// ===========================
          /// Scrollable content
          /// ===========================
          NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.axis == Axis.vertical) {
                _scrollOffset.value = scroll.metrics.pixels;
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: maxHeaderHeight + 150.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: CategoriesSection(),
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const BestsellingFoodsSection(),
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const FeaturedRestaurantsSection(),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),

          /// ===========================
          /// Animated Collapsing Header
          /// ===========================
          ValueListenableBuilder<double>(
            valueListenable: _scrollOffset,
            builder: (context, offset, _) {
              // 0 -> chưa cuộn, 1 -> đã cuộn đủ để header thu nhỏ hoàn toàn
              final double progress = (offset /
                      (maxHeaderHeight - minHeaderHeight))
                  .clamp(0.0, 1.0);

              final double currentHeight =
                  maxHeaderHeight -
                  (maxHeaderHeight - minHeaderHeight) * progress;

              return ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24.r),
                ),
                child: Container(
                  height: currentHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    image: DecorationImage(
                      image: AssetImage(Assets.images.backgroudHeader.path),
                      fit: BoxFit.none,
                      repeat: ImageRepeat.repeat,
                      alignment: Alignment.topLeft,
                      opacity: 0.2,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: OverflowBox(
                        maxHeight:
                            240.h, // Cho phép nội dung vượt ra khi co lại
                        alignment: Alignment.topCenter,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: HomeSearchBar(
                                    onTap: () {
                                      context.push('/search');
                                    },
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, authState) {
                                    if (authState.isAuthenticated) {
                                      // Show user icon when logged in
                                      return GestureDetector(
                                        onTap: () {
                                          context.go('/account-information');
                                        },
                                        child: Container(
                                          width: 44.w,
                                          height: 44.w,
                                          decoration: BoxDecoration(
                                            color: AppColors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Assets.svgs.iconUser.svg(
                                              width: 24.w,
                                              height: 24.h,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Show login button when not logged in
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 9,
                                        ),
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFEB5B00),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(40),
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            context.push('/login');
                                          },
                                          child: Text(
                                            'Đăng Nhập',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontFamily: 'Quicksand',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                SizedBox(width: 12.w),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Opacity(
                              opacity: 1 - progress,
                              child: Transform.translate(
                                offset: Offset(0, 20 * progress),
                                child: Text(
                                  'Mua ngay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          /// ===========================
          /// Floating Promotional Banner
          /// ===========================
          ValueListenableBuilder<double>(
            valueListenable: _scrollOffset,
            builder: (context, offset, _) {
              final double hideProgress = (offset / 100.h).clamp(0.0, 1.0);
              final double translateY = hideProgress * -40.h;
              final double opacity = 1.0 - hideProgress;

              return Positioned(
                left: 16.w,
                right: 16.w,
                top: maxHeaderHeight - 70.h + translateY,
                child: IgnorePointer(
                  ignoring: opacity < 0.1,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: 1 - hideProgress * 0.05,
                      child: const PromotionalBanner(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const HomeBottomNavigationBar(),
    );
  }
}
