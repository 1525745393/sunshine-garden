import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_item.dart';
import '../../widgets/timer_bar.dart';

/// 今日任务：勾选完成变绿发积分 + 进度条 + 今日成就
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  bool _celebratedToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllDone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 任务完成后弹出今日成就（每日本页只弹一次）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllDone();
    });
  }

  void _checkAllDone() {
    final task = TaskProvider.instance;
    if (!task.isLoaded) return;
    if (_celebratedToday) return;
    if (task.totalCount > 0 && task.completedCount == task.totalCount) {
      _celebratedToday = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🎉 今日成就达成！'),
            content: const Text(
              '今天的任务全部完成，你是最棒的！\n明天继续加油，坚持 7 天还能解锁「坚持之星」勋章哦～',
              textAlign: TextAlign.center,
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('太棒了'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TaskProvider>(
        builder: (context, task, _) {
          if (!task.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 时长卡（今日学习时间）
                const TimerBar(),
                const SizedBox(height: 14),
                // 进度卡
                _buildProgressCard(task),
                const SizedBox(height: 14),
                // 任务列表
                ...task.tasks.map(
                  (t) => TaskItem(
                    task: t,
                    onToggle: () async {
                      await context.read<TaskProvider>().toggleTask(t);
                      final score = t.completed ? t.score : 0;
                      if (!mounted) return;
                      if (score > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ 完成任务，+$score 阳光积分！'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                      _checkAllDone();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 总积分 + 完成进度条
  Widget _buildProgressCard(TaskProvider task) {
    final user = UserProvider.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '今日任务进度',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              Text(
                '总积分 ${user.totalScore}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: task.progress,
              minHeight: 10,
              backgroundColor: AppColors.trackBackground,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成 ${task.completedCount}/${task.totalCount} 项 · 今日已得 +${task.earnedScore} 积分',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
