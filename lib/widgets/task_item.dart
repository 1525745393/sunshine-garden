import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// 今日任务条目：勾选后变绿并显示已得积分
class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskItem({super.key, required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final done = task.completed;
    return Card(
      color: done ? AppColors.success.withOpacity(0.12) : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 勾选状态
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: done ? AppColors.success : AppColors.locked,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(task.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: done ? AppColors.success : AppColors.textMain,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 积分
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: done ? AppColors.score : AppColors.rewardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  done ? '+${task.score} ✓' : '+${task.score}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
