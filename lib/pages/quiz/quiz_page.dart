import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/level.dart';
import '../../models/question.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import 'quiz_result_page.dart';

/// 答题页：进度条 + 即时反馈 + 解析 + 前台计时（WidgetsBindingObserver）
class QuizPage extends StatefulWidget {
  final Level level;

  const QuizPage({super.key, required this.level});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with WidgetsBindingObserver {
  // ---------- 前台计时 ----------
  Timer? _ticker;
  DateTime _foregroundStart = DateTime.now();
  int _elapsedBeforeBackground = 0;

  // ---------- 答题状态 ----------
  String? _selected; // 用户当前选择
  bool _answered = false;
  int _gainedThisQuestion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foregroundStart = DateTime.now();
    // 每秒刷新一次 UI（时长条）
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // 每日时长提醒（每天只弹一次）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = UserProvider.instance;
      if (await user.consumeTimeUpNotice()) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⏰ 学习时间到啦'),
            content: const Text('今天的学习时间到啦，明天再来吧！\n错题复习仍然开放哦～'),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('好的'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    // 退出时把前台活跃时长累计入账
    _flushForeground();
    super.dispose();
  }

  // ---------- 生命周期：后台暂停计时，前台恢复 ----------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flushForeground();
      _ticker?.cancel();
      _ticker = null;
    } else if (state == AppLifecycleState.resumed) {
      _foregroundStart = DateTime.now();
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// 累计前台活跃时长（秒）并写入持久化
  Future<void> _flushForeground() async {
    final elapsed =
        DateTime.now().difference(_foregroundStart).inSeconds;
    if (elapsed > 0) {
      await UserProvider.instance.addActiveSeconds(elapsed);
    }
    _foregroundStart = DateTime.now();
  }

  // ---------- 答题 ----------
  Question get _question => QuizProvider.instance.currentQuestion;

  Future<void> _submit(String answer) async {
    if (_answered) return;
    final quiz = QuizProvider.instance;
    _selected = answer;
    _answered = true;
    _gainedThisQuestion =
        await quiz.submitAnswer(answer); // 含连对奖励
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _next() async {
    final quiz = QuizProvider.instance;
    final hasNext = quiz.nextQuestion();
    if (hasNext) {
      setState(() {
        _selected = null;
        _answered = false;
        _gainedThisQuestion = 0;
      });
      return;
    }
    // 全部答完 → 结算
    await _flushForeground();
    final result = await quiz.finishLevel();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final session = quiz.session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('知识闯关')),
        body: const Center(child: Text('闯关已结束')),
      );
    }
    final q = _question;
    final total = session.questions.length;
    final current = session.currentIndex + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('退出', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 进度条 + 题号
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '第 $current / $total 题',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '连对奖励中…',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (current - 1) / total,
                      minHeight: 8,
                      backgroundColor: AppColors.trackBackground,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            // 题目区
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuestionText(q: q),
                    const SizedBox(height: 16),
                    _OptionsPanel(
                      q: q,
                      selected: _selected,
                      answered: _answered,
                      onSelect: _submit,
                    ),
                    if (_answered) ...[
                      const SizedBox(height: 12),
                      _FeedbackPanel(
                        q: q,
                        correct: _selected != null &&
                            _normalize(_selected!) == _normalize(q.answer),
                        gained: _gainedThisQuestion,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _next,
                        icon: Icon(
                          current >= total
                              ? Icons.emoji_events
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          current >= total ? '查看结算' : '下一题',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalize(String s) => s.trim().toLowerCase();
}

/// 题干文本（阅读理解含短文）
class _QuestionText extends StatelessWidget {
  final Question q;

  const _QuestionText({required this.q});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    q.type.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${q.subject} · ${q.unit}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              q.question,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMain,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 选项面板（选择/判断/填空/阅读统一选项按钮渲染）
class _OptionsPanel extends StatelessWidget {
  final Question q;
  final String? selected;
  final bool answered;
  final ValueChanged<String> onSelect;

  const _OptionsPanel({
    required this.q,
    required this.selected,
    required this.answered,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = q.options ?? const [];
    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt;
        final isCorrect = answered &&
            _normalize(opt) == _normalize(q.answer);
        final isWrongPick = answered && isSelected && !isCorrect;

        Color bg = Colors.white;
        Color border = AppColors.locked;
        if (answered) {
          if (isCorrect) {
            bg = AppColors.success.withOpacity(0.15);
            border = AppColors.success;
          } else if (isWrongPick) {
            bg = AppColors.warning.withOpacity(0.15);
            border = AppColors.warning;
          }
        } else if (isSelected) {
          bg = AppColors.primary.withOpacity(0.12);
          border = AppColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: answered ? null : () => onSelect(opt),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Row(
                  children: [
                    if (answered && isCorrect)
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20)
                    else if (answered && isWrongPick)
                      const Icon(Icons.cancel,
                          color: AppColors.warning, size: 20),
                    if (answered && (isCorrect || isWrongPick))
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _normalize(String s) => s.trim().toLowerCase();
}

/// 反馈面板：正确/错误 + 正确答案 + 解析
class _FeedbackPanel extends StatelessWidget {
  final Question q;
  final bool correct;
  final int gained;

  const _FeedbackPanel({
    required this.q,
    required this.correct,
    required this.gained,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? AppColors.rewardBackground : AppColors.feedbackErrorBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                correct ? '🎉 答对啦！' : '🤔 再想想～',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: correct ? AppColors.success : AppColors.warning,
                ),
              ),
              const Spacer(),
              if (gained > 0)
                Text(
                  '+$gained 积分',
                  style: const TextStyle(
                    color: AppColors.score,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 6),
            Text(
              '正确答案：${q.answer}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            q.analysis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
