import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/garden_plot.dart';
import '../../providers/garden_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/plot_tile.dart';

/// 阳光花园（v1.1）：地块网格，已解锁显示植物，锁定地块用积分解锁。
/// v1.2 增强：解锁二次确认（防误触扣分）+ 植物详情弹窗 + 满园彩蛋。
class GardenPage extends StatefulWidget {
  const GardenPage({super.key});

  @override
  State<GardenPage> createState() => _GardenPageState();
}

class _GardenPageState extends State<GardenPage> {
  @override
  void initState() {
    super.initState();
    // 幂等加载：地块定义 + 解锁状态
    GardenProvider.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GardenProvider, UserProvider>(
      builder: (context, garden, user, _) {
        if (!garden.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final score = user.totalScore;
        final total = garden.plots.length;
        final unlocked = garden.unlockedCount;
        final isFull = unlocked == total && total > 0;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 花园概况卡（深蓝）
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(isFull ? '🎉' : '🌻',
                        style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFull ? '花园满园啦！' : '我的小花园',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFull
                                ? '全部 $total 块地都已解锁 🌈'
                                : '已解锁 $unlocked/$total 块地',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '阳光积分',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: AppColors.score,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // 地块网格（手机 2 列 / 平板 4 列）
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 600 ? 4 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: garden.plots.length,
                    itemBuilder: (context, i) {
                      final plot = garden.plots[i];
                      return PlotTile(
                        plot: plot,
                        score: score,
                        onUnlock: (p) => _confirmUnlock(context, p),
                        onTap: plot.unlocked ? () => _showPlotDetail(context, plot) : null,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 解锁二次确认：防止孩子误触扣分
  Future<void> _confirmUnlock(BuildContext context, GardenPlot plot) async {
    final user = UserProvider.instance;
    if (user.totalScore < plot.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('积分不够哦，还差 ${plot.price - user.totalScore} 分')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('解锁 ${plot.name}？'),
        content: Text('将花费 ${plot.price} 阳光积分解锁「${plot.icon} ${plot.name}」\n${plot.description}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定解锁'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _unlock(context, plot);
  }

  /// 植物详情弹窗（已解锁地块点击查看）
  void _showPlotDetail(BuildContext context, GardenPlot plot) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${plot.icon} ${plot.name}'),
        content: Text(
          '${plot.description}\n\n已解锁地块，每天都会在这里陪伴你学习～',
          style: const TextStyle(height: 1.5),
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

  /// 解锁地块：调用 Provider 扣分落库并反馈
  Future<String> _unlock(BuildContext context, GardenPlot plot) async {
    final msg = await GardenProvider.instance.unlock(plot);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    return msg;
  }
}
