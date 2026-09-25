import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reward.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reward_card.dart';

/// 阳光商城（v1.1）：奖励商品卡片，积分足够扣分兑换，否则禁用。
/// v1.2 增强：奖励档次筛选（全部/小/中/大）。
class MallPage extends StatefulWidget {
  const MallPage({super.key});

  @override
  State<MallPage> createState() => _MallPageState();
}

class _MallPageState extends State<MallPage> {
  /// 当前档次筛选：all / small / medium / big
  String _tierFilter = 'all';

  @override
  void initState() {
    super.initState();
    // 幂等加载：商品 + 兑换记录
    RewardProvider.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RewardProvider, UserProvider>(
      builder: (context, reward, user, _) {
        if (!reward.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final score = user.totalScore;
        final items = reward.items;
        final filtered = _tierFilter == 'all'
            ? items
            : items.where((i) => i.tier == _tierFilter).toList();

        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + 2,
            itemBuilder: (context, i) {
              // 顶部标题卡
              if (i == 0) {
                return _buildHeader(score, reward.redeemedCount, items.length);
              }
              // 档次筛选条
              if (i == 1) {
                return _buildFilterBar();
              }
              final item = filtered[i - 2];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RewardCard(
                  item: item,
                  score: score,
                  onRedeem: (r) => _redeem(context, r),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 顶部标题卡：引导文案 + 积分
  Widget _buildHeader(int score, int redeemed, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.rewardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '阳光商城',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '已兑换 $redeemed/$total 件 · 攒积分换奖励',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '我的积分',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: AppColors.priceText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 档次筛选条
  Widget _buildFilterBar() {
    const options = [
      ('all', '全部'),
      ('small', '小奖励'),
      ('medium', '中奖励'),
      ('big', '大奖励'),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final (key, label) = opt;
          final selected = _tierFilter == key;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _tierFilter = key),
            selectedColor: AppColors.menuSelected,
            labelStyle: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 兑换商品：调用 Provider 扣分落库并反馈
  Future<String> _redeem(BuildContext context, RewardItem item) async {
    final msg = await RewardProvider.instance.redeem(item);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    return msg;
  }
}
