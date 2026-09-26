import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/database_helper.dart';
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
  int _todayEarned = 0; // 今日获得积分（任务 + 闯关 + 复习，v1.3 每日目标）

  @override
  void initState() {
    super.initState();
    _loadTodayEarned();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllDone();
    });
  }

  /// 统计今日正向积分（records 表 day_key 分组）
  Future<void> _loadTodayEarned() async {
    final today = _dayKey(DateTime.now());
    final records = await DatabaseHelper.instance.getRecords(UserProvider.instance.currentProfileId, );
    final sum = records
        .where((r) => r.dayKey == today && r.scoreChange > 0)
        .fold(0, (acc, r) => acc + r.scoreChange);
    if (!mounted) return;
    setState(() => _todayEarned = sum);
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
    final user = UserProvider.instance;
    final target = user.profile?.dailyTargetScore ?? 0;
    // 每日目标达成 OR 今日任务全部完成 → 今日成就卡（每日本页只弹一次）
    final targetHit = target > 0 && _todayEarned >= target;
    final allDone =
        task.totalCount > 0 && task.completedCount == task.totalCount;
    if (targetHit || allDone) {
      _celebratedToday = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(targetHit ? '🎉 今日成就达成！' : '🎉 今日成就达成！'),
            content: Text(
              targetHit
                  ? '今日积分达到 $_todayEarned 分，达成家长设定的目标！\n继续保持，坚持 7 天还能解锁「坚持之星」勋章哦～'
                  : '今天的任务全部完成，你是最棒的！\n明天继续加油，坚持 7 天还能解锁「坚持之星」勋章哦～',
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
                // 今日成就卡（家长设定每日目标后显示，v1.3）
                _buildDailyTargetCard(),
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

  /// 今日成就卡：家长每日目标进度 + 积分上限（v1.3 / v1.4）
  Widget _buildDailyTargetCard() {
    final user = UserProvider.instance;
    final target = user.profile?.dailyTargetScore ?? 0;
    final limit = user.profile?.dailyScoreLimit ?? 0;
    if (target <= 0 && limit <= 0) return const SizedBox.shrink();
    final hasTarget = target > 0;
    final hit = hasTarget && _todayEarned >= target;
    final ratio =
        (hasTarget ? (_todayEarned / target) : 0.0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hit ? AppColors.successBackground : AppColors.rewardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(hit ? '🌟' : '🏁',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                hasTarget ? '今日成就' : '今日积分',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              Text(
                hasTarget
                    ? (hit ? '已达成！' : '$_todayEarned / $target 分')
                    : '已获 $_todayEarned 分',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: hit ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.6),
                valueColor: AlwaysStoppedAnimation(
                    hit ? AppColors.success : AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            hit
                ? '今天的成就目标完成啦，去家长中心看看新奖励吧！'
                : (hasTarget
                    ? '完成任务与闯关，攒够 $target 分即可获得今日成就卡片'
                    : '今日已获得 $_todayEarned 分，继续加油！'),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (limit > 0) ...[
            const SizedBox(height: 6),
            Text(
              limit > 0 && _todayEarned >= limit
                  ? '📊 已达今日积分上限（$limit 分），明天再来赚积分吧'
                  : '📊 今日积分上限：$limit 分（已获 $_todayEarned 分）',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 日期 key：yyyy-MM-dd
  static String _dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

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
