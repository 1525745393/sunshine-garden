/// 花园地块（v1.1）
///
/// 阳光花园由若干地块组成：已解锁地块展示植物，锁定地块消费阳光积分解锁。
class GardenPlot {
  final String id;
  final String name;
  final String icon; // 植物 emoji
  final String description;
  final int price; // 解锁所需积分（0 = 默认解锁）
  bool unlocked;

  GardenPlot({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.price,
    this.unlocked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'price': price,
        'unlocked': unlocked ? 1 : 0,
      };

  factory GardenPlot.fromMap(Map<String, dynamic> map) => GardenPlot(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? '🌱',
        description: map['description'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        unlocked: (map['unlocked'] as num?)?.toInt() == 1,
      );
}
