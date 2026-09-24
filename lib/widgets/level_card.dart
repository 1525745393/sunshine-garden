import 'package:flutter/material.dart';

import '../models/level.dart';
import '../theme/app_theme.dart';

/// 关卡卡片：星级 / 解锁状态 / 学科单元
class LevelCard extends StatelessWidget {
  final Level level;
  final VoidCallback onTap;

  const LevelCard({
    super.key,
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !level.unlocked;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: locked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 关卡序号 / 锁
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: locked
                      ? AppColors.locked
                      : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: locked
                    ? const Icon(Icons.lock, color: Colors.white)
                    : Text(
                        level.name.characters.first,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.subject} · ${level.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StarDisplay(starCount: level.starCount, locked: locked),
            ],
          ),
        ),
      ),
    );
  }
}

/// 星级展示（3 颗星，点亮/置灰）
class _StarDisplay extends StatelessWidget {
  final int starCount;
  final bool locked;

  const _StarDisplay({required this.starCount, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final lit = !locked && i < starCount;
        return Icon(
          lit ? Icons.star : Icons.star_border,
          size: 20,
          color: lit ? AppColors.score : AppColors.locked,
        );
      }),
    );
  }
}
