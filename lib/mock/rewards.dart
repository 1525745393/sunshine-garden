import '../models/reward.dart';

/// 默认商城奖励商品（分三档：小/中/大奖励）
/// 注意：兑换状态在运行时可被修改，故不用 const 列表。
final defaultRewards = <RewardItem>[
  RewardItem(id: 'r_sticker', name: '太阳花贴纸包', icon: '🌻', price: 30, tier: 'small'),
  RewardItem(id: 'r_pencil', name: '彩色铅笔一盒', icon: '🖍️', price: 50, tier: 'small'),
  RewardItem(id: 'r_bunny', name: '花园小兔子装饰', icon: '🐰', price: 120, tier: 'medium'),
  RewardItem(id: 'r_fountain', name: '花园小喷泉', icon: '⛲', price: 200, tier: 'medium'),
  RewardItem(id: 'r_book', name: '选一本新绘本（家长兑现）', icon: '📚', price: 300, tier: 'big'),
  RewardItem(id: 'r_park', name: '周末公园之旅（家长兑现）', icon: '🎡', price: 500, tier: 'big'),
];
