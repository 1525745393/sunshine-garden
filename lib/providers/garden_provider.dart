import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../mock/garden.dart';
import '../models/garden_plot.dart';
import '../models/study_record.dart';
import 'user_provider.dart';

/// 阳光花园状态：地块网格 + 积分解锁（v1.1）
///
/// 解锁消费阳光积分（走 UserProvider.changeScore 统一收口），
/// 解锁状态持久化到 garden_plots 表，同时写一条学习记录。
class GardenProvider extends ChangeNotifier {
  GardenProvider._();
  static final GardenProvider instance = GardenProvider._();

  List<GardenPlot> _plots = [];
  bool _loaded = false;

  List<GardenPlot> get plots => _plots;
  bool get isLoaded => _loaded;

  /// 已解锁地块数
  int get unlockedCount => _plots.where((p) => p.unlocked).length;

  /// 加载地块：mock 定义 + 数据库解锁状态合并
  Future<void> load() async {
    final saved = await DatabaseHelper.instance.getGardenPlots();
    final savedById = {for (final p in saved) p.id: p};
    _plots = defaultPlots.map((p) {
      final s = savedById[p.id];
      if (s != null) p.unlocked = s.unlocked;
      return p;
    }).toList();
    // 首块默认解锁并落库（保证新装用户也有花园可看）
    if (_plots.isNotEmpty && !_plots.first.unlocked) {
      _plots.first.unlocked = true;
      await DatabaseHelper.instance.upsertGardenPlot(_plots.first);
    }
    _loaded = true;
    notifyListeners();
  }

  /// 解锁地块：积分足够则扣分并落库；返回 SnackBar 提示文案
  Future<String> unlock(GardenPlot plot) async {
    if (plot.unlocked) return '这块地已经解锁啦 🌻';
    final user = UserProvider.instance;
    if (user.totalScore < plot.price) {
      return '积分不够哦，还差 ${plot.price - user.totalScore} 分';
    }
    await user.changeScore(-plot.price);
    plot.unlocked = true;
    await DatabaseHelper.instance.upsertGardenPlot(plot);
    await DatabaseHelper.instance.insertRecord(StudyRecord(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      dayKey: _dayKey(),
      createdAt: DateTime.now(),
      type: 'reward',
      title: '解锁花园 · ${plot.name}',
      detail: '花费 ${plot.price} 阳光积分',
      scoreChange: -plot.price,
    ));
    notifyListeners();
    return '解锁成功！${plot.icon} ${plot.name} 加入花园啦';
  }

  static String _dayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
