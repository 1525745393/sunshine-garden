import 'package:flutter/material.dart';
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
                  itemBuilder: (context, i) => BadgeItem(badge: badges[i]),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 兑换记录列表
  Widget _buildRedemptionList(List<RedemptionRecord> redemptions) {
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
            ...redemptions.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(r.rewardIcon, style: const TextStyle(fontSize: 22)),
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
                        Text(
                          _fmtDate(r.redeemedAt),
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
  }

  /// 兑换时间展示：MM月DD日 HH:mm
  String _fmtDate(DateTime t) =>
      '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
