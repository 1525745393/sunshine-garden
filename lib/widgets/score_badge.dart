import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// AppBar 右侧阳光积分胶囊
class ScoreBadge extends StatelessWidget {
  final int score;
  final VoidCallback? onTap;

  const ScoreBadge({super.key, required this.score, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32, minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.score,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
