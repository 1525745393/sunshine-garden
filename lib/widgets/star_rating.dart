import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 星级结算展示（点亮动画由调用页控制）
class StarRating extends StatelessWidget {
  final int stars;
  final double size;

  const StarRating({super.key, required this.stars, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final lit = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            lit ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: lit ? AppColors.score : AppColors.locked,
          ),
        );
      }),
    );
  }
}
