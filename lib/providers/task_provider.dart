import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../mock/tasks.dart';
import '../models/study_record.dart';
import '../models/task.dart';
import 'user_provider.dart';

/// 今日任务状态：按日期加载 / 勾选发积分 / 进度
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String _dayKey = '';
  bool _loaded = false;

  List<Task> get tasks => _tasks;
  bool get isLoaded => _loaded;

  int get completedCount => _tasks.where((t) => t.completed).length;
  int get totalCount => _tasks.length;
  double get progress =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  /// 今日已完成获得的积分合计
  int get earnedScore => _tasks
      .where((t) => t.completed)
      .fold(0, (sum, t) => sum + t.score);

  /// 加载今日任务（跨日则重建默认任务）
  Future<void> load() async {
    final dayKey = _todayKey();
    _dayKey = dayKey;
    var list = await DatabaseHelper.instance.getTasksForDay(dayKey);
    if (list.isEmpty) {
      list = defaultTasks();
      await DatabaseHelper.instance.replaceTasksForDay(dayKey, list);
    }
    _tasks = list;
    _loaded = true;
    notifyListeners();
  }

  /// 勾选/取消勾选任务：完成后发放积分并写入学习记录
  Future<void> toggleTask(Task task) async {
    final user = UserProvider.instance;
    if (!task.completed) {
      task.completed = true;
      await user.changeScore(task.score);
      await DatabaseHelper.instance.insertRecord(StudyRecord(
        id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
        dayKey: _dayKey,
        createdAt: DateTime.now(),
        type: 'task',
        title: task.title,
        detail: '完成今日任务，获得 +${task.score} 积分',
        scoreChange: task.score,
      ));
    } else {
      task.completed = false;
      await user.changeScore(-task.score);
    }
    await DatabaseHelper.instance.updateTask(task);
    notifyListeners();
  }

  /// 家长/系统重置任务（每日重建用）
  Future<void> resetToday() async {
    final dayKey = _todayKey();
    _dayKey = dayKey;
    _tasks = defaultTasks();
    await DatabaseHelper.instance.replaceTasksForDay(dayKey, _tasks);
    notifyListeners();
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
