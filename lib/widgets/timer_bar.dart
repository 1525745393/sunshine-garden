import 'package:flutter/material.dart';

import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

/// 今日学习时长条：显示已玩时长 / 剩余时间 / 超时状态
class TimerBar extends StatelessWidget {
  const TimerBar({super.key});

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = UserProvider.instance;
    final used = user.todayUsedSeconds;
    final limit = user.dailyLimitSeconds;
    final remaining = user.todayRemainingSeconds;
    final progress = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final timeUp = user.isTimeUp;

    return Card(
      color: AppColors.statusCard,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '今日学习时间',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  timeUp ? '已用完' : '剩余 ${_fmt(remaining)}',
                  style: TextStyle(
                    color: timeUp ? AppColors.warning : AppColors.score,
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
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                  timeUp ? AppColors.warning : AppColors.score,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '已学习 ${_fmt(used)} / ${_fmt(limit)}'
              '${timeUp ? ' · 新关卡已锁定，错题复习不受影响' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            // 番茄钟状态（v1.4）
            if (user.pomodoroEnabled && !timeUp) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: user.isPomodoroBreak
                      ? AppColors.warning.withValues(alpha: 0.18)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      user.isPomodoroBreak ? '☕ 休息时间' : '🍅 学习专注',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${user.isPomodoroBreak ? '还剩' : '本轮还剩'} '
                      '${_fmt(user.pomodoroRemainingSeconds)}',
                      style: TextStyle(
                        color: user.isPomodoroBreak
                            ? AppColors.warning
                            : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
