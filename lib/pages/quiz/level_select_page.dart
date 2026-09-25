import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mistake.dart';
import '../../models/question.dart';
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
    // 超时 或 超出允许时间段 → 锁定新关卡（错题复习不受限）
    final blocked = user.isTimeUp || user.isOutsideAllowedWindow;
    final timeUp = user.isTimeUp;

    // v1.3 内容过滤：家长开启后仅显示当前学段关卡
    final profile = user.profile;
    final levels = (profile?.filterCurrentStage ?? false) && profile != null
        ? quiz.levels
            .where((l) => l.stage == profile.stage.name)
            .toList()
        : quiz.levels;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TimerBar(),
            const SizedBox(height: 14),
            if (blocked)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.rewardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.isOutsideAllowedWindow
                            ? '现在不是学习时间哦，家长设置了时间段限制！\n错题复习和查看记录仍然开放～'
                            : '今天的学习时间到啦，明天再来吧！\n错题复习和查看记录仍然开放哦～',
                        style: const TextStyle(
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
            ...levels.map(
              (level) => LevelCard(
                level: level,
                onTap: () {
                  if (blocked) {
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
    // 遗忘曲线排序：到期（待复习）优先，其余按复习时间升序
    final list = List<Mistake>.of(quiz.mistakes)
      ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
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
              itemBuilder: (context, i) => _buildCard(context, list[i]),
            ),
    );
  }

  /// 错题卡片：题目 + 到期状态 + 重做入口
  Widget _buildCard(BuildContext context, Mistake m) {
    final quiz = QuizProvider.instance;
    final q = quiz.findQuestion(m.id); // 反查原题（含选项）
    final now = DateTime.now();
    final dueNow = m.nextReviewAt.isBefore(now);
    final daysLeft =
        m.nextReviewAt.difference(now).inDays + 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.questionText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMain,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // 到期状态徽标（橙色=待复习 / 灰=未到期）
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dueNow
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dueNow ? '待复习' : '$daysLeft 天后',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dueNow
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (q != null && (q.options?.isNotEmpty ?? false))
              Text(
                '题型：${q.type.label}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
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
                child: Text(dueNow ? '重做' : '提前复习'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 重做入口：选择题走选项作答，其余走填空作答
  Future<void> _redo(BuildContext context, Mistake m) async {
    final quiz = QuizProvider.instance;
    final q = quiz.findQuestion(m.id);
    if (q != null && (q.options?.isNotEmpty ?? false)) {
      await _showChoiceRedo(context, m, q);
    } else {
      await _showTextRedo(context, m);
    }
  }

  /// 选择题重做：显示题目 + 选项（点击选项即作答）
  Future<void> _showChoiceRedo(
      BuildContext context, Mistake m, Question q) async {
    final options = q.options ?? const <String>[];
    final answer = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('错题重做'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.question,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMain,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () => Navigator.pop(ctx, options[i]),
                    child: Text(
                      '${String.fromCharCode(65 + i)}. ${options[i]}',
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (answer == null || !mounted) return;
    await _judge(context, m, answer);
  }

  /// 填空/其他题型重做：输入答案作答
  Future<void> _showTextRedo(BuildContext context, Mistake m) async {
    final ctrl = TextEditingController();
    final answer = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('错题重做'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.questionText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMain,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '输入你的答案',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('提交'),
          ),
        ],
      ),
    );
    if (answer == null || answer.isEmpty || !mounted) return;
    await _judge(context, m, answer);
  }

  /// 判定：答对 → +2 积分移出错题本；答错 → 顺延到明天复习
  Future<void> _judge(
      BuildContext context, Mistake m, String answer) async {
    final quiz = QuizProvider.instance;
    final correct = _norm(m.correctAnswer) == _norm(answer);
    if (correct) {
      await quiz.resolveMistake(m);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ 答对啦！+2 积分，错题移出。'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      await quiz.postponeMistake(m);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🤔 还差一点点，正确答案：${m.correctAnswer}。明天再来复习这道题'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 答案归一化：去首尾空格、去空格、转小写
  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(' ', '');
}
