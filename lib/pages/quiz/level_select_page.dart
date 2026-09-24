import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mistake.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/level_card.dart';
import '../../widgets/timer_bar.dart';
import 'quiz_page.dart';

/// 知识闯关 · 关卡选择页
class LevelSelectPage extends StatefulWidget {
  const LevelSelectPage({super.key});

  @override
  State<LevelSelectPage> createState() => _LevelSelectPageState();
}

class _LevelSelectPageState extends State<LevelSelectPage> {
  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final user = context.watch<UserProvider>();
    final timeUp = user.isTimeUp;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TimerBar(),
            const SizedBox(height: 14),
            if (timeUp)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.rewardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '今天的学习时间到啦，明天再来吧！\n错题复习和查看记录仍然开放哦～',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMain,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            // 学科/关卡列表
            ...quiz.levels.map(
              (level) => LevelCard(
                level: level,
                onTap: () {
                  if (timeUp) {
                    _showTimeUpSnack();
                    return;
                  }
                  quiz.startLevel(level);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPage(level: level),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // 错题本入口（超时不受限）
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MistakePage()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.replay_circle_filled,
                            color: AppColors.warning),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '错题本',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '复习错题不受每日时长限制',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeUpSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('今天的学习时间到啦，明天再来吧！')),
    );
  }
}

/// 错题本（v1.0：错题列表 + 重做）
class MistakePage extends StatefulWidget {
  const MistakePage({super.key});

  @override
  State<MistakePage> createState() => _MistakePageState();
}

class _MistakePageState extends State<MistakePage> {
  @override
  void initState() {
    super.initState();
    QuizProvider.instance.loadMistakes();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final list = quiz.mistakes;
    return Scaffold(
      appBar: AppBar(title: const Text('错题本')),
      body: list.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌈', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('太棒了，还没有错题！',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final m = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.questionText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMain,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '正确答案：${m.correctAnswer}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m.analysis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _redo(context, m),
                            child: const Text('我学会了，重做通过'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _redo(BuildContext context, Mistake m) async {
    final quiz = QuizProvider.instance;
    // 简化重做确认：家长/孩子确认已掌握后移出错题本
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('错题重做'),
        content: Text(
          '题目：${m.questionText}\n\n正确答案：${m.correctAnswer}\n\n确定已经掌握了吗？通过后 +2 积分并移出错题本。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('再看看'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('我学会了'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await quiz.resolveMistake(m);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 重做通过，+2 积分！')),
      );
    }
  }
}
