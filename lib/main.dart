import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user_profile.dart';
import 'pages/garden/garden_page.dart';
import 'pages/home/home_page.dart';
import 'pages/mall/mall_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/parent/parent_center_page.dart';
import 'pages/quiz/level_select_page.dart';
import 'pages/record/record_page.dart';
import 'pages/reward/reward_page.dart';
import 'pages/task/task_page.dart';
import 'providers/garden_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/score_badge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 加载用户状态（含跨日重置）
  await UserProvider.instance.load();
  runApp(const SunshineGardenApp());
}

class SunshineGardenApp extends StatelessWidget {
  const SunshineGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: UserProvider.instance),
        ChangeNotifierProvider.value(value: TaskProvider.instance),
        ChangeNotifierProvider.value(value: QuizProvider.instance),
        ChangeNotifierProvider.value(value: GardenProvider.instance),
        ChangeNotifierProvider.value(value: RewardProvider.instance),
      ],
      child: Consumer<UserProvider>(
        builder: (context, user, _) {
          return MaterialApp(
            title: '阳光花园・学习乐园',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode:
                user.profile?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

/// 根路由：未初始化档案 → 引导页；已初始化 → 主框架
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final user = UserProvider.instance;
    if (!user.isLoaded) {
      // 初始化等待
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (user.initFailed) {
      return const Scaffold(
        body: Center(
          child: Text('初始化失败，请重启应用重试'),
        ),
      );
    }
    if (user.profile == null) {
      return const OnboardingPage();
    }
    return const MainShell();
  }
}

/// 主框架：Scaffold + AppBar（积分胶囊）+ Drawer + IndexedStack
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Drawer 菜单项（与 IndexedStack 顺序对应）
  static const _menus = [
    (Icons.dashboard_outlined, '学习总览'),
    (Icons.checklist_outlined, '今日任务'),
    (Icons.extension_outlined, '知识闯关'),
    (Icons.local_florist_outlined, '阳光花园'),
    (Icons.storefront_outlined, '阳光商城'),
    (Icons.card_giftcard_outlined, '我的奖励'),
    (Icons.history_outlined, '学习记录'),
    (Icons.family_restroom_outlined, '家长中心'),
  ];

  late final List<Widget> _pages = [
    HomePage(onNavigate: (i) => setState(() => _index = i)),
    const TaskPage(),
    const LevelSelectPage(),
    const GardenPage(),
    const MallPage(),
    const RewardPage(),
    const RecordPage(),
    const ParentCenterPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = UserProvider.instance;
    final profile = user.profile!;
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: '菜单',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _menus[_index].$2,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              '${profile.nickname} · ${profile.stage.label} · ${profile.grade}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ScoreBadge(score: user.totalScore),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: IndexedStack(index: _index, children: _pages),
    );
  }

  Widget _buildDrawer(BuildContext context, UserProvider user) {
    final profile = user.profile!;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo + 品牌
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.statusCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      '阳光',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '阳光花园・学习乐园',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '学习赚积分，积分种花园',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // 菜单
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menus.length,
                itemBuilder: (context, i) {
                  final selected = _index == i;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Material(
                      color: selected ? AppColors.menuSelected : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => _index = i);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              // 导航图标：淡紫色背景容器
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.subtitle
                                          .withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _menus[i].$1,
                                  size: 20,
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _menus[i].$2,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.textMain
                                      : Colors.white,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 底部：当前孩子
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.child_care, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${profile.nickname} · ${profile.stage.label}${profile.grade}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '👑 ${user.totalScore}',
                    style: const TextStyle(
                      color: AppColors.score,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
