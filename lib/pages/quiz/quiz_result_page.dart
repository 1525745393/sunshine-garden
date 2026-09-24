import 'package:flutter/material.dart';

import '../../providers/quiz_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/star_rating.dart';
import 'quiz_page.dart';

/// 闯关结算页：星级 + 积分明细 + 解锁提示 + 重玩
class QuizResultPage extends StatefulWidget {
  final QuizResult result;

  const QuizResultPage({super.key, required this.result});

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('闯关结算'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // 星星（动画点亮）
              const SizedBox(height: 12),
              Center(
                child: _AnimatedStars(stars: r.stars),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${r.level.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '答对 ${r.correct}/${r.total} 题',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 积分明细卡
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ScoreRow(
                        label: '满星通关奖励',
                        value: r.stars == 3 ? '+5' : '-',
                      ),
                      const Divider(height: 20),
                      _ScoreRow(
                        label: '努力值（认真完成）',
                        value: '+2',
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '本次共获得',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                          Text(
                            '+${r.bonusScore} 阳光积分',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.score,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 解锁提示
              if (r.stars >= 1)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.rewardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🎉 通关成功，下一关已解锁！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        // 重玩：回到答题页
                        final quiz = QuizProvider.instance;
                        quiz.startLevel(widget.result.level);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                QuizPage(level: widget.result.level),
                          ),
                        );
                      },
                      child: const Text(
                        '再玩一次',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '完成',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 星星点亮动画（逐颗放大出现）
class _AnimatedStars extends StatefulWidget {
  final int stars;

  const _AnimatedStars({required this.stars});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars> {
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    // 依次点亮星星
    Future<void> show() async {
      for (var i = 0; i < widget.stars; i++) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) setState(() => _shown = i + 1);
      }
    }

    show();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final lit = i < _shown;
        return AnimatedScale(
          scale: lit ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              lit ? Icons.star_rounded : Icons.star_border_rounded,
              size: 52,
              color: lit ? AppColors.score : AppColors.locked,
            ),
          ),
        );
      }),
    );
  }
}

/// 明细行
class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
