/// 勋章
class Badge {
  final String id;
  final String name;
  final String icon; // emoji
  final String condition; // 解锁条件说明
  bool unlocked;

  Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.condition,
    this.unlocked = false,
  });
}

/// 商城奖励商品
class RewardItem {
  final String id;
  final String name;
  final String icon; // emoji
  final int price; // 所需积分
  final String tier; // small / medium / big
  bool redeemed;
  bool custom; // 家长自定义奖励（v1.3）

  RewardItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.tier,
    this.redeemed = false,
    this.custom = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'price': price,
        'tier': tier,
        'redeemed': redeemed ? 1 : 0,
        'custom': custom ? 1 : 0,
      };

  factory RewardItem.fromMap(Map<String, dynamic> map) => RewardItem(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? '🎁',
        price: (map['price'] as num?)?.toInt() ?? 0,
        tier: map['tier'] as String? ?? 'small',
        redeemed: (map['redeemed'] as num?)?.toInt() == 1,
        custom: (map['custom'] as num?)?.toInt() == 1,
      );
}

/// 兑换记录
class RedemptionRecord {
  final String id;
  final String rewardName;
  final String rewardIcon;
  final int cost;
  final DateTime redeemedAt;
  String status; // pending（待家长审批）/ approved / rejected
  final String tier;

  RedemptionRecord({
    required this.id,
    required this.rewardName,
    required this.rewardIcon,
    required this.cost,
    required this.redeemedAt,
    this.status = 'approved',
    this.tier = 'small',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'reward_name': rewardName,
        'reward_icon': rewardIcon,
        'cost': cost,
        'redeemed_at': redeemedAt.toIso8601String(),
        'status': status,
        'tier': tier,
      };

  factory RedemptionRecord.fromMap(Map<String, dynamic> map) =>
      RedemptionRecord(
        id: map['id'] as String,
        rewardName: map['reward_name'] as String,
        rewardIcon: map['reward_icon'] as String? ?? '🎁',
        cost: (map['cost'] as num?)?.toInt() ?? 0,
        redeemedAt: DateTime.parse(map['redeemed_at'] as String),
        status: map['status'] as String? ?? 'approved',
        tier: map['tier'] as String? ?? 'small',
      );
}
