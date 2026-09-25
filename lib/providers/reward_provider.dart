import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../mock/rewards.dart';
import '../models/reward.dart';
import '../models/study_record.dart';
import 'user_provider.dart';

/// 阳光商城状态：奖励商品兑换 + 兑换记录（v1.1）
///
/// 兑换消费阳光积分（走 UserProvider.changeScore 统一收口），
/// 兑换状态写入 rewards 表、兑换记录写入 redemptions 表，
/// 同时写一条学习记录（学习记录页已支持 reward 类型渲染）。
class RewardProvider extends ChangeNotifier {
  RewardProvider._();
  static final RewardProvider instance = RewardProvider._();

  List<RewardItem> _items = [];
  List<RedemptionRecord> _redemptions = [];
  bool _loaded = false;

  List<RewardItem> get items => _items;
  List<RedemptionRecord> get redemptions => _redemptions;
  bool get isLoaded => _loaded;

  /// 已兑换商品数
  int get redeemedCount => _items.where((i) => i.redeemed).length;

  /// 加载商品（mock + 数据库兑换状态合并）与兑换记录
  Future<void> load() async {
    final savedItems = await DatabaseHelper.instance.getRewards();
    final savedById = {for (final i in savedItems) i.id: i};
    _items = defaultRewards.map((i) {
      final s = savedById[i.id];
      if (s != null) i.redeemed = s.redeemed;
      return i;
    }).toList();
    _redemptions = await DatabaseHelper.instance.getRedemptions();
    _loaded = true;
    notifyListeners();
  }

  /// 兑换商品：积分足够且未兑换则扣分并记录；返回 SnackBar 提示文案
  Future<String> redeem(RewardItem item) async {
    if (item.redeemed) return '这个奖励已经兑换过啦 🎁';
    final user = UserProvider.instance;
    if (user.totalScore < item.price) {
      return '积分不够哦，还差 ${item.price - user.totalScore} 分';
    }
    await user.changeScore(-item.price);
    item.redeemed = true;
    await DatabaseHelper.instance.upsertReward(item);

    final record = RedemptionRecord(
      id: 'rd_${DateTime.now().microsecondsSinceEpoch}',
      rewardName: item.name,
      rewardIcon: item.icon,
      cost: item.price,
      redeemedAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertRedemption(record);
    _redemptions.insert(0, record);

    await DatabaseHelper.instance.insertRecord(StudyRecord(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      dayKey: _dayKey(),
      createdAt: DateTime.now(),
      type: 'reward',
      title: '兑换奖励 · ${item.name}',
      detail: '花费 ${item.price} 阳光积分（${_tierLabel(item.tier)}）',
      scoreChange: -item.price,
    ));
    notifyListeners();
    return '兑换成功！${item.icon} ${item.name} 已加入奖励列表';
  }

  /// 奖励档次标签（用于商品卡角标与记录详情）
  static String _tierLabel(String tier) => switch (tier) {
        'small' => '小奖励',
        'medium' => '中奖励',
        _ => '大奖励',
      };
}
