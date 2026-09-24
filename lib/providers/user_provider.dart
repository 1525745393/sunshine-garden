import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../models/user_profile.dart';

/// 用户全局状态：档案 / 积分 / 每日时长 / 设置
class UserProvider extends ChangeNotifier {
  UserProvider._();
  static final UserProvider instance = UserProvider._();

  static const _kUserId = 'current_user_id';
  static const _kTodayKey = 'today_key';
  static const _kTodaySeconds = 'today_used_seconds';
  static const _kPrivacyAccepted = 'privacy_accepted';
  static const _kTimeLockNoticeKey = 'time_lock_notice_key';

  UserProfile? _profile;
  bool _loaded = false;

  /// 今日已用时长（秒），跨日自动重置
  int _todayUsedSeconds = 0;
  String _todayKey = '';
  bool _privacyAccepted = false;
  bool _initFailed = false;

  UserProfile? get profile => _profile;
  bool get isLoaded => _loaded;
  bool get initFailed => _initFailed;
  bool get privacyAccepted => _privacyAccepted;
  int get totalScore => _profile?.totalScore ?? 0;

  /// 今日已用时长（秒）
  int get todayUsedSeconds => _todayUsedSeconds;

  /// 今日剩余秒数
  int get todayRemainingSeconds {
    final limit = (_profile?.dailyMinutes ?? 20) * 60;
    return (limit - _todayUsedSeconds).clamp(0, limit);
  }

  /// 今日时长是否已用尽（超时锁定新关卡）
  bool get isTimeUp => todayRemainingSeconds <= 0;

  /// 每日时长上限（秒）
  int get dailyLimitSeconds => (_profile?.dailyMinutes ?? 20) * 60;

  /// 应用启动时加载用户与跨日重置
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _privacyAccepted = prefs.getBool(_kPrivacyAccepted) ?? false;

      // 跨日重置：今日时长
      final now = DateTime.now();
      final todayKey = _dayKey(now);
      final storedDay = prefs.getString(_kTodayKey) ?? '';
      if (storedDay != todayKey) {
        await prefs.setString(_kTodayKey, todayKey);
        await prefs.setInt(_kTodaySeconds, 0);
        _todayUsedSeconds = 0;
      } else {
        _todayUsedSeconds = prefs.getInt(_kTodaySeconds) ?? 0;
      }
      _todayKey = todayKey;

      // 加载用户
      final userId = prefs.getString(_kUserId);
      if (userId != null) {
        _profile = await DatabaseHelper.instance.getUser(userId);
      }
      if (_profile != null) {
        _checkDailyRollover();
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      // 数据库未就绪等初始化异常：标记失败，页面展示重试
      debugPrint('UserProvider.load error: $e');
      _initFailed = true;
      _loaded = true;
      notifyListeners();
    }
  }

  /// 跨日判断：更新连续打卡天数
  void _checkDailyRollover() {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final last = _profile!.lastActiveDayKey;
    if (last == todayKey) return;
    if (last != null) {
      final lastDate = DateTime.parse(last);
      final diff = now.difference(lastDate).inDays;
      _profile!.continuousDays = diff == 1 ? _profile!.continuousDays + 1 : 1;
    } else {
      _profile!.continuousDays = 1;
    }
    _profile!.lastActiveDayKey = todayKey;
    _profile!.lastActiveDate = now;
    _persistProfile();
  }

  /// 创建档案（首次引导）
  Future<void> createProfile({
    required String nickname,
    required StudyStage stage,
    required String grade,
  }) async {
    final profile = UserProfile(
      id: 'user_001',
      nickname: nickname,
      stage: stage,
      grade: grade,
    );
    _profile = profile;
    _todayKey = _dayKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, profile.id);
    await DatabaseHelper.instance.upsertUser(profile);
    notifyListeners();
  }

  /// 家长中心修改设置
  Future<void> updateSettings({
    StudyStage? stage,
    String? grade,
    int? dailyMinutes,
    bool? soundEnabled,
    bool? animationEnabled,
    bool? darkMode,
  }) async {
    final p = _profile;
    if (p == null) return;
    if (stage != null) p.stage = stage;
    if (grade != null) p.grade = grade;
    if (dailyMinutes != null) p.dailyMinutes = dailyMinutes;
    if (soundEnabled != null) p.soundEnabled = soundEnabled;
    if (animationEnabled != null) p.animationEnabled = animationEnabled;
    if (darkMode != null) p.darkMode = darkMode;
    await _persistProfile();
  }

  /// 积分增减（闯关 / 任务 / 兑换扣分），持久化
  Future<void> changeScore(int delta) async {
    final p = _profile;
    if (p == null) return;
    p.totalScore = (p.totalScore + delta).clamp(0, 999999);
    await _persistProfile();
  }

  Future<void> _persistProfile() async {
    if (_profile == null) return;
    await DatabaseHelper.instance.upsertUser(_profile!);
    notifyListeners();
  }

  /// 家长中心：一键清除本地全部数据
  Future<void> wipeAllData() async {
    await DatabaseHelper.instance.wipeAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kTodayKey);
    await prefs.remove(_kTodaySeconds);
    _profile = null;
    _todayUsedSeconds = 0;
    notifyListeners();
  }

  /// 家长确认隐私协议（首次启动）
  Future<void> acceptPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrivacyAccepted, true);
    _privacyAccepted = true;
    notifyListeners();
  }

  /// 累计前台活跃时长（秒）；每次状态切换调用，持久化到 prefs
  Future<void> addActiveSeconds(int seconds) async {
    if (seconds <= 0) return;
    _todayUsedSeconds += seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTodaySeconds, _todayUsedSeconds);
    notifyListeners();
  }

  /// 判断是否需要弹"今日时间到"提示（每天只弹一次）
  Future<bool> consumeTimeUpNotice() async {
    if (!isTimeUp) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kTimeLockNoticeKey$_todayKey';
    final shown = prefs.getBool(key) ?? false;
    if (shown) return false;
    await prefs.setBool(key, true);
    return true;
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
