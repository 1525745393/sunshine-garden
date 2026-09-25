import '../models/garden_plot.dart';

/// 默认花园地块（mock 数据，与业务代码解耦）
///
/// 首块默认解锁，其余按解锁积分递增；价格区间覆盖小/中/大三档奖励，
/// 与商城商品价格带开错开，避免孩子"只种花不兑换"。
/// 注意：地块解锁状态在运行时可被修改，故不用 const 列表。
final defaultPlots = <GardenPlot>[
  GardenPlot(
    id: 'g1',
    name: '向日葵田',
    icon: '🌻',
    description: '阳光最充足的一角',
    price: 0,
    unlocked: true,
  ),
  GardenPlot(
    id: 'g2',
    name: '草莓园',
    icon: '🍓',
    description: '甜甜的草莓快成熟啦',
    price: 40,
  ),
  GardenPlot(
    id: 'g3',
    name: '萝卜菜地',
    icon: '🥕',
    description: '拔萝卜要用力呀',
    price: 80,
  ),
  GardenPlot(
    id: 'g4',
    name: '小池塘',
    icon: '🐟',
    description: '池塘里住着小金鱼',
    price: 140,
  ),
  GardenPlot(
    id: 'g5',
    name: '蘑菇屋',
    icon: '🍄',
    description: '小蘑菇撑开小伞',
    price: 200,
  ),
  GardenPlot(
    id: 'g6',
    name: '彩虹花坛',
    icon: '🌈',
    description: '七种颜色的小花',
    price: 280,
  ),
  GardenPlot(
    id: 'g7',
    name: '蝴蝶花园',
    icon: '🦋',
    description: '蝴蝶在花间飞舞',
    price: 380,
  ),
  GardenPlot(
    id: 'g8',
    name: '阳光大树',
    icon: '🌳',
    description: '大树底下好乘凉',
    price: 500,
  ),
];
