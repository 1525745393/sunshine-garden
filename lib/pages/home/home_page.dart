import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/quiz_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

/// 学习总览（首页）：Hero 卡 + 统计卡 + 任务摘要 + 快捷入口
class HomePage extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = UserProvider.instance;
    final tasks = TaskProvider.instance;
    final quiz = QuizProvider.instance;
    // 并行初始化今日任务 / 关卡 / 勋章
    await Future.wait([
      tasks.load(),
      quiz.loadLevels(),
      quiz.loadBadges(),
    ]);
    await quiz.refreshBadges();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TaskProvider>(
        builder: (context, task, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 14),
                _buildStatRow(),
                const SizedBox(height: 14),
                _buildTaskSummary(task),
                const SizedBox(height: 14),
                _buildQuickEntries(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 深蓝 Hero 卡：积分进度环 + 累计积分 + 连续打卡
  Widget _buildHeroCard() {
    return Consumer2<UserProvider, TaskProvider>(
      builder: (context, user, task, _) {
        final progress = task.progress;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.statusCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // 进度环
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.score),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日任务进度',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.totalScore}',
                      style: const TextStyle(
                        color: AppColors.score,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '阳光积分',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '连续打卡 ${user.profile?.continuousDays ?? 0} 天',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 统计卡片区
  Widget _buildStatRow() {
    return Consumer2<TaskProvider, QuizProvider>(
      builder: (context, task, quiz, _) {
        return Row(
          children: [
            _StatCard(
              icon: Icons.task_alt,
              label: '任务完成',
              value: '${task.completedCount}/${task.totalCount}',
              color: AppColors.success,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.timer_outlined,
              label: '今日已学',
              value:
                  '${(UserProvider.instance.todayUsedSeconds / 60).floor()} 分钟',
              color: AppColors.warning,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.military_tech_outlined,
              label: '勋章',
              value: '${quiz.unlockedBadgeCount} 枚',
              color: AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  /// 今日任务摘要（前 3 条待办）
  Widget _buildTaskSummary(TaskProvider task) {
    final todos = task.tasks.where((t) => !t.completed).take(3).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日任务',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(1),
                child: const Text('全部 ›'),
              ),
            ],
          ),
          if (todos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '🎉 今天的任务都完成啦，真棒！',
                style: TextStyle(color: AppColors.success),
              ),
            )
          else
            ...todos.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(t.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.title,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '+${t.score}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 快捷入口：闯关主按钮 + 花园/勋章预览
  Widget _buildQuickEntries() {
    return Consumer2<UserProvider, QuizProvider>(
      builder: (context, user, quiz, _) {
        final timeUp = user.isTimeUp;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 今日知识闯关主入口
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: timeUp
                  ? null
                  : () => widget.onNavigate(2),
              icon: Icon(timeUp ? Icons.lock_clock : Icons.play_circle_fill),
              label: Text(
                timeUp ? '今日时间到啦，明天再来！' : '今日知识闯关',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PreviewCard(
                    icon: '🌸',
                    title: '阳光花园',
                    subtitle: '攒积分解锁地块',
                    onTap: () => widget.onNavigate(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PreviewCard(
                    icon: '🏅',
                    title: '勋章墙',
                    subtitle: '已解锁 ${quiz.unlockedBadgeCount} 枚',
                    onTap: () => widget.onNavigate(5),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 统计小卡
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 快捷预览卡
class _PreviewCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
