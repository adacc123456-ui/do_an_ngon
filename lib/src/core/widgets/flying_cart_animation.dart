import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';

class FlyingCartAnimation extends StatefulWidget {
  final Offset startPosition;
  final Offset? endPosition;
  final VoidCallback onComplete;

  const FlyingCartAnimation({
    super.key,
    required this.startPosition,
    this.endPosition,
    required this.onComplete,
  });

  @override
  State<FlyingCartAnimation> createState() => _FlyingCartAnimationState();
}

class _FlyingCartAnimationState extends State<FlyingCartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;
  Offset? _endPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Calculate end position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.endPosition != null) {
        _endPosition = widget.endPosition;
      } else {
        // Fallback: approximate cart icon position
        final screenSize = MediaQuery.of(context).size;
        _endPosition = Offset(
          screenSize.width - 60.w,
          100.h,
        );
      }

      _positionAnimation = Tween<Offset>(
        begin: widget.startPosition,
        end: _endPosition!,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubic,
        ),
      );

      setState(() {});
      _controller.forward().then((_) {
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_endPosition == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IgnorePointer(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  left: _positionAnimation.value.dx - 20.w,
                  top: _positionAnimation.value.dy - 20.w,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

