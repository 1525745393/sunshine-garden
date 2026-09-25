import 'package:flutter/material.dart';

import '../models/reward.dart';
import '../theme/app_theme.dart';

/// 商城奖励商品卡（阳光商城 v1.1）
///
/// 展示商品图标、名称、奖励档次与所需积分；
/// 按钮三态：已兑换（禁用）/ 积分不足（禁用显示差额）/ 可兑换。
class RewardCard extends StatelessWidget {
  final RewardItem item;
  final int score; // 当前阳光积分
  final Future<String> Function(RewardItem) onRedeem;

  const RewardCard({
    super.key,
    required this.item,
    required this.score,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final tierStyle = _tierStyle(item.tier);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 商品图标
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.rewardBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(item.icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            // 名称 + 档次 + 价格
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tierStyle.$1.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tierStyle.$2,
                          style: TextStyle(
                            fontSize: 10,
                            color: tierStyle.$1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.score.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.price} 分',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A6B00),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 兑换按钮（48 高，保证最小点击区域）
            SizedBox(
              width: 84,
              height: 48,
              child: _buildActionButton(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 按钮三态
  Widget _buildActionButton(BuildContext context) {
    if (item.redeemed) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.success,
          side: const BorderSide(color: AppColors.success),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        onPressed: null,
        child: const Text(
          '已兑换',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }
    final canRedeem = score >= item.price;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: canRedeem ? AppColors.primary : AppColors.locked,
        disabledBackgroundColor: AppColors.locked,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: canRedeem ? () => onRedeem(item) : null,
      child: Text(
        canRedeem ? '兑换' : '还差 ${item.price - score} 分',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 奖励档次样式：(颜色, 标签)
  (Color, String) _tierStyle(String tier) => switch (tier) {
        'small' => (AppColors.success, '小奖励'),
        'medium' => (AppColors.primary, '中奖励'),
        _ => (AppColors.warning, '大奖励'),
      };
}
