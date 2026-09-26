import 'package:flutter/material.dart';

import '../../db/database_helper.dart';
import '../../models/study_record.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

/// 学习记录：时间线样式，按日期倒序
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<StudyRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await DatabaseHelper.instance.getRecords(UserProvider.instance.currentProfileId, limit: 200);
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌱', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('还没有学习记录，去闯关吧！',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // 按日期分组（倒序）
    final groups = <String, List<StudyRecord>>{};
    for (final r in _records) {
      groups.putIfAbsent(r.dayKey, () => []).add(r);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final items = groups[day]!;
          final dayScore = items.fold<int>(
              0, (sum, r) => sum + r.scoreChange);
          return _DayGroup(
            dayKey: day,
            records: items,
            dayScore: dayScore,
          );
        },
      ),
    );
  }
}

/// 单日分组（时间线）
class _DayGroup extends StatelessWidget {
  final String dayKey;
  final List<StudyRecord> records;
  final int dayScore;

  const _DayGroup({
    required this.dayKey,
    required this.records,
    required this.dayScore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Row(
            children: [
              Text(
                _fmtDay(dayKey),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              if (dayScore > 0)
                Text(
                  '当日 +$dayScore 积分',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.score,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 时间线
          Column(
            children: records.map((r) {
              final icon = switch (r.type) {
                'quiz' => (Icons.extension, AppColors.primary),
                'task' => (Icons.check_circle, AppColors.success),
                _ => (Icons.star, AppColors.score),
              };
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 竖线 + 节点
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: icon.$2,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Expanded(
                            child: VerticalDivider(
                              width: 2,
                              thickness: 1.5,
                              color: AppColors.lightDivider,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon.$1, size: 18, color: icon.$2),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (r.scoreChange > 0)
                                  Text(
                                    '+${r.scoreChange}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.score,
                                    ),
                                  ),
                              ],
                            ),
                            if (r.detail.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                r.detail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${r.createdAt.hour.toString().padLeft(2, '0')}:'
                              '${r.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.locked,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 展示日期：今天/昨天/具体日期
  String _fmtDay(String key) {
    final today = _dayKey(DateTime.now());
    if (key == today) return '今天';
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (key == yesterday) return '昨天';
    final parts = key.split('-');
    return '${parts[1]}月${parts[2]}日';
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
