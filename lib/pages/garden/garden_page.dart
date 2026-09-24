import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

/// 阳光花园（v1.1 完整实现，当前为占位壳）
class GardenPage extends StatelessWidget {
  const GardenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '阳光花园',
      icon: '🌸',
      message: '花园正在施工中…\n攒够阳光积分，就能解锁漂亮的花园地块啦！',
    );
  }
}
