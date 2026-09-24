import 'package:flutter/material.dart';

/// 品牌视觉规范（PRD 第 6 章）
/// 所有颜色集中管理，禁止在业务代码中硬编码色值。
class AppColors {
  AppColors._();

  /// 主色：主题紫
  static const Color primary = Color(0xFFB791FA);

  /// 副标题色：淡紫
  static const Color subtitle = Color(0xFFC8A9FC);

  /// 页面背景：浅蓝
  static const Color background = Color(0xFFEEF4FF);

  /// 深色状态卡：深蓝
  static const Color statusCard = Color(0xFF22315B);

  /// 阳光积分色：明黄
  static const Color score = Color(0xFFFFC93C);

  /// 任务完成色：绿
  static const Color success = Color(0xFF34C38F);

  /// 奖励区背景：淡黄
  static const Color rewardBackground = Color(0xFFFFF8E4);

  /// 菜单选中背景：淡紫
  static const Color menuSelected = Color(0xFFDCC9FD);

  /// 错误反馈色：橙色（替代红色，降低儿童挫败感）
  static const Color warning = Color(0xFFFF8F5A);

  /// 锁定 / 未解锁：灰
  static const Color locked = Color(0xFFB9C0D0);

  /// 文字主色：深灰
  static const Color textMain = Color(0xFF2E2E38);

  /// 文字次级
  static const Color textSecondary = Color(0xFF7A7F8E);
}

/// 应用主题构建器
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.subtitle,
        surface: Colors.white,
        error: AppColors.warning,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamilyFallback: const ['PingFang SC', 'Noto Sans SC'],
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.primary,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.statusCard,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success
              : Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFE4E8F5),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        error: AppColors.warning,
      ),
      scaffoldBackgroundColor: const Color(0xFF191A24),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
