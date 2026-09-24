import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// 我的奖励（v1.2 完整实现，当前为占位壳）
class RewardPage extends StatelessWidget {
  const RewardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '我的奖励',
      icon: '🏅',
      message: '奖励面板正在整理中…\n勋章墙和兑换记录马上就会亮起来！',
    );
  }
}
