import 'package:flutter/material.dart' hide Badge;

import '../models/reward.dart';
import '../theme/app_theme.dart';

/// 勋章卡（我的奖励 v1.1）
///
/// 已解锁：淡紫底 + 彩色 emoji；未解锁：灰底 + 🔒 + 解锁条件说明。
/// v1.2 增强：点击可查看勋章详情。
class BadgeItem extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onTap;

  const BadgeItem({super.key, required this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    final content = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.locked.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? AppColors.primary.withOpacity(0.35)
              : AppColors.locked.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 勋章图标（未解锁置灰并盖锁）
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: Text(
                  badge.icon,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              if (!unlocked)
                const Positioned(
                  bottom: -2,
                  right: -4,
                  child: Text('🔒', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.textMain : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            unlocked ? '已解锁' : badge.condition,
            style: TextStyle(
              fontSize: 10,
              color: unlocked ? AppColors.success : AppColors.locked,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    // 点击查看详情
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
