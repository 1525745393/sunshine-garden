/// 今日任务
class Task {
  final String id;
  final String title;
  final String icon; // emoji
  final int score; // 完成奖励积分
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.icon,
    required this.score,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon,
        'score': score,
        'completed': completed ? 1 : 0,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        icon: map['icon'] as String? ?? '📌',
        score: (map['score'] as num?)?.toInt() ?? 0,
        completed: (map['completed'] as num?)?.toInt() == 1,
      );
}
