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

  /// 加载商品（mock + 数据库兑换状态合并 + 家长自定义奖励）与兑换记录
  Future<void> load() async {
    final savedItems = await DatabaseHelper.instance.getRewards();
    final savedById = {for (final i in savedItems) i.id: i};
    _items = defaultRewards.map((i) {
      final s = savedById[i.id];
      if (s != null) i.redeemed = s.redeemed;
      return i;
    }).toList();
    // v1.3：追加家长自定义奖励（不在 mock 列表中）
    for (final s in savedItems) {
      if (s.custom && !_items.any((i) => i.id == s.id)) {
        _items.add(s);
      }
    }
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

    // v1.3：大奖励需家长审批（pending），小/中奖励直接生效
    final isBig = item.tier == 'big';
    final status = isBig ? 'pending' : 'approved';
    final record = RedemptionRecord(
      id: 'rd_${DateTime.now().microsecondsSinceEpoch}',
      rewardName: item.name,
      rewardIcon: item.icon,
      cost: item.price,
      redeemedAt: DateTime.now(),
      status: status,
      tier: item.tier,
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
    return isBig
        ? '已提交兑换！${item.icon} 请家长确认后领取'
        : '兑换成功！${item.icon} ${item.name} 已加入奖励列表';
  }

  /// 待家长审批的兑换记录（v1.3 大奖励）
  List<RedemptionRecord> get pendingRedemptions =>
      _redemptions.where((r) => r.status == 'pending').toList();

  /// 家长批准奖励：记录状态置为 approved
  Future<void> approveRedemption(RedemptionRecord record) async {
    record.status = 'approved';
    await DatabaseHelper.instance.updateRedemptionStatus(record.id, 'approved');
    notifyListeners();
  }

  /// 家长拒绝奖励：退回积分，商品可重新兑换
  Future<void> rejectRedemption(RedemptionRecord record) async {
    record.status = 'rejected';
    await DatabaseHelper.instance.updateRedemptionStatus(record.id, 'rejected');
    // 退回积分（同一学习记录追加一条正向记录，便于追溯）
    await UserProvider.instance.changeScore(record.cost);
    RewardItem? item;
    for (final i in _items) {
      if (i.name == record.rewardName) {
        item = i;
        break;
      }
    }
    if (item != null) {
      item.redeemed = false;
      await DatabaseHelper.instance.upsertReward(item);
    }
    await DatabaseHelper.instance.insertRecord(StudyRecord(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      dayKey: _dayKey(),
      createdAt: DateTime.now(),
      type: 'reward',
      title: '奖励未通过 · ${record.rewardName}',
      detail: '家长未确认，退回 ${record.cost} 阳光积分',
      scoreChange: record.cost,
    ));
    notifyListeners();
  }

  /// 家长自定义奖励（v1.3）：写入 rewards 表并加入商城
  Future<void> addCustomReward({
    required String name,
    required String icon,
    required int price,
    required String tier,
  }) async {
    final item = RewardItem(
      id: 'cst_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      icon: icon.isEmpty ? '🎁' : icon,
      price: price,
      tier: tier,
      custom: true,
    );
    await DatabaseHelper.instance.upsertReward(item);
    _items.add(item);
    notifyListeners();
  }

  /// 奖励档次标签（用于商品卡角标与记录详情）
  static String _tierLabel(String tier) => switch (tier) {
        'small' => '小奖励',
        'medium' => '中奖励',
        _ => '大奖励',
      };

  /// 日期 key：yyyy-MM-dd（学习记录按天分组用）
  static String _dayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
