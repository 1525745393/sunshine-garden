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
                      backgroundColor: const Color(0xFFE4E8F5),
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
                    if (_answered) ...[...],
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
