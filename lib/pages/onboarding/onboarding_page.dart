import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

/// 首次引导：隐私告知（家长同意）→ 学段选择 → 年级选择 → 昵称
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  StudyStage? _stage;
  String? _grade;
  final _nicknameController = TextEditingController(text: '小太阳');

  /// 各学段可选年级
  static const _grades = {
    StudyStage.kindergarten: ['小班', '中班', '大班'],
    StudyStage.primary: ['一年级', '二年级', '三年级', '四年级', '五年级', '六年级'],
    StudyStage.middle: ['七年级', '八年级', '九年级'],
  };

  @override
  void initState() {
    super.initState();
    // 若隐私尚未同意，先弹隐私告知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!UserProvider.instance.privacyAccepted) {
        _showPrivacyDialog();
      }
    });
  }

  /// 隐私告知弹窗（家长同意，未同意退出应用）
  Future<void> _showPrivacyDialog() async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('致家长的一封信'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '「阳光花园・学习乐园」是一款儿童学习应用：\n\n'
                '· 所有数据仅保存在本机，不会上传任何个人信息；\n'
                '· 不收集设备 ID、手机号、位置、相册、通讯录；\n'
                '· 无广告、无外链、无社交功能；\n'
                '· 家长可在家长中心一键清除全部本地数据。',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('不同意并退出'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (agreed == true) {
      await UserProvider.instance.acceptPrivacy();
    } else {
      // 未同意直接退出
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primaryTranslucent,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    '阳光',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '阳光花园・学习乐园',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  '学习赚积分，积分种花园',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),

              // 学段选择
              const Text(
                '选择学段',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StageCard(
                    emoji: '🧸',
                    label: '幼儿园',
                    desc: '听音选图 · 10 分钟/天',
                    selected: _stage == StudyStage.kindergarten,
                    onTap: () => setState(() => _stage = StudyStage.kindergarten),
                  ),
                  const SizedBox(width: 10),
                  _StageCard(
                    emoji: '🎒',
                    label: '小学',
                    desc: '图文结合 · 20 分钟/天',
                    selected: _stage == StudyStage.primary,
                    onTap: () => setState(() => _stage = StudyStage.primary),
                  ),
                  const SizedBox(width: 10),
                  _StageCard(
                    emoji: '📚',
                    label: '初中',
                    desc: '文字为主 · 30 分钟/天',
                    selected: _stage == StudyStage.middle,
                    onTap: () => setState(() => _stage = StudyStage.middle),
                  ),
                ],
              ),

              // 年级选择
              if (_stage != null) ...[
                const SizedBox(height: 24),
                const Text(
                  '选择年级',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _grades[_stage]!.map((g) {
                    final selected = _grade == g;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _grade = g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.locked,
                          ),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // 昵称
              const SizedBox(height: 24),
              const Text(
                '宝宝昵称',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nicknameController,
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: '给孩子起个小名',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed:
                    _stage == null || _grade == null ? null : _start,
                child: const Text(
                  '开始学习啦',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final user = UserProvider.instance;
    await user.createProfile(
      nickname: _nicknameController.text.trim().isEmpty
          ? '小太阳'
          : _nicknameController.text.trim(),
      stage: _stage!,
      grade: _grade!,
    );
    if (!mounted) return;
    // 交给 main.dart 的监听跳转（UserProvider 通知后重建）
  }
}

/// 学段卡片
class _StageCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _StageCard({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.locked,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
