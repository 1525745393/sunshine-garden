import '../models/task.dart';

/// 默认每日任务模板（每天生成一组，跨日重置）
List<Task> defaultTasks() => [
      Task(id: 't_daily', title: '每日打卡：完成 10 分钟学习', icon: '🌞', score: 5),
      Task(id: 't_quiz', title: '完成 1 次知识闯关', icon: '⭐', score: 10),
      Task(id: 't_mistake', title: '重做 3 道错题', icon: '🔁', score: 6),
      Task(id: 't_read', title: '阅读 1 篇小短文', icon: '📖', score: 4),
      Task(id: 't_words', title: '复习今天学的生字', icon: '✏️', score: 3),
    ];
