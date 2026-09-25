import 'package:flutter/material.dart';

import '../models/garden_plot.dart';
import '../theme/app_theme.dart';

/// 花园地块卡（阳光花园 v1.1）
///
/// 已解锁：白底 + 植物 + 名称（可点击查看详情）；锁定：灰底 + 🔒 + 解锁按钮。
/// 按钮最小点击区域 48 高；积分不足时禁用并显示差额。
class PlotTile extends StatelessWidget {
  final GardenPlot plot;
  final int score; // 当前阳光积分
  final Future<void> Function(GardenPlot) onUnlock;
  final VoidCallback? onTap; // 已解锁地块点击（详情弹窗）

  const PlotTile({
    super.key,
    required this.plot,
    required this.score,
    required this.onUnlock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (plot.unlocked) {
      return _buildUnlocked();
    }
    return _buildLocked(context);
  }

  /// 已解锁地块：植物展示（可点击查看详情）
  Widget _buildUnlocked() {
    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(plot.icon, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 6),
          Text(
            plot.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const Text(
            '已解锁 · 点我查看',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    // 已解锁地块可点击查看详情
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }

  /// 锁定地块：🔒 + 解锁按钮
  Widget _buildLocked(BuildContext context) {
    final canUnlock = score >= plot.price;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.locked.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.locked.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text('🔒', style: TextStyle(fontSize: 34, color: AppColors.locked)),
          const SizedBox(height: 4),
          Text(
            plot.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            plot.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: canUnlock ? AppColors.primary : AppColors.locked,
                disabledBackgroundColor: AppColors.locked,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: canUnlock ? () => onUnlock(plot) : null,
              child: Text(
                canUnlock ? '${plot.price} 分解锁' : '还差 ${plot.price - score} 分',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
