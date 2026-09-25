import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/database_helper.dart';
import '../../models/user_profile.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

/// 家长中心：算术验证 → 报告 / 档案 / 审批 / 时长 / 偏好 / 一键清除
class ParentCenterPage extends StatefulWidget {
  const ParentCenterPage({super.key});

  @override
  State<ParentCenterPage> createState() => _ParentCenterPageState();
}

class _ParentCenterPageState extends State<ParentCenterPage> {
  bool _verified = false;
  int? _mistakeCount;
  String _report = '';

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final mistakes =
        await DatabaseHelper.instance.getMistakes(resolved: false);
    final records = await DatabaseHelper.instance.getRecords(limit: 100);
    if (!mounted) return;
    final total = records.length;
    final quiz = records.where((r) => r.type == 'quiz').length;
    setState(() {
      _mistakeCount = mistakes.length;
      _report = '共 $total 条学习记录 · 闯关 $quiz 次 · 待复习错题 ${mistakes.length} 道';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _verified ? _buildSettings(context) : _VerifyGate(onVerified: () {
        setState(() => _verified = true);
        _loadReportData();
      }),
    );
  }

  /// 验证通过后的设置面板
  Widget _buildSettings(BuildContext context) {
    final user = context.watch<UserProvider>();
    final profile = user.profile!;
    final quiz = context.watch<QuizProvider>();
    final reward = context.watch<RewardProvider>();
    final pending = reward.pendingRedemptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 学习报告
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '学习报告',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今日已学 ${(user.todayUsedSeconds / 60).floor()} 分钟 / '
                  '目标 ${profile.dailyMinutes} 分钟',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '总积分 ${user.totalScore} · 连续打卡 ${profile.continuousDays} 天',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _report,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 奖励审批（v1.3 大奖励需家长确认）
          _SectionCard(
            title: '奖励审批（${pending.length}）',
            child: pending.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '暂无待审批的奖励',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Column(
                    children: pending.map((r) {
                      return ListTile(
                        leading: Text(r.rewardIcon,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(
                          r.rewardName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${r.cost} 阳光积分 · ${_tierLabel(r.tier)} · '
                          '${r.redeemedAt.month}月${r.redeemedAt.day}日',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: AppColors.success),
                              tooltip: '批准',
                              onPressed: () async {
                                await reward.approveRedemption(r);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('已批准：${r.rewardName}')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel,
                                  color: AppColors.warning),
                              tooltip: '拒绝并退回积分',
                              onPressed: () async {
                                await reward.rejectRedemption(r);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '已拒绝：退回 ${r.cost} 阳光积分')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),

          // 孩子档案
          _SectionCard(
            title: '孩子档案',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.child_care,
                      color: AppColors.primary),
                  title: const Text('昵称'),
                  trailing: Text(
                    profile.nickname,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.school, color: AppColors.primary),
                  title: const Text('学段 · 年级'),
                  trailing: Text(
                    '${profile.stage.label} · ${profile.grade}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('修改学段 / 年级'),
                  subtitle: const Text('修改后题库与默认时长自动切换'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showStageGradeDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag_outlined,
                      color: AppColors.primary),
                  title: const Text('每日目标积分'),
                  subtitle: Text(profile.dailyTargetScore == 0
                      ? '未设置（点击设置今日成就目标）'
                      : '今日达成 ${profile.dailyTargetScore} 分获得成就卡片'),
                  trailing: Text(
                    profile.dailyTargetScore == 0
                        ? '未设置'
                        : '${profile.dailyTargetScore} 分',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showDailyTargetDialog(context, profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 奖励管理（v1.3 自定义奖励）
          _SectionCard(
            title: '奖励管理',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  title: const Text('添加自定义奖励'),
                  subtitle: const Text('自定义奖励会出现在阳光商城'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCustomRewardDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 时间控制
          _SectionCard(
            title: '时间控制',
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.timer_outlined, color: AppColors.primary),
                  title: const Text('每日总时长（分钟）'),
                  trailing: Text(
                    '${profile.dailyMinutes} 分钟',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showDurationDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.hourglass_top,
                      color: AppColors.primary),
                  title: Text(
                      '番茄钟（${profile.focusMinutes} 分钟学习 + ${profile.breakMinutes} 分钟休息）'),
                  subtitle: Text(profile.pomodoroEnabled
                      ? '到点提醒休息，复习错题不受影响'
                      : '已关闭'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPomodoroDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.savings_outlined,
                      color: AppColors.primary),
                  title: const Text('每日积分上限'),
                  subtitle: Text(profile.dailyScoreLimit == 0
                      ? '未限制（可设置上限防刷题）'
                      : '今日最多获得 ${profile.dailyScoreLimit} 分'),
                  trailing: Text(
                    profile.dailyScoreLimit == 0
                        ? '不限'
                        : '${profile.dailyScoreLimit} 分',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showScoreLimitDialog(context, profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 偏好设置
          _SectionCard(
            title: '偏好设置',
            child: Column(
              children: [
                SwitchListTile(
                  value: profile.soundEnabled,
                  onChanged: (v) async {
                    await user.updateSettings(soundEnabled: v);
                  },
                  secondary: const Icon(Icons.volume_up,
                      color: AppColors.primary),
                  title: const Text('音效'),
                ),
                SwitchListTile(
                  value: profile.animationEnabled,
                  onChanged: (v) async {
                    await user.updateSettings(animationEnabled: v);
                  },
                  secondary: const Icon(Icons.animation,
                      color: AppColors.primary),
                  title: const Text('动画效果'),
                ),
                SwitchListTile(
                  value: profile.darkMode,
                  onChanged: (v) async {
                    await user.updateSettings(darkMode: v);
                  },
                  secondary:
                      const Icon(Icons.dark_mode, color: AppColors.primary),
                  title: const Text('深色模式'),
                ),
                SwitchListTile(
                  value: profile.filterCurrentStage,
                  onChanged: (v) async {
                    await user.updateSettings(filterCurrentStage: v);
                  },
                  secondary: const Icon(Icons.filter_alt,
                      color: AppColors.primary),
                  title: const Text('内容过滤：仅当前学段关卡'),
                  subtitle: const Text('闯关列表只显示本学段内容'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 数据管理
          _SectionCard(
            title: '数据管理',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever,
                      color: AppColors.warning),
                  title: const Text(
                    '一键清除本地全部数据',
                    style: TextStyle(color: AppColors.warning),
                  ),
                  subtitle: const Text('清空学习记录、积分、档案，不可恢复'),
                  onTap: () => _confirmWipe(context, user),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 勋章预览（家长查看）
          _SectionCard(
            title: '勋章墙（${quiz.unlockedBadgeCount}/${quiz.badges.length}）',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quiz.badges.map((b) {
                final lit = b.unlocked;
                return Tooltip(
                  message: '${b.name}：${b.condition}',
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: lit
                          ? AppColors.rewardBackground
                          : AppColors.locked.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      lit ? b.icon : '🔒',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 修改学段 / 年级
  Future<void> _showStageGradeDialog(
      BuildContext context, UserProfile profile) async {
    StudyStage? newStage = profile.stage;
    String newGrade = profile.grade;
    final grades = {
      StudyStage.kindergarten: ['小班', '中班', '大班'],
      StudyStage.primary: ['一年级', '二年级', '三年级', '四年级', '五年级', '六年级'],
      StudyStage.middle: ['七年级', '八年级', '九年级'],
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('修改学段 / 年级'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('学段', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: StudyStage.values.map((s) {
                  final selected = s == newStage;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: selected,
                    onSelected: (v) => setDialogState(() {
                      newStage = s;
                      newGrade = grades[s]!.first;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('年级', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: grades[newStage]!.map((g) {
                  final selected = g == newGrade;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (v) => setDialogState(() => newGrade = g),
                  );
                }).toList(),
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
              onPressed: () async {
                await UserProvider.instance.updateSettings(
                  stage: newStage,
                  grade: newGrade,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 修改每日时长（10-120 分钟）
  Future<void> _showDurationDialog(
      BuildContext context, UserProfile profile) async {
    var minutes = profile.dailyMinutes;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('每日学习总时长'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$minutes 分钟',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Slider(
                value: minutes.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                label: '$minutes',
                onChanged: (v) =>
                    setDialogState(() => minutes = v.round()),
              ),
              const Text(
                '达到上限后仅锁定新关卡，错题复习不受影响',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              onPressed: () async {
                await UserProvider.instance.updateSettings(
                    dailyMinutes: minutes);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 修改每日目标积分（0 表示关闭成就目标）
  Future<void> _showDailyTargetDialog(
      BuildContext context, UserProfile profile) async {
    var target = profile.dailyTargetScore;
    const presets = [0, 30, 50, 100, 150];
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('每日目标积分'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                target == 0 ? '未设置' : '$target 分',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: presets.map((p) {
                  return ChoiceChip(
                    label: Text(p == 0 ? '关闭' : '$p'),
                    selected: target == p,
                    onSelected: (v) => setDialogState(() => target = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Slider(
                value: target.toDouble().clamp(0, 200),
                min: 0,
                max: 200,
                divisions: 20,
                label: '$target',
                onChanged: (v) => setDialogState(() => target = v.round()),
              ),
              const Text(
                '孩子当日获得积分达到目标后，会获得"今日成就"卡片',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              onPressed: () async {
                await UserProvider.instance
                    .updateSettings(dailyTargetScore: target);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 修改每日积分上限（0 表示不限制，防刷简单题）
  Future<void> _showScoreLimitDialog(
      BuildContext context, UserProfile profile) async {
    var limit = profile.dailyScoreLimit;
    const presets = [0, 50, 100, 150, 200];
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('每日积分上限'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                limit == 0 ? '不限' : '$limit 分',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: presets.map((p) {
                  return ChoiceChip(
                    label: Text(p == 0 ? '不限' : '$p'),
                    selected: limit == p,
                    onSelected: (v) => setDialogState(() => limit = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Slider(
                value: limit.toDouble().clamp(0, 300),
                min: 0,
                max: 300,
                divisions: 30,
                label: '$limit',
                onChanged: (v) => setDialogState(() => limit = v.round()),
              ),
              const Text(
                '防止孩子刷简单题；达到上限后当天不再获得积分（兑换扣分不受影响）',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              onPressed: () async {
                await UserProvider.instance
                    .updateSettings(dailyScoreLimit: limit);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 番茄钟配置：开关 + 学习 / 休息时长
  Future<void> _showPomodoroDialog(
      BuildContext context, UserProfile profile) async {
    var enabled = profile.pomodoroEnabled;
    var focus = profile.focusMinutes;
    var rest = profile.breakMinutes;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('番茄钟'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: enabled,
                onChanged: (v) => setDialogState(() => enabled = v),
                secondary: const Icon(Icons.timer_outlined,
                    color: AppColors.primary),
                title: const Text('开启番茄钟'),
              ),
              const SizedBox(height: 8),
              Text(
                '学习 $focus 分钟',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Slider(
                value: focus.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '$focus',
                onChanged: (v) =>
                    setDialogState(() => focus = v.round()),
              ),
              Text(
                '休息 $rest 分钟',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Slider(
                value: rest.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$rest',
                onChanged: (v) => setDialogState(() => rest = v.round()),
              ),
              const Text(
                '学习到点提醒休息；休息/超时阶段错题复习不受影响',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              onPressed: () async {
                await UserProvider.instance.updateSettings(
                  pomodoroEnabled: enabled,
                  focusMinutes: focus,
                  breakMinutes: rest,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 家长自定义奖励表单（v1.3）
  Future<void> _showCustomRewardDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String tier = 'small';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加自定义奖励'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '奖励名称',
                    hintText: '例如：看一集动画片',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: '图标（emoji）',
                    hintText: '例如：🎬',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '所需积分',
                    hintText: '例如：80',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('小奖励'),
                      selected: tier == 'small',
                      onSelected: (_) => setDialogState(() => tier = 'small'),
                    ),
                    ChoiceChip(
                      label: const Text('中奖励'),
                      selected: tier == 'medium',
                      onSelected: (_) => setDialogState(() => tier = 'medium'),
                    ),
                    ChoiceChip(
                      label: const Text('大奖励（需家长确认）'),
                      selected: tier == 'big',
                      onSelected: (_) => setDialogState(() => tier = 'big'),
                    ),
                  ],
                ),
              ],
            ),
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
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = int.tryParse(priceCtrl.text.trim());
                if (name.isEmpty || price == null || price <= 0) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('请填写名称和有效积分')),
                    );
                  }
                  return;
                }
                await RewardProvider.instance.addCustomReward(
                  name: name,
                  icon: iconCtrl.text.trim(),
                  price: price,
                  tier: tier,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('已添加奖励：$name')),
                  );
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    iconCtrl.dispose();
    priceCtrl.dispose();
  }

  /// 奖励档次标签
  static String _tierLabel(String tier) => switch (tier) {
        'small' => '小奖励',
        'medium' => '中奖励',
        _ => '大奖励',
      };

  /// 一键清除确认
  Future<void> _confirmWipe(BuildContext context, UserProvider user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除全部数据？'),
        content: const Text(
          '将清空所有学习记录、积分、关卡进度、勋章和档案，且不可恢复。确定要清除吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await user.wipeAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除全部本地数据')),
      );
    }
  }
}

/// 设置分组卡片
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// 算术验证门（防止孩子误入设置）
class _VerifyGate extends StatefulWidget {
  final VoidCallback onVerified;

  const _VerifyGate({required this.onVerified});

  @override
  State<_VerifyGate> createState() => _VerifyGateState();
}

class _VerifyGateState extends State<_VerifyGate> {
  final _random = Random();
  late int _a;
  late int _b;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 10 + _random.nextInt(40);
    _b = 10 + _random.nextInt(40);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.verified_user,
              size: 64, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            '家长验证',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请家长完成下面的算术题\n防止小朋友误改设置',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '$_a + $_b = ?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '输入答案',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _verify,
            child: const Text('进入家长中心',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _verify() {
    final input = int.tryParse(_controller.text.trim());
    if (input == _a + _b) {
      widget.onVerified();
      return;
    }
    // 答错换新题，温和提示
    setState(() {
      _newQuestion();
      _controller.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('答案不对哦，再试一次～')),
    );
  }
}
