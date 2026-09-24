import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// 阳光商城（v1.2 完整实现，当前为占位壳）
class MallPage extends StatelessWidget {
  const MallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '阳光商城',
      icon: '🎁',
      message: '商城正在筹备中…\n用阳光积分兑换心仪的贴纸、装饰和奖励！',
    );
  }
}
