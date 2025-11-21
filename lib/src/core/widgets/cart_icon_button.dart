import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_state.dart';

class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final itemCount = state.totalItems;
        return GestureDetector(
          onTap: () {
            context.go('/cart');
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
                  child: SvgIcon(
                    assetPath: 'assets/svgs/cart.svg',
                    width: 24,
                    height: 24,
                    color: AppColors.white,
                    fallbackIcon: Icons.shopping_cart_outlined,
                  ),
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 20.w,
                      minHeight: 20.w,
                    ),
                    child: Center(
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

