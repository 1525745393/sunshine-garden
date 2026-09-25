import '../models/reward.dart';

/// 内置勋章墙（按学习进度自动解锁）
/// 注意：勋章解锁状态在运行时可被修改，故不用 const 列表。
final defaultBadges = <Badge>[
  Badge(id: 'b_pinyin', name: '拼音小达人', icon: '🔤', condition: '完成幼儿园拼音关卡'),
  Badge(id: 'b_words', name: '字词小达人', icon: '📝', condition: '字词关卡获得 2 星'),
  Badge(id: 'b_poet', name: '古诗小诗人', icon: '🏮', condition: '古诗关卡获得 2 星'),
  Badge(id: 'b_reader', name: '阅读之星', icon: '📖', condition: '完成阅读关卡'),
  Badge(id: 'b_champion', name: '闯关王', icon: '🏆', condition: '累计完成 10 次闯关'),
  Badge(id: 'b_persist', name: '坚持之星', icon: '🌟', condition: '连续 7 天每天学习 10 分钟'),
  Badge(id: 'b_middle', name: '初中预备役', icon: '🎓', condition: '小学全部关卡获得 3 星'),
];
