import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../../models/reward.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/reward_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badge_item.dart';

/// 我的奖励（v1.1）：淡黄奖励面板 + 勋章墙 + 兑换记录
class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  @override
  void initState() {
    super.initState();
    // 幂等加载：勋章（QuizProvider 托管）与兑换记录
    QuizProvider.instance.loadBadges().then((_) {
      if (mounted) setState(() {});
    });
    RewardProvider.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuizProvider, RewardProvider>(
      builder: (context, quiz, reward, _) {
        final badges = quiz.badges;
        final unlocked = quiz.unlockedBadgeCount;
        final redemptions = reward.redemptions;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 勋章墙（淡黄奖励面板）
              _buildBadgeWall(badges, unlocked),
              const SizedBox(height: 14),
              // 兑换记录
              _buildRedemptionList(redemptions),
            ],
          ),
        );
      },
    );
  }

  /// 勋章墙面板
  Widget _buildBadgeWall(List<Badge> badges, int unlocked) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.rewardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🏅 我的勋章',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              Text(
                '已解锁 $unlocked/${badges.length} 枚',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (badges.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '勋章正在路上，先闯关赢取吧！',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            // 勋章网格（手机 3 列 / 平板 5 列）
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 600 ? 5 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, i) => BadgeItem(
                    badge: badges[i],
                    onTap: () => _showBadgeDetail(context, badges[i]),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 勋章详情弹窗：名称 + 图标 + 解锁条件 + 当前状态
  void _showBadgeDetail(BuildContext context, Badge badge) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${badge.icon} ${badge.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.condition,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              badge.unlocked ? '🎉 已解锁，太棒了！' : '🔒 继续学习即可解锁',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: badge.unlocked ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  /// 兑换记录列表（按日期分组，时间线）
  Widget _buildRedemptionList(List<RedemptionRecord> redemptions) {
    // 按日期分组（倒序）
    final groups = <String, List<RedemptionRecord>>{};
    for (final r in redemptions) {
      final key = _dateKey(r.redeemedAt);
      groups.putIfAbsent(key, () => []).add(r);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎁 兑换记录',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          if (redemptions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '还没有兑换记录，去阳光商城看看吧！',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...days.map((day) {
              final items = groups[day]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fmtDateShort(day),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightDivider,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...items.map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(r.rewardIcon,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r.rewardName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMain,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '-${r.cost} 分',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // v1.3：审批状态徽标（大奖励）
                                _StatusChip(status: r.status),
                                Text(
                                  _fmtTime(r.redeemedAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// 日期 key：yyyy-MM-dd
  String _dateKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// 分组标题：今天 / 昨天 / M月d日
  String _fmtDateShort(String key) {
    final today = _dateKey(DateTime.now());
    if (key == today) return '今天';
    final yesterday = _dateKey(
        DateTime.now().subtract(const Duration(days: 1)));
    if (key == yesterday) return '昨天';
    final parts = key.split('-');
    return '${int.parse(parts[1])}月${int.parse(parts[2])}日';
  }

  /// 兑换时间展示：HH:mm
  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// 兑换状态徽标（v1.3 奖励审批）
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('待家长确认', AppColors.warning),
      'rejected' => ('未通过', AppColors.textSecondary),
      _ => ('已领取', AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
