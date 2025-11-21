import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:do_an_ngon/src/core/constants/app_colors.dart';

class RatingWidget extends StatelessWidget {
  final double? rating;
  final int? totalReviews;
  final double starSize;
  final double fontSize;
  final bool showReviewsCount;
  final Color? starColor;
  final Color? textColor;

  const RatingWidget({
    super.key,
    this.rating,
    this.totalReviews,
    this.starSize = 14,
    this.fontSize = 12,
    this.showReviewsCount = true,
    this.starColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final averageRating = rating ?? 0.0;
    final hasRating = averageRating > 0;
    final reviews = totalReviews ?? 0;

    if (!hasRating && reviews == 0) {
      return Text(
            'Chưa có đánh giá',
            style: TextStyle(
              fontSize: fontSize.sp,
              color: textColor ?? AppColors.textGrey,
            ),
          );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        ...List.generate(5, (index) {
          final starValue = index + 1;
          final isFilled = starValue <= averageRating.round();
          final isHalf = starValue - 0.5 <= averageRating && averageRating < starValue;

          return Icon(
            isFilled
                ? Icons.star
                : isHalf
                    ? Icons.star_half
                    : Icons.star_border,
            size: starSize.sp,
            color: isFilled || isHalf
                ? (starColor ?? Colors.amber)
                : AppColors.lightGrey,
          );
        }),
        SizedBox(width: 6.w),
        // Rating number
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppColors.black,
          ),
        ),
        // Reviews count
        if (showReviewsCount && reviews > 0) ...[
          SizedBox(width: 4.w),
          Text(
            '($reviews)',
            style: TextStyle(
              fontSize: (fontSize - 1).sp,
              color: textColor ?? AppColors.textGrey,
            ),
          ),
        ],
      ],
    );
  }
}

