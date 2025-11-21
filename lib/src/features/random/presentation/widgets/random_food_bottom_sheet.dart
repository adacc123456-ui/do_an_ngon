import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';
import 'package:do_an_ngon/src/core/widgets/svg_icon.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/random_food.dart';

class RandomFoodBottomSheet extends StatefulWidget {
  const RandomFoodBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFF9F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      constraints: BoxConstraints(maxHeight: 1.sh),
      builder: (context) {
        return SafeArea(child: const RandomFoodBottomSheet());
      },
    );
  }

  @override
  State<RandomFoodBottomSheet> createState() => _RandomFoodBottomSheetState();
}

class _RandomFoodBottomSheetState extends State<RandomFoodBottomSheet> {
  // Mock data - in real app, this would come from a use case
  final RandomFood _randomFood = const RandomFood(
    id: '1',
    name: 'Cá kho Vũ Đại',
    imageUrl: 'assets/images/food.jpg',
    description:
        'Cá kho Vũ Đại là một món ăn truyền thống của Việt Nam, có nguồn gốc từ vùng Vũ Đại, Hà Nam. Món ăn này được chế biến từ cá tươi (thường là cá trắm, cá chép hoặc cá quả), được ướp với các gia vị truyền thống như nước mắm, đường, tỏi, ớt, sau đó được kho trong nước dừa và nước mắm cho đến khi cá chín mềm, thấm đẫm gia vị. Món ăn có vị đậm đà, thơm ngon, thể hiện được tinh hoa ẩm thực Việt Nam.',
    restaurantName: 'Nhà hàng Vũ Đại',
    restaurantAddress: '1901 Thornridge Cir. Shiloh, Hawaii 81063',
    isFavorite: false,
  );

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = _randomFood.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      // decoration: BoxDecoration(
      //   color: AppColors.darkGrey,
      //   borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      // ),
      child: Column(
        children: [
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Food Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heart Icon
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isFavorite = !_isFavorite;
                                  });
                                },
                                child: SvgIcon(
                                  assetPath:
                                      _isFavorite
                                          ? 'assets/svgs/heart_filled.svg'
                                          : 'assets/svgs/heart.svg',
                                  width: 24,
                                  height: 24,
                                  color:
                                      _isFavorite
                                          ? AppColors.primary
                                          : AppColors.grey,
                                  fallbackIcon:
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Food Image
                        Center(
                          child: Container(
                            width: 200.w,
                            height: 200.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.lightGrey,
                              border: Border.all(
                                color: AppColors.white,
                                width: 4,
                              ),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              size: 80.sp,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Food Name
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            _randomFood.name,
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Description
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            _randomFood.description,
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 14.sp,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Address
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'Địa chỉ: ${_randomFood.restaurantAddress}',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Confirm Button
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'Xác nhận',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
